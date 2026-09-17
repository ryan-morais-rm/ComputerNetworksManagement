#!/bin/bash

sudo dnf upgrade --refresh
sudo dnf install -y nginx
sudo systemctl enable --now nginx

sudo mkdir -p /var/www/html/poetas
sudo cp index.html /var/www/html/poetas

sudo cp poetas.conf /etc/nginx/conf.d/poetas.conf

sudo systemctl restart nginx

sudo tail -f /var/log/nginx/access.log >> acess.log
sudo tail -f /var/log/nginx/error.log >> error.log