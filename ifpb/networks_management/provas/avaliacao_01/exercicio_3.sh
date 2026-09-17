#!/bin/bash
sudo dnf install -y php-fpm
sudo systemctl enable --now php-fpm

sudo mkdir -p /var/www/html/phpsite
sudo cp index.php /var/www/html/phpsite/index.php

sudo cp phpsite.conf /etc/nginx/conf.d/phpsite.conf
sudo systemctl restart nginx php-fpm
