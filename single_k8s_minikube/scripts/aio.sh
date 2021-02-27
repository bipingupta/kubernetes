#!/bin/bash

export CHANGE_MINIKUBE_NONE_USER=true

echo "***************************** Copying Minikube & Kubectl from vagrant shared folder to bin *****************************"
export DOWNLOAD_PACKAGE=/vagrant/download
export HOME=/usr/local

sudo cp -v -f $DOWNLOAD_PACKAGE/minikube $HOME/bin
sudo cp -v -f $DOWNLOAD_PACKAGE/kubectl $HOME/bin
sudo chmod +x $HOME/bin/minikube
sudo chmod +x $HOME/bin/kubectl

sudo apt-get install conntrack

echo "***************************** Start M i n i k u b e *****************************"
minikube start --vm-driver=none
cat ~/.kube/config
kubectl proxy --accept-hosts=.* --address=0.0.0.0 &
minikube addons enable dashboard

echo "****************** Kubectl => Make kubectl work for your non-root user named vagrant *****************************"
sudo mkdir -v -p /home/vagrant/.kube
sudo cp -v -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

echo "***************************** Check  M i n i k u b e *****************************"
echo $(whoami)
minikube version
minikube status

echo "***************************** Start M i n i k u b e - D a s h b o a r d *****************************"
kubectl apply -f /vagrant/scripts/recommended.yaml
kubectl apply -f /vagrant/scripts/sa_cluster_admin.yaml

echo "***************************** Check  K u b e c t l *****************************"
kubectl get nodes -o wide
kubectl get services -o wide
kubectl get all --all-namespaces

echo "***************************** M i n i k u b e - Dashboard Access using Token *****************************"
kubectl -n kubernetes-dashboard describe sa dashboard-admin-sa
kubectl -n kubernetes-dashboard describe secret dashboard-admin-sa-token
kubectl version --short



