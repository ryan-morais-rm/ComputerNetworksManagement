#!/bin/bash
set -e

sudo dnf install -y postgresql-server postgresql

sudo postgresql-setup --initdb

sudo systemctl enable --now postgresql

sudo -u postgres psql -c "CREATE DATABASE ABCDEFGH;"

sudo -u postgres psql -c "\l"

sudo dnf install -y php-pgsql

sudo systemctl restart php-fpm

sudo setsebool -P httpd_can_network_connect_db 1

echo "PostgreSQL instalado e banco 'ABCDEFGH' criado com sucesso!"