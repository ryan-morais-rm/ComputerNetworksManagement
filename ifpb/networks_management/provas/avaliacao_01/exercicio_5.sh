#!/bin/bash
set -e

sudo dnf install -y php-pgsql
sudo systemctl restart php-fpm

sudo cp db.php /var/www/html/phpsite/db.php

sudo chown nginx:nginx /var/www/html/phpsite/db.php
sudo chmod 644 /var/www/html/phpsite/db.php

sudo restorecon -v /var/www/html/phpsite/db.php

echo "Rodando o teste de conexão via CLI..."
php test_db_cli.php