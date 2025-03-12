CREATE DATABASE IF NOT EXISTS dev;
CREATE DATABASE IF NOT EXISTS test;
USE dev;
CREATE TABLE IF NOT EXISTS (...);

-- create the databases
CREATE DATABASE IF NOT EXISTS projectone;

-- create the users for each database
CREATE USER 'projectoneuser'@'%' IDENTIFIED BY 'somepassword';
GRANT CREATE, ALTER, INDEX, LOCK TABLES, REFERENCES, UPDATE, DELETE, DROP, SELECT, INSERT ON `projectone`.* TO 'projectoneuser'@'%';

FLUSH PRIVILEGES;

create database debezium_demo;
use debezium_demo;
Create a table "user":
create table user (
    user_id int primary key,
    first_name varchar(50),
    last_name varchar(50),
    city varchar(50),
    state varchar(50),
    pincode varchar(10)
);
insert into user values (1, "John", "Doe", "Seattle", "Washington", "98101");
