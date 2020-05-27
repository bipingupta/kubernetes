#!/usr/bin/env bash

echo "***************************** MongoDB - Installation *****************************"
if [ ! -f /usr/bin/mongod ]
    then
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
		sudo apt-get install gnupg
        echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
        sudo apt-get update -y
        sudo apt-get install mongodb-org -y
        sudo mkdir -p /data/db
        sudo chown -R $USER /data/db 
        sudo chmod -R go+w /data/db
else
  echo "mongo db already installed.  Skipping..."
fi
sudo systemctl start mongod
sudo systemctl daemon-reload
sudo systemctl status mongod

sleep 5

mongo admin <<'EOF'
use admin
rs.initiate()
exit
EOF

sleep 5

echo "Adding admin user"
mongo admin <<'EOF'
use admin
rs.initiate()
var user = {
  "user" : "admin",
  "pwd" : "admin",
  roles : [
      {
          "role" : "userAdminAnyDatabase",
          "db" : "admin"
      }
  ]
}
db.createUser(user);
exit
EOF

echo "Complete"