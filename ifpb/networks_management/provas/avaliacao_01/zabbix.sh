#!/bin/bash
set -e

ZABBIX_PASS="zabbix"

echo "==> a. Configurando o repositório do Zabbix..."
if [ -f /etc/yum.repos.d/epel.repo ]; then
    sudo sed -i '/^\[epel\]/a excludepkgs=zabbix*' /etc/yum.repos.d/epel.repo
fi

sudo rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/centos/9/noarch/zabbix-release-latest-7.4.el9.noarch.rpm || true
sudo dnf clean all

echo "==> b. Instalando servidor, frontend e agente Zabbix..."
sudo dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent

echo "==> c. Criando o banco de dados inicial..."
sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '${ZABBIX_PASS}';" || true
sudo -u postgres psql -c "DROP DATABASE IF EXISTS zabbix;"
sudo -u postgres psql -c "CREATE DATABASE zabbix OWNER zabbix;"

echo "==> Importando o esquema de dados do Zabbix (Como dono das tabelas)..."
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | PGPASSWORD="${ZABBIX_PASS}" psql -h 127.0.0.1 -U zabbix -d zabbix

echo "==> d. Configurando o banco de dados no servidor Zabbix..."
sudo sed -i "s/# DBPassword=/DBPassword=${ZABBIX_PASS}/g" /etc/zabbix/zabbix_server.conf
echo "DBHost=127.0.0.1" | sudo tee -a /etc/zabbix/zabbix_server.conf

echo "==> e. Configurando o NGINX (Alterando para a porta 8082 para não conflitar com o site Poetas)..."
sudo sed -i 's/#        listen          8080;/        listen          8082;/g' /etc/nginx/conf.d/zabbix.conf
sudo sed -i 's/#        server_name     example.com;/        server_name     localhost;/g' /etc/nginx/conf.d/zabbix.conf

echo "==> Liberando portas e permissões (Firewall e SELinux)..."
sudo semanage port -a -t http_port_t -p tcp 8082 || true
sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --reload
sudo setsebool -P zabbix_can_network 1

echo "==> f. Iniciando os serviços do Zabbix..."
sudo systemctl restart zabbix-server zabbix-agent nginx php-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php-fpm

echo "=========================================================="
echo " Instalação Concluída com Sucesso!"
echo "=========================================================="