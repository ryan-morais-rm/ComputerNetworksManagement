FROM node:20-slim

WORKDIR /app

COPY package.json .
RUN npm install --omit=dev

COPY index.js .

# Gera um certificado autoassinado para os testes com TLS (HTTPS / WSS)
RUN apt-get update && apt-get install -y openssl --no-install-recommends && \
    mkdir -p certs && \
    openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout certs/key.pem -out certs/cert.pem -days 3650 \
      -subj "/CN=wsbench-server" && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 3000 3443

CMD ["node", "index.js"]
