# 7.1) Sensor virtual publicando temperatura aleatória a cada 5s.
import paho.mqtt.client as mqtt
from random import randint
from time import sleep

AREA_ID = 10
SENSOR_ID = 6000  # usar SENSOR_ID = 5000 para sv_5000.py.

tt = "area/%d/sensor/%s/temperatura" % (AREA_ID, SENSOR_ID)

# Scripts abaixo já usam mqtt.CallbackAPIVersion.VERSION1.
client = mqtt.Client(
    mqtt.CallbackAPIVersion.VERSION1,
    client_id='NODE:%d-%d' % (AREA_ID, SENSOR_ID),
    protocol=mqtt.MQTTv31,
)

client.connect("127.0.0.1", 1883)

while True:
    t = randint(0, 50)
    msg = str(t)
    client.publish(tt, msg, qos=0)
    print(tt + "/" + str(t))
    sleep(5)
