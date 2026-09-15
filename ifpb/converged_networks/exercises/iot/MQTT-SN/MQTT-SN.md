# MQTT-SN

Teoria: <https://embarcados.com.br/mqtt-sn-mqtt-para-rede-de-sensores/>

## 1) Instalar e testar Broker

Primeiro você deve configurar o ambiente de forma que o MQTT esteja
funcionando: executar em um terminal um teste de inscrição no tópico
`/teste` e em outro terminal um teste para publicar no tópico `/teste`.

```
nc -zv 127.0.0.1 1883
```

## 2) Instalar ferramentas básicas para programação

```
sudo apt install build-essential
sudo apt install cmake
sudo apt-get install libssl-dev
```

## 3) Compilar e configurar o gateway MQTT-SN

```
git clone https://github.com/eclipse-paho/paho.mqtt-sn.embedded-c.git
cd paho.mqtt-sn.embedded-c/MQTTSNGateway

./build.sh udp
cd bin/
sudo ./MQTT-SNGateway

cat gateway.conf
nano gateway.conf
```

Como deve estar o arquivo de configuração do `gateway.conf`:

```
#**************************************************************************
# Copyright (c) 2016-2021, Tomoaki Yamaguchi
#
# config file of MQTT-SN Gateway
#

GatewayID=1
GatewayName=PahoGateway-01
MaxNumberOfClients=30
KeepAlive=60
#LoginID=your_ID
#Password=your_Password

#luciana BrokerName=mqtt.eclipseprojects.io
BrokerPortNo=1883
BrokerSecurePortNo=8883

#
# CertsKey for TLS connections to a broker
#

#RootCAfile=/etc/ssl/certs/ca-certificates.crt
#RootCApath=/etc/ssl/certs/
#CertKey=/path/to/certKey.pem
#PrivateKey=/path/to/privateKey.pem

#
# When AggregatingGateway=YES or ClientAuthentication=YES,
# All clients must be specified by the ClientList File
#

AggregatingGateway=NO
QoS-1=NO
Forwarder=NO
PredefinedTopic=NO
ClientAuthentication=NO

ClientsList=/path/to/your_clients.conf
PredefinedTopicList=/path/to/your_predefinedTopic.conf


#==============================
#  SensorNetworks parameters
#==============================
#
# UDP | DTLS
#

GatewayPortNo=10000
#luciana MulticastPortNo=1883
MulticastPortNo=1884
MulticastIP=225.1.1.1
MulticastTTL=1

#
# UDP6 | DTLS6
#

GatewayIPv6PortNo=10000
#luciana MulticastIPv6PortNo=1883
MulticastIPv6PortNo=1886
MulticastIPv6=ff1e:feed:caca:dead::1
MulticastIPv6If=wlp4s0
MulticastHops=1

#
# DTLS | DTLS6
#

DtlsCertsKey=/etc/ssl/certs/gateway.pem
DtlsPrivKey=/etc/ssl/private/privkey.pem

#
# XBee
#

Baudrate=38400
SerialDevice=/dev/ttyUSB0
ApiMode=2

#
# LoRaLink
#

BaudrateLoRaLink=115200
DeviceRxLoRaLink=/dev/loralinkRx
DeviceTxLoRaLink=/dev/loralinkTx

#
# Bluetooth RFCOMM
#

RFCOMMAddress=60:57:18:06:8B:72.*

#
# LOG
#

ShearedMemory=NO
```

## 4) Baixar e compilar o código para MQTT-SN

```
git clone https://github.com/njh/mqtt-sn-tools.git
cd mqtt-sn-tools/
make
```

## 5) Testar se o gateway está escutando UDP na porta 10000

```
nc -zv -u 127.0.0.1 10000
```

## 6) Executar o mqtt-sn para publicar no tópico /teste

```
./mqtt-sn-pub -h 127.0.0.1 -t "/teste" -m testmqtt-sn -p 10000
```