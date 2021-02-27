#!/bin/bash

echo "***************************** Installing SNAP *****************************"
#sudo apt update
sudo apt install snapd

echo "***************************** Installing Microk8s *****************************"
sudo snap install microk8s --classic --channel=1.20/stable
sudo microk8s.start

echo "***************************** Microk8s - STATUS *****************************"
sudo microk8s.status 

echo "***************************** Microk8s - Enable Dashboard *****************************"
sudo microk8s.enable dns dashboard ingress
sudo microk8s.kubectl proxy --accept-hosts=.* --address=0.0.0.0 &

echo "***************************** Microk8s - Info *****************************"
microk8s.kubectl get nodes -o wide
microk8s.kubectl get services -o wide
microk8s.kubectl get all --all-namespaces

echo "***************************** Microk8s - Deployment *****************************"
microk8s.kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
microk8s.kubectl get pods

echo "***************************** Microk8s - Disable Security *****************************" 
#### add line after auto-generate-certificates =>  - --enable-skip-login ####
microk8s.kubectl apply -f /vagrant/scripts/recommended.yaml

echo "***************************** Microk8s - Dashboard Access using Token *****************************"
#sudo microk8s.kubectl -n kubernetes-dashboard describe sa dashboard-admin-sa
#sudo microk8s.kubectl -n kubernetes-dashboard describe secret dashboard-admin-sa-token
microk8s.kubectl version --short