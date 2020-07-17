#!/usr/bin/env bash

echo "***************************** PHP - Installation *****************************"
sudo apt-get update
sudo apt-get install -y php

echo "***************************** PHPMyAdmin - Installation *****************************" 
sudo apt-get update
sudo apt-get install -y phpmyadmin php-mbstring php-gettext apache2-utils

echo "***************************** Apache 2 - Installation *****************************" 
sudo apt-get install  -y apache2 
sudo apt-get install -y php-{bcmath,bz2,intl,gd,mbstring,mcrypt,mysql,zip,curl} && sudo apt-get install libapache2-mod-php -y

echo "***************************** Apache 2 - configuring *****************************" 
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

rm -rf /var/www/html
ln -fs /vagrant/public /var/www/html

sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/apache2/php.ini

echo "***************************** apache2 restart *****************************" 
sudo service apache2 restart



