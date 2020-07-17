#!/usr/bin/env bash

# update the apt package
sudo apt-get update
sudo apt-get install -y debconf-utils
sudo debconf-get-selections | grep mysql

# Installing Without Prompts
export DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

echo "***************************** MySQL-Server - Installation *****************************"
sudo apt-get install -y mysql-server

### secure the mysql installation
#mysql_secure_installation

echo "***************************** MySQL-Server - set root password *****************************"
sudo mysqladmin -u root -proot version

#echo "***************************** MySQL-Server - allow remote access *****************************"
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;"


#echo "***************************** MySQL-Server - FLUSH PRIVILEGES *****************************" 
mysql -u root -proot -e "FLUSH PRIVILEGES;"

#echo "***************************** MySQL-Server - update mysql conf file to allow remote access to the db *****************************" 
sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "***************************** MySQL-Server - restart Mysql-Server *****************************" 
sudo service mysql restart

