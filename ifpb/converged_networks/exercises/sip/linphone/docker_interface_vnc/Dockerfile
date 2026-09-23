FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

RUN apt-get update && apt-get install -y \
    linphone \
    fluxbox \
    xvfb \
    x11vnc \
    net-tools \
    xterm \
    dbus-x11 \
    && mkdir -p /root/.fluxbox \
    && echo "fluxbox-init" > /root/.fluxbox/init \
    && echo "fluxbox-menu" > /root/.fluxbox/menu \
    && apt-get clean

ENV DISPLAY=:0

CMD ["bash", "-c", "Xvfb :0 -screen 0 1024x768x16 & sleep 3 && fluxbox & x11vnc -forever -passwd senha123 -display :0 & linphone"]
