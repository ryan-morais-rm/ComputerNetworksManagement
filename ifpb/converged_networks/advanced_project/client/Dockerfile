FROM node:20-slim

WORKDIR /app

COPY package.json .
RUN npm install --omit=dev

COPY benchmark.js .
COPY summarize.js .

# Mantém o container vivo para rodar os testes manualmente com "docker exec"
CMD ["tail", "-f", "/dev/null"]
