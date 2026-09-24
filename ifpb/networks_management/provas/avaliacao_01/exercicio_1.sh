#!/bin/bash
set -e

sudo dnf upgrade --refresh -y
sudo dnf install -y nginx

sudo mkdir -p /var/www/html/poetas
sudo cp index.html /var/www/html/poetas/
sudo cp poetas.conf /etc/nginx/conf.d/poetas.conf

sudo chown -R nginx:nginx /var/www/html/poetas
sudo chmod -R 755 /var/www/html/poetas

sudo restorecon -Rv /var/www/html/poetas

sudo systemctl enable --now nginx
sudo systemctl restart nginx

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload

sudo cat /var/log/nginx/access.log > acess.log
sudo cat /var/log/nginx/error.log > error.log

echo "NGINX configurado e página liberada com sucesso!"