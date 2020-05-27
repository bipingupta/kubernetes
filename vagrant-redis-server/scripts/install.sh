#!/usr/bin/env bash

# Step 1: Install the Build and Test Dependencies
sudo apt-get update
sudo apt-get install -y build-essential tcl

#Step 2: Download and Extract Redis Server Source Code
cd /tmp
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable

#Step 3: Build and Install Redis
make
make test
make install

#Step 4: Configure Redis
mkdir /etc/redis
cp /tmp/redis-stable/redis.conf /etc/redis
sed -i "s/^supervised no/supervised systemd/" /etc/redis/redis.conf
sed -i "s/^dir \.\//dir \/var\/lib\/redis/" /etc/redis/redis.conf

# Create a Redis systemd Unit File
wget -O /etc/systemd/system/redis.service https://gist.githubusercontent.com/clzola/2b98f0b128d94811e43f86412dc375a1/raw/d2b1475ba3c44d6b3341a724166004e366a7304b/redis.service

# Create the Redis User, Group and Directories
adduser --system --group --no-create-home redis
mkdir /var/lib/redis
chown redis:redis /var/lib/redis
chmod 770 /var/lib/redis

# Start Redis
systemctl start redis

# Enable Redis to Start at Boot
systemctl enable redis

# Clean
#rm -rf /tmp/redis-stable
#rm /tmp/redis-stable.tar.gz

# Test Redis Server
sudo systemctl start redis
sudo systemctl enable redis
sudo systemctl status redis

# USING SNAP PAKAGE MANAGER
#sudo apt update
#sudo apt install snapd
#sudo snap install redis-server-5-0-2 --beta --devmode

