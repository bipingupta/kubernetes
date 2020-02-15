#!/usr/bin/env bash

echo "***************************** erlang - Installation *****************************"
cd /opt/
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get update -y

# Install erlang on ubuntu
sudo apt-get install erlang -y

# Alternatively, you can to install erlang on ubuntu with specify version
# To search for erlang package version on ubuntu with apt-cache command as below:
sudo apt-cache show erlang
# To install erlang package version
#sudo apt-get install erlang=version-number

echo "***************************** RabbitMQ - Installation *****************************"
echo "deb https://dl.bintray.com/rabbitmq/debian xenial main erlang"  | sudo tee  /etc/apt/sources.list.d/bintray.rabbitmq.list > /dev/null
wget -O - 'https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc' | sudo apt-key add -
sudo apt-get update -y
sudo apt-get install rabbitmq-server -y
sudo service rabbitmq-server start
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmqctl add_user admin admin
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
sudo rabbitmqctl delete_user guest
sudo service rabbitmq-server restart
sudo systemctl status  rabbitmq-server.service 
systemctl is-enabled rabbitmq-server.service 

