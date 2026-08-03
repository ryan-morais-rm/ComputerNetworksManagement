#!/bin/bash
set -e

# Configuração do Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Senha exportada
export PGPASSWORD="$POSTGRES_PASSWORD"

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/zabbix/nginx.conf /etc/nginx/conf.d/zabbix.conf

# Configuraçõa para o nginx não sequestrar a porta 80
sed -i 's/#        listen          8080;/        listen          80;/' /etc/zabbix/nginx.conf
sed -i 's/#        server_name     example.com;/        server_name     localhost;/' /etc/zabbix/nginx.conf

# ------------------------------------------

echo "Aguardando o banco de dados em $DB_SERVER_HOST..."
until pg_isready -h "$DB_SERVER_HOST" -U "$POSTGRES_USER"; do
  sleep 2
done

# Configurar o zabbix_server.conf
sed -i "s/^# DBPassword=/DBPassword=$POSTGRES_PASSWORD/" /etc/zabbix/zabbix_server.conf
sed -i "s/^DBHost=localhost/DBHost=$DB_SERVER_HOST/" /etc/zabbix/zabbix_server.conf

# Importar o Schema se necessário
DB_EXISTS=$(psql -h "$DB_SERVER_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users');")

if [ "$DB_EXISTS" != "t" ]; then
    echo "Importando schema inicial do Zabbix..."
    if [ -f "/usr/share/zabbix-sql-scripts/postgresql/server.sql.gz" ]; then
        zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | psql -h "$DB_SERVER_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB"
        echo "Importação concluída com sucesso!"
    else
        echo "ERRO CRÍTICO: Arquivo SQL não encontrado em /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz"
        exit 1
    fi
fi

mkdir -p /run/php
php-fpm8.2 -D

echo "Iniciando Nginx e Agente..."
nginx -g "daemon off;" & 
/usr/sbin/zabbix_agent2 -c /etc/zabbix/zabbix_agent2.conf &

echo "Iniciando Zabbix Server..."
exec /usr/sbin/zabbix_server -f -c /etc/zabbix/zabbix_server.conf