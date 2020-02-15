#!/usr/bin/env bash

# Version of PostgreSQL that is installed
PG_VERSION=9.5

echo "***************************** Update package list and upgrade all packages *****************************"
apt-get update

echo "***************************** PostgreSQL-Server - Installation *****************************"
apt-get -y install "postgresql-$PG_VERSION" "postgresql-contrib-$PG_VERSION"


echo "************** PostgreSQL-Server - fixing listen_addresses on postgresql.conf **************"
sudo sed -i "s/#listen_address.*/listen_addresses '*'/" /etc/postgresql/$PG_VERSION/main/postgresql.conf

echo "************** PostgreSQL-Server - fixing postgres pg_hba.conf file **************"
sudo cat >> /etc/postgresql/$PG_VERSION/main/pg_hba.conf <<EOF
# Accept all IPv4 connections - FOR DEVELOPMENT ONLY!!!
host    all         all         0.0.0.0/0             md5
EOF

echo "************** PostgreSQL-Server - creating postgres root role with password root **************"
sudo su postgres -c "psql -c \"CREATE ROLE root SUPERUSER LOGIN PASSWORD 'root'\" "

echo "************** PostgreSQL-Server - creating wtm database **************"
sudo su postgres -c "createdb -E UTF8 -T template0 --locale=en_US.utf8 -O root wtm"

echo "Successfully created PostgreSQL dev virtual machine."
echo ""