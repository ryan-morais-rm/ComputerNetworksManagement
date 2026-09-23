FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

RUN apt-get update && \     
    apt-get install -y x11-apps linphone

ENV DISPLAY=:0  

CMD ["linphone"]