## 1. No Servidor (Host Ubuntu/Debian)
### Para preparar a imagem e subir o monitoramento:

Buildar a imagem customizada:
``` docker compose build ```

Subir o ambiente (Postgres + Zabbix):
``` docker compose up -d ```

Verificar se os containers estão rodando:
``` docker ps ```

## 2. Nas Máquinas Virtuais (Agentes)
### Para instalar e vincular a VM ao servidor:

Dar permissão ao script de configuração:
``` chmod +x agent.sh ```

Executar a configuração (Ajuste o IP e o Nome, IP meramente ilustrativo):
``` sudo ./agent.sh 192.168.60.1 VM-01 ```

## 3. Comandos de Verificação (Troubleshooting)
### Se o ícone ZBX não ficar verde, use estes comandos para achar o erro:

Ver os logs do Zabbix no Docker:
``` docker compose logs -f zabbix-app ```

Testar se o Servidor alcança a VM (Porta 10050):
``` docker exec -it zabbix-app zabbix_get -s 192.168.60.10 -k agent.ping ```

Testar se a VM alcança o Servidor (Porta 10051):
``` telnet 192.168.60.1 10051 ```

Verificar logs do agente dentro da VM:
``` sudo tail -f /var/log/zabbix/zabbix_agent2.log ```