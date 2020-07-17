#!/usr/bin/env bash

#http://updates.jenkins-ci.org/download/plugins/
#http://updates.jenkins-ci.org/download/plugins/ant/1.3/ant.hpi
echo "***************************** SNAPD - Installation *****************************"

set -o pipefail

JENKINS_WAR=${JENKINS_WAR:-/usr/share/jenkins/jenkins.war}
JENKINS_UC="http://updates.jenkins-ci.org"

REF_DIR="${REF}/plugins"
FAILED="$REF_DIR/failed-plugins.txt"

getLockFile() {
    printf '%s' "$REF_DIR/${1}.lock"
}

getArchiveFilename() {
    printf '%s' "$REF_DIR/${1}.jpi"
}

download() {
    local plugin originalPlugin version lock ignoreLockFile url
    plugin="$1"
    version="${2:-latest}"
    ignoreLockFile="${3:-}"
    url="${4:-}"
    lock="$(getLockFile "$plugin")"

    if [[ $ignoreLockFile ]] || mkdir "$lock" &>/dev/null; then
        if ! doDownload "$plugin" "$version" "$url"; then
            # some plugin don't follow the rules about artifact ID
            # typically: docker-plugin
            originalPlugin="$plugin"
            plugin="${plugin}-plugin"
            if ! doDownload "$plugin" "$version" "$url"; then
                echo "Failed to download plugin: $originalPlugin or $plugin" >&2
                echo "Not downloaded: ${originalPlugin}" >> "$FAILED"
                return 1
            fi
        fi

        if ! checkIntegrity "$plugin"; then
            echo "Downloaded file is not a valid ZIP: $(getArchiveFilename "$plugin")" >&2
            echo "Download integrity: ${plugin}" >> "$FAILED"
            return 1
        fi

        resolveDependencies "$plugin"
    fi
}

doDownload() {
    local plugin version url jpi
    plugin="$1"
    version="$2"
    url="$3"
    jpi="$(getArchiveFilename "$plugin")"

    # If plugin already exists and is the same version do not download
    if test -f "$jpi" && unzip -p "$jpi" META-INF/MANIFEST.MF | tr -d '\r' | grep "^Plugin-Version: ${version}$" > /dev/null; then
        echo "Using provided plugin: $plugin"
        return 0
    fi

    if [[ -n $url ]] ; then
        echo "Will use url=$url"
    elif [[ "$version" == "latest" && -n "$JENKINS_UC_LATEST" ]]; then
        # If version-specific Update Center is available, which is the case for LTS versions,
        # use it to resolve latest versions.
        url="$JENKINS_UC_LATEST/latest/${plugin}.hpi"
    elif [[ "$version" == "experimental" && -n "$JENKINS_UC_EXPERIMENTAL" ]]; then
        # Download from the experimental update center
        url="$JENKINS_UC_EXPERIMENTAL/latest/${plugin}.hpi"
    elif [[ "$version" == incrementals* ]] ; then
        # Download from Incrementals repo: https://jenkins.io/blog/2018/05/15/incremental-deployment/
        # Example URL: https://repo.jenkins-ci.org/incrementals/org/jenkins-ci/plugins/workflow/workflow-support/2.19-rc289.d09828a05a74/workflow-support-2.19-rc289.d09828a05a74.hpi
        local groupId incrementalsVersion
        # add a trailing ; so the \n gets added to the end
        readarray -t "-d;" arrIN <<<"${version};";
        unset 'arrIN[-1]';
        groupId=${arrIN[1]}
        incrementalsVersion=${arrIN[2]}
        url="${JENKINS_INCREMENTALS_REPO_MIRROR}/$(echo "${groupId}" | tr '.' '/')/${plugin}/${incrementalsVersion}/${plugin}-${incrementalsVersion}.hpi"
    else
        JENKINS_UC_DOWNLOAD=${JENKINS_UC_DOWNLOAD:-"$JENKINS_UC/download"}
        url="$JENKINS_UC_DOWNLOAD/plugins/$plugin/$version/${plugin}.hpi"
    fi

    echo "Downloading plugin: $plugin from $url"
    # We actually want to allow variable value to be split into multiple options passed to curl.
    # This is needed to allow long options and any options that take value.
    # shellcheck disable=SC2086
    retry_command curl ${CURL_OPTIONS:--sSfL} --connect-timeout "${CURL_CONNECTION_TIMEOUT:-20}" --retry "${CURL_RETRY:-3}" --retry-delay "${CURL_RETRY_DELAY:-0}" --retry-max-time "${CURL_RETRY_MAX_TIME:-60}" "$url" -o "$jpi"
    return $?
}

