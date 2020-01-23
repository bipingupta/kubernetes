
This is a guide for anyone wanting to setup MicroK8s on "ubuntu/xenial64".

Installation
--

Install Vagrant and Vitualbox on Windows 7.0/10

&nbsp;

Getting Started
--

##### Clone this github repo:
```
git clone 
```

Navigate to ```single_k8s-microk8s``` directory
```
$ cd kubernetes.resources/k8s-vagrant/
```

##### Spin up Kubernetes cluster

Navigate to ```single_k8s-microk8s``` directory and then run the following command to start the Vagrant:

$ vagrant up
```
Now, wait for kubernetes cluster to be ready. This might take a while to complete.

&nbsp;

##### Access Kubernetes Dashboard

http://172.42.42.100:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default
