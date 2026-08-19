# Replicando "Comparison of WebSocket and HTTP Protocol Performance" com Docker

Este projeto é um ponto de partida para reproduzir, de forma adaptada, o
estudo de Łasocha & Badurowicz (2021) sobre desempenho de HTTP vs. WebSocket,
usando apenas um notebook (via containers Docker) em vez do laboratório com
switch, servidor e dois laptops usado no artigo original.

## O que o artigo original fez (resumo)

Os autores mediram o tempo de envio/recebimento de strings de 100 caracteres,
em lotes de 1 a 3.000 cópias, comparando HTTP (POST/GET) com WebSocket (via
Socket.IO), em duas máquinas cliente diferentes (um laptop rápido e um lento),
três navegadores, com e sem TLS, e com e sem cabeçalhos HTTP extras
("overhead"). Cada medição foi repetida 10 vezes e a média foi usada nos
gráficos. As conclusões principais foram: WebSocket fica muito mais rápido
que HTTP a partir de ~100 mensagens; overhead de cabeçalhos só derruba
performance de forma perceptível com ~100 cabeçalhos extras; TLS tem impacto
mínimo em ambos os protocolos; e o desempenho do WebSocket independe do
hardware/navegador do cliente, ao contrário do HTTP.

## O que muda na replicação (e por quê)

Como existe a limitação de apenas um notebook, **não é possível reproduzir 
literalmente** a parte do estudo que compara hardwares/navegadores diferentes 
em uma LAN física. O que este setup faz para chegar o mais perto possível, 
dentro do que é viável:

1. **Servidor e cliente em containers separados**, ligados por uma rede
   Docker *bridge* dedicada (`benchlan`). Isso dá dois "hosts" de rede
   distintos (IPs diferentes, uma interface de rede real entre eles), mesmo
   rodando na mesma máquina física — o suficiente para testar o protocolo de
   verdade (handshake, HTTP keep-alive, etc.), porém sem a latência de uma
   LAN física (a rede virtual do Docker é ordens de magnitude mais rápida que
   Ethernet/Wi-Fi real).
2. Isso significa que **os valores absolutos de tempo não serão comparáveis**
   aos do artigo (ambiente docker será mais rápido). O que será validado é o 
   **comportamento relativo**: HTTP vs WebSocket conforme o número
   de cópias cresce, o efeito do overhead de cabeçalhos, e o efeito do TLS.
   Isso será declarado explicitamente no relatório como limitação.
3. É possível adicionar latência artificial com `tc`/`netem` dentro do container 
   cliente (está comentado no `docker-compose.yml`, com `cap_add: NET_ADMIN`) 
   — por exemplo, 1-2 ms de latência simulando uma Gigabit LAN típica.
4. Como só está disponível uma configuração de hardware, **não é possível reproduzir a
   comparação "laptop rápido vs. laptop lento"**. Uma alternativa honesta é
   limitar artificialmente a CPU do container cliente com `docker run --cpus`
   ou `deploy.resources.limits` para simular um "cliente mais fraco" e comparar
   com o container sem limite — isso te dá pelo menos uma variável de
   hardware para comparar, mesmo que não seja fisicamente outro laptop.
5. **Navegadores** ficam de fora: o teste roda via Node.js diretamente (Axios
   para HTTP, `socket.io-client` para WebSocket), sem abrir Chrome/Firefox/
   Edge. Isso é uma limitação real da replicação — vale pontuar no relatório
   que está sendo medido o protocolo "puro", sem overhead do motor de
   JavaScript do navegador.

## Estrutura

```
wsbench/
├── docker-compose.yml
├── server/          # servidor Express + Socket.IO (HTTP, HTTPS, WS, WSS)
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── client/           # script de benchmark
│   ├── Dockerfile
│   ├── benchmark.js
│   ├── summarize.js
│   └── package.json
├── run-all.sh        # roda a bateria completa de cenários, sem interação
└── data/             # dados recebidos pelo servidor + CSVs de resultado (criado em runtime)
```

## Rodando a bateria completa automaticamente

O jeito mais simples de reproduzir tudo é usar o `run-all.sh`, que builda as
imagens, sobe os containers, roda **todos** os cenários do artigo (HTTP vs
WebSocket, com e sem TLS, envio e recebimento, 1 a 3.000 cópias, e a varredura
de overhead de cabeçalhos) e no final derruba os containers — sem pedir
nenhuma confirmação no meio do caminho:

