#!/bin/bash

set -e

IMAGE_NAME="linphone"
CONTAINER_NAME="linphone"

echo "Construindo a imagem Docker ($IMAGE_NAME)..."
docker build -t $IMAGE_NAME .

echo "Liberando permissão do servidor gráfico (X11)..."
xhost +local: > /dev/null

trap "echo -e '\n Revogando permissão do servidor gráfico...'; xhost -local: > /dev/null" EXIT

echo "Iniciando o container da interface gráfica..."
docker run -it --rm --name $CONTAINER_NAME \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/.Xauthority:/root/.Xauthority:rw \
  -e XAUTHORITY=/root/.Xauthority \
  --network host \
  $IMAGE_NAME