checkIntegrity() {
    local plugin jpi
    plugin="$1"
    jpi="$(getArchiveFilename "$plugin")"

    unzip -t -qq "$jpi" >/dev/null
    return $?
}

resolveDependencies() {
    local plugin jpi dependencies
    plugin="$1"
    jpi="$(getArchiveFilename "$plugin")"

    dependencies="$(unzip -p "$jpi" META-INF/MANIFEST.MF | tr -d '\r' | tr '\n' '|' | sed -e 's#| ##g' | tr '|' '\n' | grep "^Plugin-Dependencies: " | sed -e 's#^Plugin-Dependencies: ##')"

    if [[ ! $dependencies ]]; then
        echo " > $plugin has no dependencies"
        return
    fi

    echo " > $plugin depends on $dependencies"

    IFS=',' read -r -a array <<< "$dependencies"

    for d in "${array[@]}"
    do
        plugin="$(cut -d':' -f1 - <<< "$d")"
        if [[ $d == *"resolution:=optional"* ]]; then
            echo "Skipping optional dependency $plugin"
        else
            local pluginInstalled
            if pluginInstalled="$(echo -e "${bundledPlugins}\n${installedPlugins}" | grep "^${plugin}:")"; then
                pluginInstalled="${pluginInstalled//[$'\r']}"
                local versionInstalled; versionInstalled=$(versionFromPlugin "${pluginInstalled}")
                local minVersion; minVersion=$(versionFromPlugin "${d}")
                if versionLT "${versionInstalled}" "${minVersion}"; then
                    echo "Upgrading bundled dependency $d ($minVersion > $versionInstalled)"
                    download "$plugin" &
                else
                    echo "Skipping already installed dependency $d ($minVersion <= $versionInstalled)"
                fi
            else
                download "$plugin" &
            fi
        fi
    done
    wait
}

bundledPlugins() {
    if [ -f "$JENKINS_WAR" ]
    then
        TEMP_PLUGIN_DIR=/tmp/plugintemp.$$
        for i in $(jar tf "$JENKINS_WAR" | grep -E '[^detached-]plugins.*\..pi' | sort)
        do
            rm -fr $TEMP_PLUGIN_DIR
            mkdir -p $TEMP_PLUGIN_DIR
            PLUGIN=$(basename "$i"|cut -f1 -d'.')
            (cd $TEMP_PLUGIN_DIR;jar xf "$JENKINS_WAR" "$i";jar xvf "$TEMP_PLUGIN_DIR/$i" META-INF/MANIFEST.MF >/dev/null 2>&1)
            VER=$(grep -E -i Plugin-Version "$TEMP_PLUGIN_DIR/META-INF/MANIFEST.MF"|cut -d: -f2|sed 's/ //')
            echo "$PLUGIN:$VER"
        done
        rm -fr $TEMP_PLUGIN_DIR
    else
        echo "war not found, installing all plugins: $JENKINS_WAR"
    fi
}

versionFromPlugin() {
    local plugin=$1
    if [[ $plugin =~ .*:.* ]]; then
        echo "${plugin##*:}"
    else
        echo "latest"
    fi

}