```bash
cd wsbench
chmod +x run-all.sh 
./run-all.sh
```

Isso vai gerar, dentro de `./data`:

- Um CSV bruto por cenário (ex.: `http-send-oh0.csv`, `wss-receive-oh0.csv`,
  `http-send-oh100.csv`, ...), com o tempo de cada uma das `RUNS` repetições
  por quantidade de cópias.
- `summary.csv`, consolidando tudo em uma única tabela com
  `protocol, direction, overhead, copies, runs, avg_ms, min_ms, max_ms` — pronta
  para importar numa planilha e montar os gráficos de barras equivalentes aos
  do artigo.
- `run.log`, com o log completo da execução (útil se algum cenário falhar).

Variáveis de ambiente opcionais:

```bash
RUNS=5 ./run-all.sh          # menos repetições por ponto (mais rápido para testar o script)
KEEP_UP=1 ./run-all.sh       # não derruba os containers no final
SKIP_BUILD=1 ./run-all.sh    # pula o rebuild das imagens
```

A bateria completa com `RUNS=10` (o padrão, igual ao artigo) soma bastante
execuções — em especial o teste com 3.000 cópias sequenciais — então
espera-se que a execução total leve de alguns minutos a algumas dezenas de
minutos, dependendo da máquina.

## Rodando cenários individuais manualmente

Se a preferência for rodar somente um cenário por vez (por exemplo, para depurar algo),
suba o ambiente e chame o `benchmark.js` diretamente:

```bash
docker compose up -d --build
```

Isso sobe o servidor (portas 3000 = HTTP/WS, 3443 = HTTPS/WSS) e o cliente
(que fica ocioso, esperando o usuário rodar os testes manualmente via `exec`).

### Rodando um teste

```bash
docker compose exec client node benchmark.js \
  --protocol=http --direction=send --copies=1,3,10,30,100,300,1000,3000 --runs=10
```

Parâmetros disponíveis (veja os comentários no topo de `benchmark.js`):

| Parâmetro     | Valores                        | Descrição                                   |
|---------------|---------------------------------|----------------------------------------------|
| `--protocol`  | `http`, `https`, `ws`, `wss`   | Protocolo testado                             |
| `--direction` | `send`, `receive`               | Enviar para o servidor ou baixar/receber dele |
| `--copies`    | lista separada por vírgula      | Quantidades de cópias testadas                |
| `--runs`      | número                          | Repetições por ponto (padrão 10, igual ao artigo) |
| `--overhead`  | número                          | Cabeçalhos HTTP extras (só HTTP/HTTPS)        |

Exemplos equivalentes às seções do artigo original:

```bash
# 4.2 — Envio e recebimento via HTTP
docker compose exec client node benchmark.js --protocol=http --direction=send
docker compose exec client node benchmark.js --protocol=http --direction=receive

# 4.3 — Envio e recebimento via WebSocket
docker compose exec client node benchmark.js --protocol=ws --direction=send
docker compose exec client node benchmark.js --protocol=ws --direction=receive

# 4.5 — Impacto do overhead (100 cópias fixas, variando cabeçalhos extras)
for oh in 0 10 50 100 200 300; do
  docker compose exec client node benchmark.js \
    --protocol=http --direction=send --copies=100 --overhead=$oh
done

# 4.6 — Impacto do TLS
docker compose exec client node benchmark.js --protocol=https --direction=send
docker compose exec client node benchmark.js --protocol=wss --direction=send
```

Cada execução salva um CSV em `data/` com o tempo (em ms) de cada uma das
`RUNS` repetições por quantidade de cópias — é possível importar isso direto
numa planilha para montar os mesmos tipos de gráfico de barras do artigo. Se 
é necessário ser executado manualmente(fora do `run-all.sh`) e quer o
mesmo `summary.csv` consolidado:

```bash
docker compose exec client node summarize.js
```

### Limpando entre execuções

O `benchmark.js` faz essa limpeza dos dados HTTP acumulados no servidor antes
de cada rodada (equivalente ao botão "Delete" do artigo).Porém, se for necessá-
rio resetar tudo manualmente:

```bash
docker compose exec server rm -f /app/data/received.log
```