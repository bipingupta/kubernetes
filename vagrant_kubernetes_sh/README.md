
This is a guide for anyone wanting to setup Kubernetes Multi Node Cluster on "ubuntu/xenial64".

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

Navigate to ```multi_kubernetes_sh``` directory
```

##### Spin up Kubernetes cluster

Navigate to ```multi_kubernetes_sh``` directory and then run the following command to start the Vagrant:

$ vagrant up
```
Now, wait for kubernetes cluster to be ready. This might take a while to complete.

&nbsp;

##### Access Kubernetes Dashboard

http://172.42.42.100:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default
