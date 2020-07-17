#!/usr/bin/env bash

sudo apt-get install -y zip unzip

echo "***************************** JAVA 8 RUNTIME ENV - Installation *****************************"
sudo apt-get -y install openjdk-8-jdk
java -version

echo "***************************** MAVEN - Installation *****************************"
sudo apt -y install maven
mvn -version

echo "***************************** JENKINS - Installation *****************************"
wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get -y update
sudo apt-get -y install jenkins

echo "***************************** JENKINS - CHECK-STATUS *****************************"
sudo systemctl start jenkins
sudo systemctl status jenkins

echo "***************************** PRINT - PASSWORD *****************************"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "***************************** PLUGINS - INSTALLATION *****************************"
sudo /vagrant/scripts/install-plugins.sh  < /vagrant/scripts/plugins.txt