#!/bin/bash
set -e

sudo dnf install -y php-fpm

sudo sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf

sudo mkdir -p /var/www/html/phpsite
sudo cp index.php /var/www/html/phpsite/index.php
sudo cp phpsite.conf /etc/nginx/conf.d/phpsite.conf

sudo dnf install -y policycoreutils-python-utils
sudo semanage port -a -t http_port_t -p tcp 8081
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --reload

sudo chown -R nginx:nginx /var/www/html/phpsite
sudo chmod -R 755 /var/www/html/phpsite

sudo restorecon -Rv /var/www/html/phpsite

sudo systemctl enable --now php-fpm
sudo systemctl restart nginx php-fpm

echo "NGINX e PHP-FPM configurados com sucesso!"

