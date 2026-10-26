mkdir -p mqtt-sn-gateway

docker run --rm --entrypoint cat kyberpunk/paho:udp /etc/paho/gateway.conf > mqtt-sn-gateway/gateway.conf

sed -i 's/^BrokerName=.*/BrokerName=mosquitto/; s/^BrokerPortNo=.*/BrokerPortNo=1883/' mqtt-sn-gateway/gateway.conf

grep -E '^(BrokerName|BrokerPortNo|GatewayPortNo)' mqtt-sn-gateway/gateway.conf