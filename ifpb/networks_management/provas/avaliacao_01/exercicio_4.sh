#!/bin/bash

sudo dnf install -y postgresql-server postgresql
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql

sudo -i -u postgres
psql 
\l
CREATE DATABSE if_db;
\q

sudo dnf install -y php-pgsql
sudo systemctl restart php-fpm