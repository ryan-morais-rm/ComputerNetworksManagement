# Tutorial: Automação de um Container Nginx com Ansible e Docker

Este tutorial apresenta o processo de criação e execução de um playbook Ansible para validar o ambiente Docker, baixar a imagem do Nginx, criar e iniciar um container e validar seu funcionamento.

## 1. Instalar a coleção Docker para Ansible

Antes de executar o playbook, instale a coleção `community.docker` no nó de controle. Essa coleção fornece os módulos necessários para gerenciar imagens e containers Docker.

```bash
ansible-galaxy collection install community.docker
```

## 2. Criar o inventário local

Crie um arquivo chamado `hosts.ini` e defina a máquina local como alvo da execução:

```ini
[local]
localhost ansible_connection=local
```

## 3. Criar o Playbook Ansible

Crie um arquivo chamado `deploy_nginx.yml`. O playbook será responsável por validar a instalação do Docker, baixar a imagem do Nginx, criar o container e verificar se ele está em execução.

```yaml
---
- name: Automação do container Nginx com Docker
  hosts: local
  gather_facts: false

  tasks:
    - name: 1. Checar instalação do Docker
      ansible.builtin.command: docker --version
      register: docker_check
      changed_when: false
      failed_when: false

    - name: Interromper se o Docker não for encontrado
      ansible.builtin.fail:
        msg: "O binário do Docker não está instalado ou acessível nesta máquina."
      when: docker_check.rc != 0

    - name: 2. Baixar a imagem nginx:latest
      community.docker.docker_image:
        name: nginx
        tag: latest
        source: pull

    - name: 3, 4 e 5. Criar e iniciar o container web01 (Porta 8080:80)
      community.docker.docker_container:
        name: web01
        image: nginx:latest
        state: started
        restart_policy: always
        published_ports:
          - "8080:80"

    - name: 6. Coletar informações do container web01
      community.docker.docker_container_info:
        name: web01
      register: web01_status

    - name: Validar se o container está rodando
      ansible.builtin.assert:
        that:
          - web01_status.exists
          - web01_status.container.State.Running
        success_msg: "O container web01 está rodando com sucesso na porta 8080!"
        fail_msg: "O container web01 não está em execução."
```

### Estrutura dos arquivos

Ao final, o diretório deverá possuir a seguinte estrutura:

```text
.
├── deploy_nginx.yml
└── hosts.ini
```

## 4. Executar o Playbook

Execute o playbook utilizando o inventário criado anteriormente:

```bash
ansible-playbook -i hosts.ini deploy_nginx.yml
```

Durante a execução, o Ansible irá:

1. Verificar se o Docker está instalado e acessível.
2. Baixar a imagem `nginx:latest`.
3. Criar o container `web01`.
4. Iniciar o container.
5. Configurar a porta `8080` do host para a porta `80` do container.
6. Verificar se o container está em execução.

## 5. Validar a aplicação

Após a execução do playbook, teste a resposta HTTP do Nginx utilizando `curl`:

```bash
curl -I http://localhost:8080
```

Se o Nginx estiver funcionando corretamente, o comando deverá retornar uma resposta HTTP, como:

```text
HTTP/1.1 200 OK
```

Isso confirma que o container `web01` está em execução e que o Nginx está acessível através da porta `8080` do host.
