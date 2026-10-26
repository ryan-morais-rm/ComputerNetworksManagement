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
    body = bytes([0x04, 0x01]) + struct.pack("!H", KEEPALIVE) + CLIENT_ID.encode()
    sock.sendto(pkt(CONNECT, body), addr)
    connack = wait_for(sock, CONNACK)
    if connack[2] != 0x00:
        raise RuntimeError(f"CONNACK rejeitado (rc={connack[2]})")
    print("[PUBLISHER MQTT-SN] CONNACK recebido: sessão aberta")

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