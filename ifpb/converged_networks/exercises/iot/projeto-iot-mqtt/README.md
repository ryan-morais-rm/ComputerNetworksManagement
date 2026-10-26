# Projeto IoT – MQTT e MQTT-SN com Docker

Ambiente experimental de IoT executado integralmente em **contêineres Docker**. O projeto integra o **Home Assistant**, um broker **Eclipse Mosquitto**, um **gateway MQTT-SN (Eclipse Paho)** e dois clientes Python: um *publisher* MQTT-SN, que simula um sensor de temperatura, e um *subscriber* MQTT, que exibe a telemetria recebida.

## Sumário

- [Visão geral](#visão-geral)
- [Arquitetura e fluxo dos dados](#arquitetura-e-fluxo-dos-dados)
- [Pré-requisitos](#pré-requisitos)
- [Estrutura de arquivos](#estrutura-de-arquivos)
- [Ordem de execução (resumo)](#ordem-de-execução-resumo)
- [Passo 1 – Broker Mosquitto](#passo-1--broker-mosquitto)
- [Passo 2 – Gateway MQTT-SN](#passo-2--gateway-mqtt-sn)
- [Passo 3 – Subscriber MQTT](#passo-3--subscriber-mqtt)
- [Passo 4 – Publisher MQTT-SN](#passo-4--publisher-mqtt-sn)
- [Passo 5 – Docker Compose](#passo-5--docker-compose)
- [Passo 6 – Subir o ambiente](#passo-6--subir-o-ambiente)
- [Passo 7 – Visualizar as métricas](#passo-7--visualizar-as-métricas)
- [Solução de problemas](#solução-de-problemas)
- [Encerrar o ambiente](#encerrar-o-ambiente)

## Visão geral

| # | Serviço              | Imagem / Tecnologia                                   | Função                                                 | Porta (host) |
| - | --------------------- | ----------------------------------------------------- | -------------------------------------------------------- | ------------ |
| 1 | `homeassistant`     | `ghcr.io/home-assistant/home-assistant:stable`      | Plataforma de automação residencial                    | 8123/tcp     |
| 2 | `mosquitto`         | `eclipse-mosquitto:latest` (2.x)                    | Broker MQTT                                              | 1883/tcp     |
| 3 | `mqtt-sn-gateway`   | `kyberpunk/paho:udp` (Eclipse Paho MQTT-SN Gateway) | Converte MQTT-SN (UDP) em MQTT (TCP)                     | 10000/udp    |
| 4 | `subscriber-mqtt`   | Python 3.12 + `paho-mqtt` 2.x                       | Assina `homeassistant/sensor/#` e imprime as mensagens | –           |
| 5 | `publisher-mqtt-sn` | Python 3.12 + socket UDP                              | Publica a temperatura simulada via MQTT-SN               | –           |

## Arquitetura e fluxo dos dados

```
publisher-mqtt-sn ──UDP:10000──▶ mqtt-sn-gateway ──TCP:1883──▶ mosquitto ──▶ subscriber-mqtt
                                                                    │
                                                                    └────────▶ homeassistant (integração MQTT)
```

- **MQTT** tradicional trabalha sobre TCP. **MQTT-SN** foi pensado para redes restritas e usa transportes leves, como UDP.
- Um cliente MQTT-SN não fala direto com o broker: o **gateway** faz a conversão de protocolo.
- O publisher segue o fluxo MQTT-SN completo: `CONNECT` → `REGISTER` do tópico → `PUBLISH` com QoS 1, aguardando o `PUBACK`.
- Tópico da telemetria: `homeassistant/sensor/temp_garagem/state`.
- Payload (JSON), a cada 5 segundos:

```json
{"sensor": "temp_garagem", "valor": 26.78, "unidade": "C"}
```

## Pré-requisitos

- Docker e Docker Compose v2 (comando `docker compose`)
- Portas livres no notebook: `8123/tcp`, `1883/tcp` e `10000/udp` (veja [Solução de problemas](#solução-de-problemas) se alguma estiver ocupada)

## Estrutura de arquivos

```
projeto-iot-mqtt/
├── compose.yaml
├── mosquitto/
│   └── config/
│       └── mosquitto.conf
├── mqtt-sn-gateway/
│   └── gateway.conf        
├── subscriber/
│   ├── Dockerfile
│   └── subscriber.py
└── publisher_sn/
    ├── Dockerfile
    └── publisher_sn.py
```

## Ordem de execução (resumo)

1. Criar a estrutura de pastas e o `mosquitto.conf` (Passo 1).
2. Gerar o `gateway.conf` apontando para o Mosquitto (Passo 2).
3. Criar os arquivos do subscriber (Passo 3) e do publisher (Passo 4).
4. Criar o `compose.yaml` (Passo 5).
5. Subir tudo com `docker compose up -d --build` e conferir com `docker compose ps` (Passo 6).
6. Validar na ordem: gateway → publisher → Mosquitto (`mosquitto_sub`) → subscriber → Home Assistant (Passo 7).

## Passo 1 – Broker Mosquitto

Nas versões mais recentes do **Eclipse Mosquitto (2.x)**, a escuta externa e o acesso anônimo vêm **desativados por padrão**. É preciso declarar essas diretrizes explicitamente.

Crie `mosquitto/config/mosquitto.conf`:

```conf
# Escuta na porta padrao MQTT TCP 1883
listener 1883

# Permite conexoes sem autenticacao (para ambiente de teste/laboratorio)
allow_anonymous true

# Persistencia de mensagens
persistence true
persistence_location /mosquitto/data/

# Logs do broker
log_dest stdout
log_dest file /mosquitto/log/mosquitto.log
```

> `allow_anonymous true` é adequado apenas para laboratório. Em produção, configure autenticação e TLS.

## Passo 2 – Gateway MQTT-SN

A imagem `kyberpunk/paho:udp` empacota o gateway do Eclipse Paho. Os argumentos `--broker-name` e `--broker-port` **não funcionam** quando o contêiner roda sem permissão de escrita em `/etc/paho` (o script de entrada usa `sed` para alterar o arquivo e falha com `Permission denied`). O gateway então sobe apontando para um broker público. A solução é montar um `gateway.conf` já configurado.

Na raiz do projeto, extraia a configuração padrão da própria imagem e aponte para o Mosquitto:

```bash
mkdir -p mqtt-sn-gateway
docker run --rm --entrypoint cat kyberpunk/paho:udp /etc/paho/gateway.conf > mqtt-sn-gateway/gateway.conf

sed -i 's/^BrokerName=.*/BrokerName=mosquitto/; s/^BrokerPortNo=.*/BrokerPortNo=1883/' mqtt-sn-gateway/gateway.conf

grep -E '^(BrokerName|BrokerPortNo|GatewayPortNo)' mqtt-sn-gateway/gateway.conf
```

A saída esperada do `grep` é:

```
BrokerName=mosquitto
BrokerPortNo=1883
GatewayPortNo=10000
```

## Passo 3 – Subscriber MQTT

Usa **Python 3.12** e `paho-mqtt` 2.x para assinar tópicos hierárquicos com o coringa `#`.

**`subscriber/subscriber.py`**

```python
import time
import paho.mqtt.client as mqtt

BROKER_HOST = "mosquitto"
BROKER_PORT = 1883
TOPIC = "homeassistant/sensor/#"  # Assina todos os subtópicos usando o coringa '#'

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"[SUBSCRIBER MQTT] Conectado com sucesso ao Broker Mosquitto na porta {BROKER_PORT}!")
        client.subscribe(TOPIC)
        print(f"[SUBSCRIBER MQTT] Inscrito no tópico: '{TOPIC}'")
    else:
        print(f"[SUBSCRIBER MQTT] Falha na conexão. Código de retorno: {rc}")

def on_message(client, userdata, msg):
    payload_str = msg.payload.decode('utf-8')
    print(f"[SUBSCRIBER MQTT - MENSAGEM RECEBIDA] Tópico: '{msg.topic}' | Conteúdo: {payload_str}")

# Utiliza a API v2 atualizada da biblioteca paho-mqtt
client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="Python_MQTT_Subscriber")
client.on_connect = on_connect
client.on_message = on_message

print("[SUBSCRIBER MQTT] Aguardando inicialização do Broker Mosquitto...")
time.sleep(3)

client.connect(BROKER_HOST, BROKER_PORT, 60)
client.loop_forever()
```

**`subscriber/Dockerfile`**

```dockerfile
FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir paho-mqtt

COPY subscriber.py .

# Sem isso, o print do Python fica em buffer e os logs do contêiner aparecem vazios
ENV PYTHONUNBUFFERED=1

CMD ["python", "subscriber.py"]
```

## Passo 4 – Publisher MQTT-SN

Envia pacotes MQTT-SN via UDP ao gateway, executando o fluxo completo (`CONNECT`, `REGISTER`, `PUBLISH` QoS 1 com `PUBACK`). Se o gateway não responder, o publisher reconecta sozinho.

**`publisher_sn/publisher_sn.py`**

```python
import json
import random
import socket
import struct
import time

GATEWAY_HOST = "mqtt-sn-gateway"
GATEWAY_PORT = 10000
CLIENT_ID = "publisher_sn_01"
TOPIC_NAME = "homeassistant/sensor/temp_garagem/state"
KEEPALIVE = 60

CONNECT, CONNACK = 0x04, 0x05
REGISTER, REGACK = 0x0A, 0x0B
PUBLISH, PUBACK = 0x0C, 0x0D


def pkt(msg_type, body):
    return bytes([len(body) + 2, msg_type]) + body


def wait_for(sock, msg_type, timeout=5):
    """Espera um pacote do tipo pedido; ignora os demais."""
    deadline = time.time() + timeout
    while True:
        remaining = deadline - time.time()
        if remaining <= 0:
            raise socket.timeout(f"sem resposta 0x{msg_type:02X}")
        sock.settimeout(remaining)
        data, _ = sock.recvfrom(1024)
        if len(data) >= 2 and data[1] == msg_type:
            return data


def open_session(sock, addr):
    # CONNECT: Flags(CleanSession=0x04) | ProtocolId(0x01) | Duration | ClientId
    body = bytes([0x04, 0x01]) + struct.pack("!H", KEEPALIVE) + CLIENT_ID.encode()
    sock.sendto(pkt(CONNECT, body), addr)
    connack = wait_for(sock, CONNACK)
    if connack[2] != 0x00:
        raise RuntimeError(f"CONNACK rejeitado (rc={connack[2]})")
    print("[PUBLISHER MQTT-SN] CONNACK recebido: sessão aberta")

    # REGISTER: TopicId(0, quem define é o gateway) | MsgId | TopicName
    body = struct.pack("!HH", 0, 1) + TOPIC_NAME.encode()
    sock.sendto(pkt(REGISTER, body), addr)
    regack = wait_for(sock, REGACK)
    topic_id, _, rc = struct.unpack("!HHB", regack[2:7])
    if rc != 0x00:
        raise RuntimeError(f"REGACK rejeitado (rc={rc})")
    print(f"[PUBLISHER MQTT-SN] Tópico '{TOPIC_NAME}' registrado com TopicId={topic_id}")
    return topic_id


def main():
    msg_id = 1
    while True:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            addr = (socket.gethostbyname(GATEWAY_HOST), GATEWAY_PORT)
            print(f"[PUBLISHER MQTT-SN] Conectando ao gateway {addr}...")
            topic_id = open_session(sock, addr)

            while True:
                temperatura = round(random.uniform(20.0, 32.0), 2)
                payload = {"sensor": "temp_garagem", "valor": temperatura, "unidade": "C"}
                msg_id = msg_id % 65535 + 1  # MsgId nunca é 0

                # PUBLISH: Flags(QoS1=0x20) | TopicId | MsgId | Data
                body = bytes([0x20]) + struct.pack("!HH", topic_id, msg_id) \
                    + json.dumps(payload).encode("utf-8")
                sock.sendto(pkt(PUBLISH, body), addr)
                wait_for(sock, PUBACK, timeout=3)
                print(f"[PUBLISHER MQTT-SN] Publicado (PUBACK ok): {payload}")
                time.sleep(5)
        except (socket.timeout, socket.gaierror, OSError, RuntimeError) as e:
            print(f"[PUBLISHER MQTT-SN] Erro: {e}. Nova tentativa em 5s...")
            time.sleep(5)
        finally:
            sock.close()


if __name__ == "__main__":
    main()
```

**`publisher_sn/Dockerfile`**

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY publisher_sn.py .

ENV PYTHONUNBUFFERED=1

CMD ["python", "publisher_sn.py"]
```

## Passo 5 – Docker Compose

Na raiz do projeto, crie o **`compose.yaml`**:

```yaml
name: ambiente-experimental-iot

services:
  # 1. Home Assistant Core (versão estável mais recente)
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    environment:
      - TZ=America/Sao_Paulo
    volumes:
      - ha-config:/config
    ports:
      - "8123:8123"
    restart: unless-stopped

  # 2. Broker Mosquitto MQTT (2.x)
  mosquitto:
    image: eclipse-mosquitto:latest
    container_name: mosquitto
    ports:
      - "1883:1883"
    volumes:
      - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
    restart: unless-stopped

  # 3. Gateway MQTT-SN (Eclipse Paho: UDP -> TCP/Mosquitto)
  mqtt-sn-gateway:
    image: kyberpunk/paho:udp
    container_name: mqtt-sn-gateway
    volumes:
      - ./mqtt-sn-gateway/gateway.conf:/etc/paho/gateway.conf:ro
    ports:
      - "10000:10000/udp"
    depends_on:
      - mosquitto
    restart: unless-stopped

  # 4. Subscriber MQTT (Python 3.12 + paho-mqtt)
  subscriber-mqtt:
    build:
      context: ./subscriber
      dockerfile: Dockerfile
    container_name: subscriber-mqtt
    depends_on:
      - mosquitto
    restart: unless-stopped

  # 5. Publisher MQTT-SN (Python 3.12 + UDP Socket)
  publisher-mqtt-sn:
    build:
      context: ./publisher_sn
      dockerfile: Dockerfile
    container_name: publisher-mqtt-sn
    depends_on:
      - mqtt-sn-gateway
    restart: unless-stopped

volumes:
  ha-config:
```

## Passo 6 – Subir o ambiente

```bash
docker compose up -d --build
docker compose ps
```

Os 5 contêineres devem aparecer como `running`.

> O `sed` do script de entrada do gateway pode registrar `Permission denied` nos logs por causa do arquivo somente leitura. É inofensivo: o que importa é a linha `Broker : mosquitto : 1883` no banner.

## Passo 7 – Visualizar as métricas

Valide na ordem abaixo, seguindo o caminho do dado: publisher → gateway → broker → subscriber → Home Assistant.

### 7.1 Publisher: o sensor está enviando

```bash
docker compose logs -f publisher-mqtt-sn
```

Esperado:

```
[PUBLISHER MQTT-SN] CONNACK recebido: sessão aberta
[PUBLISHER MQTT-SN] Tópico 'homeassistant/sensor/temp_garagem/state' registrado com TopicId=1
[PUBLISHER MQTT-SN] Publicado (PUBACK ok): {'sensor': 'temp_garagem', 'valor': 26.78, 'unidade': 'C'}
```

### 7.2 Gateway: a conversão MQTT-SN → MQTT está ocorrendo

```bash
docker compose logs -f mqtt-sn-gateway
```

Procure o banner com `Broker : mosquitto : 1883` e, em seguida, a sequência `CONNECT` → `CONNACK`, `REGISTER` → `REGACK` e `PUBLISH` → `PUBACK`. As setas `<---` e `--->` indicam o lado MQTT-SN, e `===>` e `<===`, o lado MQTT (broker).

### 7.3 Broker: as mensagens chegaram ao Mosquitto

```bash
docker compose exec mosquitto mosquitto_sub -t 'homeassistant/sensor/#' -v
```

A cada 5 segundos aparece uma linha:

```
homeassistant/sensor/temp_garagem/state {"sensor": "temp_garagem", "valor": 28.43, "unidade": "C"}
```

Para ver os logs internos do broker (conexões e assinaturas):

```bash
docker compose logs -f mosquitto
```

### 7.4 Subscriber: o consumidor está recebendo

```bash
docker compose logs -f subscriber-mqtt
```

Esperado:

```
[SUBSCRIBER MQTT] Conectado com sucesso ao Broker Mosquitto na porta 1883!
[SUBSCRIBER MQTT] Inscrito no tópico: 'homeassistant/sensor/#'
[SUBSCRIBER MQTT - MENSAGEM RECEBIDA] Tópico: 'homeassistant/sensor/temp_garagem/state' | Conteúdo: {"sensor": "temp_garagem", ...}
```

Para acompanhar os três serviços ao mesmo tempo:

```bash
docker compose logs -f publisher-mqtt-sn mqtt-sn-gateway subscriber-mqtt
```

### 7.5 Home Assistant: ver a métrica como sensor

**a) Configurar a integração MQTT**

1. Acesse `http://localhost:8123` e conclua o cadastro inicial do administrador.
2. Vá em **Configurações > Dispositivos e Serviços > Adicionar Integração** e escolha **MQTT**.
3. Em **Servidor**, digite `mosquitto`; em **Porta**, `1883`.

**b) Ver as mensagens cruas**

Em **Ferramentas de Desenvolvedor > MQTT**, na seção *Ouvir um tópico*, digite `homeassistant/sensor/#` e clique em **Começar a ouvir**. As mensagens do publisher aparecem em tempo real.

**c) Criar o sensor de temperatura (MQTT Discovery)**

O Home Assistant monitora o prefixo `homeassistant/` para descoberta automática de entidades. Publique (uma única vez) a configuração do sensor, com a flag `-r` (*retain*) para ela persistir no broker:

```bash
docker compose exec mosquitto mosquitto_pub -r \
  -t 'homeassistant/sensor/temp_garagem/config' \
  -m '{"name":"Temperatura Garagem","unique_id":"temp_garagem_01","state_topic":"homeassistant/sensor/temp_garagem/state","value_template":"{{ value_json.valor }}","unit_of_measurement":"°C","device_class":"temperature"}'
```

Depois, em **Configurações > Dispositivos e Serviços > MQTT**, aparece a entidade **Temperatura Garagem** (`sensor.temperatura_garagem`), cujo valor atualiza a cada 5 segundos.

**d) Mostrar no painel**

Em **Visão geral > Editar painel > Adicionar cartão**, escolha **Gráfico de histórico** (ou **Medidor**) e selecione `sensor.temperatura_garagem`. O histórico também fica disponível em **Histórico** no menu lateral.

> A configuração via Discovery (item c) usa o formato padrão do Home Assistant. Se a entidade não aparecer, confira se a integração MQTT está conectada ao `mosquitto:1883` e veja a mensagem em *Ferramentas de Desenvolvedor > MQTT*.

## Solução de problemas

| Sintoma                                                               | Causa provável                                                       | Solução                                                                                                                                                                    |
| --------------------------------------------------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pull access denied for mainflux/mqtt-sn`                           | A imagem não existe                                                  | Usar `kyberpunk/paho:udp` (Passo 5)                                                                                                                                        |
| `failed to bind host port 0.0.0.0:1883/tcp: address already in use` | Outro processo usa a 1883 (Mosquitto do sistema ou contêiner antigo) | `sudo ss -ltnp 'sport = :1883'` para achar o processo; `sudo systemctl stop mosquitto` ou `docker rm -f <container>`; ou mude para `"1885:1883"` no `compose.yaml` |
| Gateway com `Broker : mqtt.eclipseprojects.io` no banner            | `gateway.conf` não foi montado ou não foi editado                 | Refazer o Passo 2 e conferir o volume no `compose.yaml`                                                                                                                    |
| Gateway recebe `CONNECT` repetido e nunca responde                  | O gateway não alcança o broker                                      | Conferir `BrokerName=mosquitto` e se o contêiner `mosquitto` está rodando                                                                                              |
| Logs do publisher/subscriber vazios                                   | Buffer de saída do Python                                            | Adicionar `ENV PYTHONUNBUFFERED=1` nos Dockerfiles e rodar `docker compose up -d --build`                                                                                |
| Publisher em loop com "sem resposta 0x05"                             | Gateway fora do ar ou mal configurado                                 | `docker compose logs mqtt-sn-gateway`                                                                                                                                      |
| Mosquitto reiniciando em loop                                         | Falha ao gravar `/mosquitto/log/mosquitto.log`                      | Remover a linha `log_dest file ...` e deixar só `log_dest stdout`                                                                                                       |
| Entidade não aparece no Home Assistant                               | Integração MQTT não configurada ou Discovery não publicado        | Refazer 7.5 (a) e (c)                                                                                                                                                        |

## Encerrar o ambiente

```bash
docker compose down        # para e remove os contêineres
docker compose down -v     # também remove o volume ha-config (reinicia o Home Assistant do zero)
```
