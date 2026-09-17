
#!/bin/bash

a. Instale o repositório Zabbix
Documentação

#Disable Zabbix packages provided by EPEL, if you have it installed. Editar arquivo /etc/yum.repos.d/epel.repo and add the following statement.
[epel]
...
excludepkgs=zabbix*

Proceed with installing zabbix repository.
# rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/centos/9/noarch/zabbix-release-latest-7.4.el9.noarch.rpm
# dnf clean all
b. Instale o servidor, o frontend e o agente Zabbix
# dnf install zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
c. Criar banco de dados inicial
Documentação

Make sure you have database server up and running.

Execute os seguintes passos em seu host de banco de dados.
# sudo -u postgres createuser --pwprompt zabbix
# sudo -u postgres createdb -O zabbix zabbix

No servidor do Zabbix, importe o esquema inicial e os dados. Vocá será solicitado a inserir a senha que foi criada anteriormente.
# zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
d. Configure o banco de dados para o servidor Zabbix

Editar arquivo /etc/zabbix/zabbix_server.conf
DBPassword=password
e. Configure o PHP para o frontend Zabbix

Editar arquivo /etc/nginx/conf.d/zabbix.conf descomente e defina as diretivas 'listen' e 'server_name'.
# listen 8080;
# server_name example.com;
f. Inicie o servidor Zabbix e os processos do agente

Inicie o servidor Zabbix e os processos do agente e configure-os para que sejam iniciados durante o boot do sistema.
# systemctl restart zabbix-server zabbix-agent nginx php-fpm
# systemctl enable zabbix-server zabbix-agent nginx php-fpm 