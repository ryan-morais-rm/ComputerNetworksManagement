%%bash
echo "=== Iniciando a limpeza do ambiente MQTT / Arduino ==="

# 1. Parar o serviço do Mosquitto
sudo systemctl stop mosquitto

# 2. Remover pacotes instalados via apt (se desejar desinstalar tudo)
sudo apt-get purge -y mosquitto mosquitto-clients net-tools
sudo apt-get autoremove -y

# 3. Limpar arquivos de configuração e certificados do Mosquitto criados nos labs
sudo rm -rf /etc/mosquitto/passwd
sudo rm -rf /etc/mosquitto/certs/
sudo rm -f /etc/mosquitto/mosquitto.conf

# 4. Remover a IDE Arduino CLI baixada e seus arquivos de configuração globais
sudo rm -f /usr/local/bin/arduino-cli
rm -f arduino-cli_1.1.0_Linux_64bit.tar.gz
rm -rf ~/.arduino-cli/

printenv "=== Limpeza concluída com sucesso! O ambiente foi resetado. ==="
