FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

ENV QT_X11_NO_MITSHM=1

RUN apt-get update && apt-get install -y \
    linphone \
    sngrep \
    libcanberra-gtk-module \
    libcanberra-gtk3-module \
    libatk-adaptor \
    at-spi2-core \
    dbus-x11 \
    libpulse0 \
    alsa-utils \
    && rm -rf /var/lib/apt/lists/* # Apaga o cache do apt para deixar a imagem mais leve

CMD ["linphone"]