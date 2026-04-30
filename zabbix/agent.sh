#!/bin/bash

# 1. Verifica os argumentos LOGO NO INÍCIO
if [ "$#" -ne 2 ]; then
    echo "Uso: sudo $0 <IP_DO_SERVIDOR_ZABBIX> <NOME_DA_VM>"
    exit 1
fi

SERVER_IP=$1
VM_HOSTNAME=$2

# 2. Detecta a Distro e Versão para baixar o Repo correto
. /etc/os-release
DISTRO=$ID # debian ou ubuntu
VERSION_CODENAME=$VERSION_CODENAME # ex: bookworm, jammy, noble

echo "Detectado: $DISTRO $VERSION_CODENAME"

# Ajustando regras de firewall
sudo ufw allow 10050/tcp && sudo ufw allow 10051/tcp

# 3. Baixa e instala o repositório oficial dinamicamente
wget "https://repo.zabbix.com/zabbix/7.0/$DISTRO/pool/main/z/zabbix-release/zabbix-release_latest_7.0+$DISTRO${VERSION_ID}_all.deb" -O zabbix-release.deb
sudo dpkg -i zabbix-release.deb
sudo apt update

# 4. INSTALA o Agente 
sudo apt install -y zabbix-agent2 zabbix-agent2-plugin-*
CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"

# 5. Backup e Configuração 
if [ -f "$CONFIG_FILE" ]; then
    echo "Configurando Zabbix Agent 2 para: $VM_HOSTNAME"
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    sed -i "s/^Server=.*/Server=$SERVER_IP/" "$CONFIG_FILE"
    sed -i "s/^ServerActive=.*/ServerActive=$SERVER_IP/" "$CONFIG_FILE"
    sed -i "s/^Hostname=.*/Hostname=$VM_HOSTNAME/" "$CONFIG_FILE"
    sed -i "s/^# HostnameItem=/HostnameItem=/" "$CONFIG_FILE" # Opcional: útil se quiser deixar dinâmico
    
    systemctl restart zabbix-agent2
    systemctl enable zabbix-agent2
    echo "Tudo pronto! Zabbix Agent 2 ativo e configurado."
else
    echo "Erro: O arquivo de configuração não foi criado. A instalação falhou?"
    exit 1
fi