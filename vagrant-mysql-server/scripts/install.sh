#!/usr/bin/env bash

# update the apt package
sudo apt-get update
sudo apt-get install -y debconf-utils
sudo debconf-get-selections | grep mysql

# Installing Without Prompts
export DEBIAN_FRONTEND="noninteractive"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

# install the MySQL package
sudo apt-get install -y mysql-server

### secure the mysql installation
#mysql_secure_installation

# set root password
sudo mysqladmin -u root -proot version

# allow remote access
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;"

# drop the anonymous users
#mysql -u root -proot -e "DROP USER ''@'localhost';"
#mysql -u root -proot -e "DROP USER ''@'$(hostname)';"

# drop the demo database
#mysql -u root -proot -e "DROP DATABASE test;"

# flush
#mysql -u root -proot -e "FLUSH PRIVILEGES;"
