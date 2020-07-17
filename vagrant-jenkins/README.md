# Jenkins-vagrant
A simple vagrant box with Jenkins-Server.

## Getting started
1. Clone this repository
2. Run `vagrant up`

## Connecting to Jenkins-Server
# http://172.42.42.42:8080/

## Retrieving Admin Password
# vagrant ssh 
sudo cat /var/snap/jenkins/1242/secrets/initialAdminPassword

Install following Plugin 
https://caylent.com/jenkins-plugins

Ensure that Jenkins-Server is not running on your machine before starting up, as there will be a port conflict. Vagrant will soon tell you :)

---
_Note: Only be used for development purposes._



