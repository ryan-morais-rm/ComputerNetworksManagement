# MACHINE-SETUP.md

Documentação do ambiente de testes usado para a replicação adaptada do artigo
*Comparison of WebSocket and HTTP Protocol Performance* (Łasocha & Badurowicz,
2021). Diferente do estudo original — que usou um switch dedicado, um
servidor físico e dois laptops clientes em uma LAN — aqui todo o experimento
roda em containers Docker dentro de uma única máquina.

## 1. Hardware

| Item | Especificação |
|---|---|
| Notebook | ASUS Vivobook X1502ZA |
| CPU | Intel Core i7-1255U (12ª geração), 12 threads, clock base 3333 MHz, turbo até 4700 MHz |
| GPU | Intel Iris Xe Graphics (Alder Lake-UP3 GT2, integrada) |
| RAM (total) | 15 GiB (~16 GB) |
| Swap | 1,9 GiB |
| Armazenamento | NVMe Intel SSDPEKNU512GZ (SSD 670p Series), 512 GB |
| Partição raiz (`/`) | 306 GB |
| Interface de rede | Realtek RTL8821CE 802.11ac (Wi-Fi PCIe) — **sem interface Ethernet cabeada** |

**Relevância para o teste:** a CPU (12 threads, até 4,7 GHz) e o SSD NVMe não
devem ser gargalo para os volumes de dados testados (textos de ~100 bytes).
O ponto mais importante para a metodologia é a ausência de uma placa de rede
cabeada — os containers Docker se comunicam por uma rede virtual em software
(bridge), não pela interface Wi-Fi física, então essa limitação não afeta o
teste em si, mas reforça por que os tempos aqui não são comparáveis aos de
uma LAN Gigabit real como a do artigo original.

## 2. Sistema operacional

| Item | Versão |
|---|---|
| Distribuição | Ubuntu 24.04.4 LTS (x86_64) |
| Kernel | 6.14.0-37-generic |
| Shell | bash 5.2.21 |

## 3. Software de containerização

| Item | Versão usada no projeto |
|---|---|
| Docker / Docker Compose | conforme instalado a partir de https://docs.docker.com/engine/install/ubuntu/ (usar `docker compose version` para registrar a versão exata antes de rodar os testes) |
| Imagem base dos containers | `node:20-slim` (servidor e cliente) |
| Versão do docker | `29.2.1, build a5c7197` |
| Versão do docker compose | `v5.0.2` |

## 4. Versões de software usadas no teste

| Componente | Versão |
|---|---|
| Node.js (dentro dos containers) | 20.x (imagem `node:20-slim`) |
| Express.js (servidor HTTP) | ^4.19.2 |
| Socket.IO (servidor WebSocket) | ^4.7.5 |
| socket.io-client (cliente WebSocket) | ^4.7.5 |
| Axios (cliente HTTP) | ^1.7.4 |
| Protocolo HTTP | HTTP/1.1 (padrão do módulo `http`/`https` do Node.js e do Express) |
| Protocolo WebSocket | RFC 6455, via Socket.IO (fallback de *long-polling* desativado — `transports: ["websocket"]` forçado no cliente) |
| TLS (para HTTPS/WSS) | certificado autoassinado gerado com OpenSSL (RSA 2048 bits), TLS negociado pelo módulo `https` do Node.js |

## 5. Diferenças declaradas em relação ao artigo original

| Aspecto | Artigo original | Esta replicação |
|---|---|---|
| Topologia de rede | Switch Gigabit físico + 2 laptops + 1 servidor | Rede *bridge* virtual do Docker, tudo em 1 máquina |
| Hardware do servidor | HP ProLiant DL320 G5 (Xeon, RAID 0) | Container na mesma CPU i7-1255U do cliente |
| Hardware do(s) cliente(s) | 2 laptops com specs diferentes (Acer Aspire 5 vs Asus K50IN) | 1 único perfil de CPU (pode ser simulado limitando `--cpus` no container, para comparar 2 cenários) |
| Sistemas operacionais testados | Windows 10 e Fedora 33 Workstation | Ubuntu 24.04.4 LTS (único SO, containers Linux) |
| Navegadores testados | Chrome, Firefox, Edge | Nenhum — testes via Node.js puro (Axios / socket.io-client) |
| Servidor de aplicação | Node.js + Express + Socket.IO | Node.js 20 + Express + Socket.IO (mesmas bibliotecas) |
| TLS | Certificado gerado com OpenSSL | Certificado autoassinado gerado com OpenSSL (equivalente) |

Essas diferenças devem ser levadas em consideração pelo motivo que os **valores absolutos**
de tempo não serão comparáveis aos do artigo, ainda que o **comportamento relativo** entre
HTTP e WebSocket (o objeto principal da comparação) continue sendo válido de se testar. 
