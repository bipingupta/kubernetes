# PostgreSQL-vagrant
A simple vagrant box with PostgreSQL server.

## Getting started
1. Clone this repository
2. Run `vagrant up`

## Connecting to PostgreSQL
Host: `172.42.42.42`  
User: `root`  
Password: `root`  
Port: `5432`

Ensure that PostgreSQL is not running on your machine before starting up, as there will be a port conflict. Vagrant will soon tell you :)

---
_Note: Only be used for development purposes._

"Env variable for application development:"
"  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME"

"Local command to access the database via psql:"
"  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME"


