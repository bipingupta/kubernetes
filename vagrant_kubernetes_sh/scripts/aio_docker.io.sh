#!/bin/bash

echo "***************************** UPDATING OS *****************************"
sudo apt update
sudo apt-get update
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

echo "***************************** Disable SWAP && FIREWALL *****************************"
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab
#sudo ufw disable

echo "***************************** ADDING KUBERNETES REPO *****************************"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt-get update

echo "***************************** Installing kubeadm & Pulling Images *****************************"
sudo apt-get update
sudo apt-get install -yq kubelet=1.18.10\* kubectl=1.18.10\* kubeadm=1.18.10\*
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm config images pull

echo "***************************** Restart KUBELET *****************************"
sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo "***************************** Initializing KUBERNETES CLUSTER Using KUBEADM *****************************"
sudo kubeadm init  --kubernetes-version stable-1.18 --token-ttl 0 --apiserver-advertise-address=172.42.42.100 --apiserver-cert-extra-sans=172.42.42.100 --pod-network-cidr=10.16.0.0/16 
# For Debugging Purpose add --v=20

echo "***************************** Generate join command with token *****************************"
sudo kubeadm token create --print-join-command > /vagrant/download/kubeadm-join-command.sh

echo "***************************** Set KUBECONFIG in ENV *****************************"
export KUBECONFIG=/etc/kubernetes/admin.conf

echo "***************************** Add an Calico Overlay Network *****************************"
sudo kubectl --kubeconfig $KUBECONFIG create -f https://docs.projectcalico.org/v3.15/manifests/calico.yaml

#echo "***************************** Add an Weave Net Overlay Network *****************************"
#kubectl --kubeconfig $KUBECONFIG apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "***************************** Make master node a running worker node too !! *****************************"
sudo kubectl --kubeconfig $KUBECONFIG taint nodes --all node-role.kubernetes.io/master-

#echo "***************************** MetalLB Load-Balancer Deployment *****************************"
kubectl --kubeconfig $KUBECONFIG apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
kubectl --kubeconfig $KUBECONFIG apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
# On first install only
kubectl --kubeconfig $KUBECONFIG create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl --kubeconfig $KUBECONFIG create -f /vagrant/download/metallb_ip.yaml

echo "***************************** Copy PKI KEYS to Home folder (Vagrant) *****************************"
sudo bash /vagrant/download/copyadminconf2user.sh

echo "***************************** Kubernetes Dashboard UI *****************************"
kubectl --kubeconfig $KUBECONFIG create -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

echo "***************************** Create the dashboard service account *****************************"
kubectl --kubeconfig $KUBECONFIG apply -f  /vagrant/download/dashboard-admin.yaml
kubectl --kubeconfig $KUBECONFIG apply -f  /vagrant/download/dashboard-read-only.yaml
kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount admin-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

#https://172.42.42.100:32593/#/login
