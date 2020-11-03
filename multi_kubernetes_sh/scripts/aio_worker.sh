#!/bin/bash

echo "***************************** UPDATING OS *****************************"
sudo apt update
#sudo apt-get update
sudo apt-get install linux-image-extra-virtual
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common gnupg2 libcurl4-openssl-dev

echo "***************************** Letting iptables see bridged traffic *****************************"
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

echo "***************************** ADDING KUBERNETES REPO *****************************"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update

echo "***************************** Installing Docker *****************************"
sudo apt-get install -yq docker.io
sudo usermod -aG docker $USER

# Set up the Docker daemon
sudo cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# Create /etc/systemd/system/docker.service.d
sudo mkdir -p /etc/systemd/system/docker.service.d

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl status docker
sudo docker info

echo "***************************** Installing kubeadm & Pulling Images *****************************"
sudo apt-get update
sudo apt-get install -yq kubelet=1.18.10\* kubectl=1.18.10\* kubeadm=1.18.10\*
sudo apt-mark hold kubelet kubeadm kubectl
sudo kubeadm config images pull

echo "***************************** Disable SWAP *****************************"
sudo swapoff -a


