# Guia de Docker

Este guia cobre os comandos básicos do Docker: instalação, execução de containers, criação de imagens, volumes, redes e Docker Compose.

---

## 1. Instalar o Docker

Siga o passo a passo oficial de instalação do Docker no Ubuntu:
https://docs.docker.com/engine/install/ubuntu/

> A documentação oficial é a fonte mais confiável e atualizada — prefira-a a tutoriais de terceiros.

---

## 2. Baixar e executar uma imagem de teste

```bash
sudo docker run hello-world
```

Esse comando baixa a imagem `hello-world` (caso ainda não exista localmente) e cria e executa um container a partir dela.

---

## 3. Executar um container em segundo plano, com mapeamento de porta

```bash
sudo docker run -d -p 8080:80 dockersamples/static-site
```

- `-d` (*detached*): executa o container em segundo plano, sem prender o terminal.
- `-p 8080:80`: mapeia a porta 8080 do host para a porta 80 do container.

Acesse `http://localhost:8080` no navegador para verificar.

---

## 4. Baixar apenas a imagem, sem executar

```bash
sudo docker pull ubuntu
```

Esse comando baixa apenas a **imagem** `ubuntu` para o repositório local, sem criar ou executar nenhum container.

---

## 5. Listar containers em execução

```bash
sudo docker ps
```
ou
```bash
sudo docker container ls
```

Note que o container baixado (mas não executado) no passo 4 não aparece nessa lista, pois `docker pull` não cria containers.

---

## 6. Listar todos os containers (em execução ou parados)

```bash
sudo docker ps -a
```
ou
```bash
sudo docker container ls -a
```

Aqui o container `hello-world`, que já finalizou sua execução, aparece na lista.

---

## 7. Parar um container

```bash
sudo docker stop <ID_DO_CONTAINER>
```

Use o ID do container `dockersamples/static-site` criado no passo 3. Depois de parado, a página deixa de responder em `localhost:8080`.

---

## 8. Iniciar um container parado

```bash
sudo docker start <ID_DO_CONTAINER>
```

Use o mesmo ID do passo 7. A página volta a responder em `localhost:8080`.

---

## 9. Executar um shell dentro de um container em execução

```bash
sudo docker exec -it <ID_DO_CONTAINER> bash
```

Use o ID do container iniciado no passo 8.

---

## 10. Remover um container

```bash
sudo docker rm <ID_DO_CONTAINER>
```

Por exemplo, remova o container `hello-world` (ele precisa estar parado para ser removido, ou use `-f` para forçar).

---

## 11. Listar as imagens já baixadas

```bash
sudo docker images
```

---

## 12. Criar uma imagem própria

### 12.1. Preparar o projeto

Baixe e descompacte o arquivo de exemplo `app-exemplo.zip` (ajuste a URL/fonte conforme o material do seu curso) e entre no diretório do projeto:

```bash
cd /home/$USER/Downloads/app-exemplo/
```

### 12.2. Criar o `Dockerfile`

Crie um arquivo chamado `Dockerfile` (sem extensão) no diretório do projeto:

```dockerfile
# Servidor web usando Node.js
FROM node:14
WORKDIR /app-node
# Copia o conteúdo do diretório atual para /app-node
COPY . .
# Instala as dependências do Node
RUN npm install
# Comando de entrada para iniciar a aplicação
ENTRYPOINT ["npm", "start"]
```

### 12.3. Construir a imagem

```bash
sudo docker build -t rcon/app-node:1.0 .
```

Isso cria a imagem `rcon/app-node`, na versão `1.0`, usando o `Dockerfile` e os arquivos do diretório atual (`.`) como contexto de build.

### 12.4. Confirmar que a imagem foi criada

```bash
sudo docker images
```

### 12.5. Testar a imagem criada

```bash
sudo docker run -d -p 8082:3000 rcon/app-node:1.0
```

Acesse `http://localhost:8082` no navegador para verificar.

---

## 13. Usar variáveis de ambiente no Dockerfile

### 13.1. Ajustar o `index.js` para ler a porta de uma variável de ambiente

```javascript
const express = require('express')
let app = express();

app.use(express.static("."));

app.get("/", (req, res) => {
    res.sendFile(__dirname + '/index.html')
})

app.listen(process.env.PORT, () => {
    console.log("Servidor escutando na porta especificada na variável de ambiente")
})
```

