# Criar um código Server.py que abre uma conexão serial.
import queue
import select
import socket
import time
import serial

ser = serial.Serial()
ser.port = '/dev/ttyACM0'
ser.baudrate = 9600
# ser.open() # Descomente quando o Arduino estiver conectado fisicamente

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setblocking(0)
server.bind(('localhost', 50000))
server.listen(5)
