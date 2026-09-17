#!/bin/bash

sudo dnf install -y php-pgsql
sudo systemctl restart php-fpm

sudo cp db.php /var/www/html/phpsite/db.php

php test_db_cli.php