### 13.2. Ajustar o `Dockerfile`

```dockerfile
# Servidor web usando Node.js
FROM node:14
WORKDIR /app-node
# Variável utilizada em tempo de construção da imagem
ARG PORT_BUILD=6000
# Variável disponível dentro do container em tempo de execução
ENV PORT=$PORT_BUILD
EXPOSE $PORT_BUILD
# Copia o conteúdo do diretório atual para /app-node
COPY . .
# Instala as dependências do Node
RUN npm install
# Comando de entrada para iniciar a aplicação
ENTRYPOINT ["npm", "start"]
```

### 13.3. Construir a nova versão da imagem

```bash
sudo docker build -t rcon/app-node:1.1 .
```

### 13.4. Testar a nova imagem

```bash
sudo docker run -d -p 9090:6000 rcon/app-node:1.1
```

Acesse `http://localhost:9090` no navegador para verificar.

---

## 14. Publicar uma imagem no Docker Hub

> Substitua `<seu-usuario-dockerhub>` pelo nome da sua conta no Docker Hub.

### 14.1. Adicionar seu usuário ao grupo `docker` (evita usar `sudo` nos comandos)

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 14.2. Autenticar no Docker Hub

```bash
docker login -u <seu-usuario-dockerhub>
```

### 14.3. Criar uma tag para a imagem, associando-a à sua conta

```bash
docker tag rcon/app-node:1.1 <seu-usuario-dockerhub>/app-node:1.1
```

### 14.4. Enviar (*push*) a imagem para o Docker Hub

```bash
docker push <seu-usuario-dockerhub>/app-node:1.1
```

---

## 15. Remover todas as imagens locais

```bash
docker rmi $(docker image ls -aq) --force
```

> Use com cuidado: esse comando remove **todas** as imagens do sistema, incluindo as que não pertencem a este exercício.

---

## 16. Usar um *bind mount* (vincular uma pasta do host a uma pasta do container)

```bash
cd /home/$USER/
mkdir volume-docker
docker run -it -v /home/$USER/volume-docker:/app ubuntu bash
cd /app
touch teste.txt
exit
ls /home/$USER/volume-docker
```

Forma equivalente, usando a sintaxe `--mount`:

```bash
docker run -it --mount type=bind,source=/home/$USER/volume-docker,target=/app ubuntu bash
```

O arquivo criado dentro do container (`/app/teste.txt`) também aparece na pasta do host (`/home/$USER/volume-docker`), pois ambas apontam para o mesmo local em disco.

---

## 17. Criar e usar um volume gerenciado pelo Docker

```bash
docker volume create meu-volume
docker volume ls
docker run -it -v meu-volume:/app ubuntu bash
cd /app
touch um-arq.txt
exit
sudo ls /var/lib/docker/volumes
sudo ls /var/lib/docker/volumes/meu-volume/_data
```

Forma equivalente, usando a sintaxe `--mount`:

```bash
docker run -it --mount source=meu-volume,target=/app ubuntu bash
cd /app
touch um-arq2.txt
exit

sudo ls /var/lib/docker/volumes
sudo ls /var/lib/docker/volumes/meu-volume/_data
```

Diferente do *bind mount*, um volume Docker é gerenciado pelo próprio Docker (armazenado em `/var/lib/docker/volumes`), e não por um caminho arbitrário do host.

---

## 18. Criar um volume em memória (`tmpfs`)

```bash
docker run -it --tmpfs=/app ubuntu bash
cd /app
touch arq.txt
exit
```

Forma equivalente, usando a sintaxe `--mount`:

```bash
docker run -it --mount type=tmpfs,destination=/app ubuntu bash
cd /app
```

> Diferente dos casos anteriores, dados em `tmpfs` existem apenas na memória RAM enquanto o container está em execução — ao encerrar o container, o conteúdo é perdido (não persiste em disco).

---

## 19. Redes do Docker

### 19.1. Listar as redes disponíveis

```bash
docker network ls
```

Tipos principais de rede:
- **none**: sem interface de rede.
- **host**: o container compartilha a mesma rede do host.
- **bridge**: rede isolada, própria do Docker (padrão).

---

## 20. Comunicação entre containers usando hostname

### 20.1. Criar uma rede bridge personalizada

