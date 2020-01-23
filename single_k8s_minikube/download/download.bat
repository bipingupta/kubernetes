REM ************************************** LATEST DOCKER VERSION **************************************
curl https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_19.03.5~3-0~ubuntu-xenial_amd64.deb --output docker-ce.deb
curl https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce-cli_19.03.5~3-0~ubuntu-xenial_amd64.deb --output docker-ce-cli.deb
curl https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb --output containerd.io.deb

REM ************************************** LATEST MINIKUBE & KUBECTL VERSION **************************************
curl https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 --output minikube
curl https://storage.googleapis.com/kubernetes-release/release/v1.16.3/bin/linux/amd64/kubectl --output kubectl