installedPlugins() {
    for f in "$REF_DIR"/*.jpi; do
        echo "$(basename "$f" | sed -e 's/\.jpi//'):$(get_plugin_version "$f")"
    done
}

jenkinsMajorMinorVersion() {
    if [[ -f "$JENKINS_WAR" ]]; then
        local version major minor
        version="$(java -jar "$JENKINS_WAR" --version)"
        major="$(echo "$version" | cut -d '.' -f 1)"
        minor="$(echo "$version" | cut -d '.' -f 2)"
        echo "$major.$minor"
    else
        echo ""
    fi
}

main() {
    local plugin jenkinsVersion
    local plugins=()

    mkdir -p "$REF_DIR" || exit 1
    rm -f "$FAILED"

    # Read plugins from stdin or from the command line arguments
    if [[ ($# -eq 0) ]]; then
        while read -r line || [ "$line" != "" ]; do
            # Remove leading/trailing spaces, comments, and empty lines
            plugin=$(echo "${line}" | tr -d '\r' | sed -e 's/^[ \t]*//g' -e 's/[ \t]*$//g' -e 's/[ \t]*#.*$//g' -e '/^[ \t]*$/d')

            # Avoid adding empty plugin into array
            if [ ${#plugin} -ne 0 ]; then
                plugins+=("${plugin}")
            fi
        done
    else
        plugins=("$@")
    fi

    # Create lockfile manually before first run to make sure any explicit version set is used.
    echo "Creating initial locks..."
    for plugin in "${plugins[@]}"; do
        mkdir "$(getLockFile "${plugin%%:*}")"
    done

    echo "Analyzing war $JENKINS_WAR..."
    bundledPlugins="$(bundledPlugins)"

    echo "Registering preinstalled plugins..."
    installedPlugins="$(installedPlugins)"

    # Check if there's a version-specific update center, which is the case for LTS versions
    jenkinsVersion="$(jenkinsMajorMinorVersion)"
    if curl -fsL -o /dev/null "$JENKINS_UC/$jenkinsVersion"; then
        JENKINS_UC_LATEST="$JENKINS_UC/$jenkinsVersion"
        echo "Using version-specific update center: $JENKINS_UC_LATEST..."
    else
        JENKINS_UC_LATEST=
    fi

    echo "Downloading plugins..."
    for plugin in "${plugins[@]}"; do
        local reg='^([^:]+):?([^:]+)?:?([^:]+)?:?(http.+)?'
        if [[ $plugin =~ $reg ]]; then
            local pluginId="${BASH_REMATCH[1]}"
            local version="${BASH_REMATCH[2]}"
            local lock="${BASH_REMATCH[3]}"
            local url="${BASH_REMATCH[4]}"
            download "$pluginId" "$version" "${lock:-true}" "${url}" &
        else
          echo "Skipping the line '${plugin}' as it does not look like a reference to a plugin"
        fi
    done
    wait

    echo
    echo "WAR bundled plugins:"
    echo "${bundledPlugins}"
    echo
    echo "Installed plugins:"
    installedPlugins

    if [[ -f $FAILED ]]; then
        echo "Some plugins failed to download!" "$(<"$FAILED")" >&2
        exit 1
    fi

    echo "Cleaning up locks"
    find "$REF_DIR" -regex ".*.lock" | while read -r filepath; do
        rm -r "$filepath"
    done

}

# compare if version1 < version2
versionLT() {
    local v1; v1=$(echo "$1" | cut -d '-' -f 1 )
    local q1; q1=$(echo "$1" | cut -s -d '-' -f 2- )
    local v2; v2=$(echo "$2" | cut -d '-' -f 1 )
    local q2; q2=$(echo "$2" | cut -s -d '-' -f 2- )
    if [ "$v1" = "$v2" ]; then
        if [ "$q1" = "$q2" ]; then
            return 1
        else
            if [ -z "$q1" ]; then
                return 1
            else
                if [ -z "$q2" ]; then
                    return 0
                else
                    [  "$q1" = "$(echo -e "$q1\n$q2" | sort -V | head -n1)" ]
                fi
            fi
        fi
    else
        [  "$v1" = "$(echo -e "$v1\n$v2" | sort -V | head -n1)" ]
    fi
}

# returns a plugin version from a plugin archive
get_plugin_version() {
    local archive; archive=$1
    local version; version=$(unzip -p "$archive" META-INF/MANIFEST.MF | grep "^Plugin-Version: " | sed -e 's#^Plugin-Version: ##')
    version=${version%%[[:space:]]}
    echo "$version"
}

# Copy files from /usr/share/jenkins/ref into $JENKINS_HOME
# So the initial JENKINS-HOME is set with expected content.
# Don't override, as this is just a reference setup, and use from UI
# can then change this, upgrade plugins, etc.
copy_reference_file() {
    f="${1%/}"
    b="${f%.override}"
    rel="${b#"$REF/"}"
    version_marker="${rel}.version_from_image"
    dir=$(dirname "${rel}")
    local action;
    local reason;
    local container_version;
    local image_version;
    local marker_version;
    local log; log=false
    if [[ ${rel} == plugins/*.jpi ]]; then
        container_version=$(get_plugin_version "$JENKINS_HOME/${rel}")
        image_version=$(get_plugin_version "${f}")
        if [[ -e $JENKINS_HOME/${version_marker} ]]; then
            marker_version=$(cat "$JENKINS_HOME/${version_marker}")
            if versionLT "$marker_version" "$container_version"; then
                if ( versionLT "$container_version" "$image_version" && [[ -n $PLUGINS_FORCE_UPGRADE ]]); then
                    action="UPGRADED"
                    reason="Manually upgraded version ($container_version) is older than image version $image_version"
                    log=true
                else
                    action="SKIPPED"
                    reason="Installed version ($container_version) has been manually upgraded from initial version ($marker_version)"
                    log=true
                fi
            else
                if [[ "$image_version" == "$container_version" ]]; then
                    action="SKIPPED"
                    reason="Version from image is the same as the installed version $image_version"
                else
                    if versionLT "$image_version" "$container_version"; then
                        action="SKIPPED"
                        log=true
                        reason="Image version ($image_version) is older than installed version ($container_version)"
                    else
                        action="UPGRADED"
                        log=true
                        reason="Image version ($image_version) is newer than installed version ($container_version)"
                    fi
                fi
            fi
        else
            if [[ -n "$TRY_UPGRADE_IF_NO_MARKER" ]]; then
                if [[ "$image_version" == "$container_version" ]]; then
                    action="SKIPPED"
                    reason="Version from image is the same as the installed version $image_version (no marker found)"
                    # Add marker for next time
                    echo "$image_version" > "$JENKINS_HOME/${version_marker}"
                else
                    if versionLT "$image_version" "$container_version"; then
                        action="SKIPPED"
                        log=true
                        reason="Image version ($image_version) is older than installed version ($container_version) (no marker found)"
                    else
                        action="UPGRADED"
                        log=true
                        reason="Image version ($image_version) is newer than installed version ($container_version) (no marker found)"
                    fi
                fi
            fi
        fi
        if [[ ! -e $JENKINS_HOME/${rel} || "$action" == "UPGRADED" || $f = *.override ]]; then
            action=${action:-"INSTALLED"}
            log=true
            mkdir -p "$JENKINS_HOME/${dir}"
            cp -pr "${f}" "$JENKINS_HOME/${rel}";
            # pin plugins on initial copy
            touch "$JENKINS_HOME/${rel}.pinned"
            echo "$image_version" > "$JENKINS_HOME/${version_marker}"
            reason=${reason:-$image_version}
        else
            action=${action:-"SKIPPED"}
        fi
    else
        if [[ ! -e $JENKINS_HOME/${rel} || $f = *.override ]]
        then
            action="INSTALLED"
            log=true
            mkdir -p "$JENKINS_HOME/${dir}"
            cp -pr "$(realpath "${f}")" "$JENKINS_HOME/${rel}";
        else
            action="SKIPPED"
        fi
    fi
    if [[ -n "$VERBOSE" || "$log" == "true" ]]; then
        if [ -z "$reason" ]; then
            echo "$action $rel" >> "$COPY_REFERENCE_FILE_LOG"
        else
            echo "$action $rel : $reason" >> "$COPY_REFERENCE_FILE_LOG"
        fi
    fi
}

# Retries a command a configurable number of times with backoff.
#
# The retry count is given by ATTEMPTS (default 60), the initial backoff
# timeout is given by TIMEOUT in seconds (default 1.)
#
function retry_command() {
  local max_attempts=${ATTEMPTS-3}
  local timeout=${TIMEOUT-1}
  local success_timeout=${SUCCESS_TIMEOUT-1}
  local max_success_attempt=${SUCCESS_ATTEMPTS-1}
  local attempt=0
  local success_attempt=0
  local exitCode=0

  while (( attempt < max_attempts ))
  do
    set +e
    "$@"
    exitCode=$?
    set -e

    if [[ $exitCode == 0 ]]
    then
      success_attempt=$(( success_attempt + 1 ))
      if (( success_attempt >= max_success_attempt))
      then
        break
      else
        sleep "$success_timeout"
        continue
      fi
    fi

    echo "$(date -u '+%T') Failure ($exitCode) Retrying in $timeout seconds..." 1>&2
    sleep "$timeout"
    success_attempt=0
    attempt=$(( attempt + 1 ))
    timeout=$(( timeout ))
  done

  if [[ $exitCode != 0 ]]
  then
    echo "$(date -u '+%T') Failed in the last attempt ($*)" 1>&2
  fi

  return $exitCode
}

main "$@"
