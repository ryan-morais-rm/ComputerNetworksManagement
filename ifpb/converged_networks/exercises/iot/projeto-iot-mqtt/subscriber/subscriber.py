import time
import paho.mqtt.client as mqtt 

BROKER_HOST = "mosquitto"
BROKER_PORT = 1883
TOPIC = "homeassistant/sensor/#"

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"[SUBSCRIBER MQTT] Conectado com sucesso ao Broker na porta {BROKER_PORT}!")
        client.subscribe(TOPIC)
        print(f"[SUBSCRIBER MQTT] Inscrito no tópico: '{TOPIC}")
    else:
        print(f"[SUBSCRIBER MQTT] Falha na conexão. Código de retorno: {rc}")

def on_message(client, userdata, msg):
    payload_str = msg.payload.decode('utf-8')
    print(f"[SUBSCRIBER MQTT - MENSAGEM RECEBIDA] Tópico: '{msg.topic}' | Conteúdo: {payload_str}")

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="Python_MQTT_Subscriber")
client.on_connect = on_connect
client.on_message = on_message 

print("[SUBSCRIBER MQTT] Aguardando inicialização do Broker Mosquitto...")
time.sleep(3)
client.connect(BROKER_HOST, BROKER_PORT, 60)
client.loop_forever()