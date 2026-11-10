# Laboratório URA Asterisk + Google TTS + MySQL

Este pacote contém os arquivos configurados para subir o ambiente via Docker.

## Estrutura

- `docker-compose.yaml` (Orquestração de Asterisk, DB e Linphones)
- `sip.conf` (Configuração dos ramais SIP)
- `extensions.conf` (Plano de discagem da URA)
- `db-init/init.sql` (Script que cria a tabela no MySQL automaticamente)
- `agi-bin/checkmatricula.agi` (Script AGI ajustado para conectar no host 'db' via rede Docker)

## Passos para uso:

1. Baixe os dois scripts externos pendentes para dentro da pasta `agi-bin`:
   - `phpagi.php` (Pode ser encontrado no repositório oficial do PHPAGI)
   - `googletts.agi` (Pode ser encontrado no github: zaf/asterisk-googletts)
3. Garanta que os scripts possuem permissão de execução:
   `chmod +x agi-bin/checkmatricula.agi agi-bin/googletts.agi`
4. Libere a exibição dos Linphones (se estiver usando interface gráfica no Linux):
   `xhost +local:docker`
5. Suba todos os containers em background:
   `docker compose up -d`
