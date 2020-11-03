#!/bin/bash

echo "***************************** UPDATING OS *****************************"
sudo apt update
#sudo apt-get update
sudo apt-get install linux-image-extra-virtual
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common gnupg2 libcurl4-openssl-dev

#echo "***************************** Installing ANSIBLE *****************************"
#sudo apt-add-repository ppa:ansible/ansible
#sudo apt-get update
#sudo apt-get -yq install ansible

echo "***************************** Letting iptables see bridged traffic *****************************"
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

echo "***************************** ADDING DOCKER REPO *****************************"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update

echo "***************************** Installing Docker as systemd *****************************"
sudo apt-get install -yq  docker-ce=18.06.2~ce~3-0~ubuntu
#sudo apt-get install -yq docker-ce docker-ce-cli containerd.io
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

echo "***************************** ADDING KUBERNETES REPO *****************************"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update

echo "***************************** Installing kubeadm & Pulling Images *****************************"
sudo apt-get update
sudo apt-get install -yq kubelet=1.18.10\* kubectl=1.18.10\* kubeadm=1.18.10\*
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm config images pull

echo "***************************** Disable SWAP *****************************"
sudo swapoff -a

echo "***************************** Initializing KUBERNETES CLUSTER Using KUBEADM *****************************"
sudo kubeadm init  --kubernetes-version stable-1.18 --token-ttl 0 --apiserver-advertise-address=172.42.42.100 --apiserver-cert-extra-sans=172.42.42.100 --pod-network-cidr=10.16.0.0/16 --v=20

echo "***************************** Copy PKI KEYS to Home folder *****************************"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "***************************** Add an overlay network *****************************"
sudo kubectl apply -f /vagrant/download/calico.yaml
sudo kubectl taint nodes --all node-role.kubernetes.io/master
kubectl get po -n kube-system
