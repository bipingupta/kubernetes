REM ************************************** LATEST DOCKER VERSION **************************************
curl -LO https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_19.03.5~3-0~ubuntu-xenial_amd64.deb --output docker-ce.deb
curl -LO https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce-cli_19.03.5~3-0~ubuntu-xenial_amd64.deb --output docker-ce-cli.deb
curl -LO https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb --output containerd.io.deb

REM ************************************** LATEST CALICO VERSION **************************************
curl -LO  https://docs.projectcalico.org/v3.8/manifests/calico.yaml --output calico.yaml

REM ************************************** LATEST PYTHON VERSION **************************************
curl -LO   https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tgz --output python-3.6.5.tgz 