```bash
docker network create --driver bridge minha-bridge
docker run -d --name pong --network minha-bridge ubuntu sleep 1d
docker run -it --name ubuntu1 --network minha-bridge ubuntu bash
apt update
apt-get install iputils-ping
```

### 20.2. Testar a comunicação usando o nome do container (hostname), sem precisar do IP

```bash
ping pong
```

Em outro terminal, é possível ver os dois containers (`ubuntu1` e `pong`) em execução:

```bash
docker ps
```

> Containers em uma mesma rede *bridge* personalizada conseguem se comunicar pelo nome do container, funcionando como um hostname interno — isso não acontece automaticamente na rede *bridge* padrão do Docker.

---

## 21. Abrir a página web de um container sem mapear portas

```bash
sudo docker run -d --network host dockersamples/static-site
```

Acesse `http://localhost:80` no navegador para verificar.

> O modo `--network host` faz o container usar diretamente a rede do host (sem isolamento de rede nem necessidade de `-p`). Esse modo funciona nativamente apenas em Linux.

---

## 22. Instalar o Docker Compose

Nas versões atuais do Docker, o Compose já vem incluído como plugin, acessível pelo comando `docker compose` (sem hífen). Para verificar se já está disponível:

```bash
docker compose version
```

Caso não esteja disponível e seja necessário instalar manualmente a versão standalone (`docker-compose`, com hífen):

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

> Prefira sempre a versão mais recente disponível na página oficial de releases: https://github.com/docker/compose/releases

---

## 23. Exemplo de `docker-compose.yaml`

```bash
mkdir -p volume-docker/yamls
cd volume-docker/yamls
```

Crie um arquivo chamado `docker-compose.yaml` com o seguinte conteúdo:

```yaml
version: "3.9"

services:
  mongo:
    image: mongo:4.4.6
    container_name: meu_mongo
    networks:
      - compose-bridge

  rcon-books:
    image: rcondocker-books:1.0
    container_name: rconbooks
    networks:
      - compose-bridge
    ports:
      - "3000:3000"
    depends_on:
      - mongo

networks:
  compose-bridge:
    driver: bridge
```

Para subir os containers definidos no arquivo:

```bash
docker compose up -d
```

---

## 24. Comandos básicos do Docker Compose

Com o arquivo `docker-compose.yaml` do passo 23 no diretório atual:

```bash
# Sobe os serviços em segundo plano
docker compose up -d

# Lista os containers gerenciados por este docker-compose.yaml
docker compose ps

# Encerra e remove os containers, redes e volumes criados
docker compose down
```

> Correções em relação à versão original deste exemplo: os nomes dos serviços (`mongo`, `rcon-books`) precisam estar declarados corretamente sob `services:`; a imagem deve ser escrita como `mongo:4.4.6` (sem espaço após os dois-pontos); e o comando correto é `docker compose up` (ou `docker-compose up` na versão standalone), nunca `docker-compose-up`.

---

## Resumo de correções feitas em relação ao material original

- **Terminologia**: `docker pull` baixa uma **imagem**, não um "container". Um container só existe depois que uma imagem é executada com `docker run`.
- **Português**: correções de concordância, acentuação e clareza nas instruções (ex.: "ambient" → "ambiente", "docker in" → "no docker", frases sem verbo, etc.).
- **Credenciais**: o usuário do Docker Hub usado como exemplo foi substituído por `<seu-usuario-dockerhub>`, um placeholder genérico.
- **Comentários incorretos no Dockerfile**: o comentário mencionava "node e ubuntu", mas o Dockerfile usa apenas a imagem base `node`.
- **Numeração**: havia dois passos "17" no material original; a numeração foi corrigida e sequencial.
- **YAML do Docker Compose**: corrigida a sintaxe (`image: mongo: 4.4.6` → `image: mongo:4.4.6`), aspas tipográficas (`”3.9”`) trocadas por aspas retas (`"3.9"`), e a estrutura de serviços do segundo exemplo (que estava sem os nomes dos serviços corretamente indentados) foi corrigida.
- **Comandos do Compose**: `docker-compose-up`, `docker-compose-up ps` e `docker-compose-up down` (inválidos) foram corrigidos para `docker compose up`, `docker compose ps` e `docker compose down`.
- **Fonte de imagem removida**: o link de busca de imagem do Google foi removido por não ser uma fonte de documentação confiável.
