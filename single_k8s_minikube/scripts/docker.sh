#!/bin/bash

echo "***************************** Begin installing D O C K E R  - C E *****************************"

#echo "****************** Docker => Uninstall old version *****************************"
#sudo apt-get -y remove docker docker-engine docker.io containerd runc

#echo "****************** Docker => Update the apt package index *****************************"
#sudo apt-get update

##Install packages to allow apt to use a repository over HTTPS
#sudo apt-get -y install apt-transport-https
#sudo apt-get -y install ca-certificates
#sudo apt-get -y install curl
#sudo apt-get -y install software-properties-common

echo "****************** Docker => Add Docker’s official GPG key ********************"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#echo "****************** Docker => Set up the stable repository *****************************"
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#echo "****************** Docker => Installing Docker CE *****************************"
#sudo apt-get update
#sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu

echo "****************** Docker => Installing Containerd.io,Docker-ce-cli,Docker-ce *****************************"
export DOWNLOAD_PACKAGE=/vagrant/download
sudo dpkg -i $DOWNLOAD_PACKAGE/containerd.io.deb
sudo dpkg -i $DOWNLOAD_PACKAGE/docker-ce-cli.deb
sudo dpkg -i $DOWNLOAD_PACKAGE/docker-ce.deb

echo "****************** Docker => To check Docker is auto-started & auto-enabled at system boot *****************************"
sudo systemctl status docker 

echo "****************** Docker => Verify that Docker CE is installed correctly *****************************"
sudo docker run hello-world
#use Docker as a non-root user
usermod -aG docker vagrant

echo "***************************** End installing D O C K E R  - C E *****************************"
