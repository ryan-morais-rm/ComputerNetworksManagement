#!/bin/bash

set -e

IMAGE_NAME="linphone-vnc"
CONTAINER_NAME="linphone-vnc-app"

echo "1. Verificando dependências..."
if ! command -v vncviewer &> /dev/null; then
    echo "TigerVNC Viewer não encontrado. Instalando..."
    sudo apt update -qq
    sudo apt install -y tigervnc-viewer
else
    echo "TigerVNC Viewer já está instalado."
fi

echo "2. Construindo a imagem Docker ($IMAGE_NAME)..."
docker build -t $IMAGE_NAME .

echo "3. Iniciando o container em segundo plano..."
docker run -d --rm --name $CONTAINER_NAME -p 5900:5900 $IMAGE_NAME

trap "echo -e '\nEncerrando e limpando o container...'; docker stop $CONTAINER_NAME > /dev/null" EXIT

echo "Aguardando o servidor VNC iniciar internamente..."
sleep 3 # Dá tempo para o processo VNC subir dentro do container antes de tentar conectar

echo "4. Abrindo a interface gráfica via VNC..."
vncviewer localhost:5900