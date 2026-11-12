# Automação de Rede com Netmiko e SNMP

Prática da disciplina **Gerenciamento de Redes de Computadores** (IFPB, Campus João Pessoa, Prof. Ruan Delgado Gomes). O projeto automatiza, via **SSH (Netmiko)** e **SNMP (pysnmp)**, a configuração e o monitoramento de uma topologia emulada no **GNS3 ou PNETLab**.

---

## Sumário

1. [Visão geral](#1-visão-geral)
2. [Topologia](#2-topologia)
3. [Estrutura do projeto](#3-estrutura-do-projeto)
4. [Pré-requisitos](#4-pré-requisitos)
5. [Preparando o laboratório](#5-preparando-o-laboratório)
6. [Configurando o inventário](#6-configurando-o-inventário)
7. [Quando e como executar cada script](#7-quando-e-como-executar-cada-script)
8. [Solução de problemas](#8-solução-de-problemas)
9. [Observações](#9-observações)

---

## 1. Visão geral

O projeto resolve duas tarefas do roteiro:

| Tarefa    | Script              | Ferramenta       | O que faz                                                                                        |
| --------- | ------------------- | ---------------- | ------------------------------------------------------------------------------------------------ |
| Seção 4 | `vlans.py`        | Netmiko (SSH)    | Cria as VLANs 2, 3 e 4 nos switches, mostra o `show vlan brief` e salva a configuração.      |
| Seção 5 | `snmp_octetos.py` | Netmiko + pysnmp | Habilita o SNMP nos roteadores e consulta, a cada 10 s, os octetos de entrada e saída da Gi0/0. |

Netmiko é uma biblioteca que abstrai os comandos repetitivos de acesso ao equipamento (`enable`, `conf t`, `end`). Com ele, os scripts enviam apenas os comandos que interessam, sobre SSH, uma alternativa mais segura que o Telnet.

---

## 2. Topologia

A topologia segue a figura do roteiro:

- **Roteadores:** R1, R2 e R3, interligados entre si e ao SW1.
- **Switches:** SW1 (núcleo, ligado ao Cloud1) e SW2, SW3 e SW4 (acesso, cada um com um PC VPCS).
- **Cloud1:** liga a topologia à rede externa pela interface `eth0`, conectada ao SW1 (Gi3/3).

IPs de gerência usados nos scripts:

| Dispositivo | IP                           | Origem                 |
| ----------- | ---------------------------- | ---------------------- |
| R1          | `192.168.1.101`            | exemplos do roteiro    |
| R2          | `192.168.2.102`            | exemplos do roteiro    |
| R3          | `192.168.3.103`            | exemplos do roteiro    |
| SW1 a SW4   | `192.168.1.201` a `.204` | **placeholders** |

---

## 3. Estrutura do projeto

```text
netmiko/
├── README.md             # este arquivo
├── requirements.txt      # netmiko e pysnmp
├── dispositivos.py       # inventário: IPs, usuário e senha (compartilhado)
├── vlans.py              # seção 4: criação de VLANs nos switches
└── snmp_octetos.py       # seção 5: habilita SNMP e monitora octetos
```

- **`dispositivos.py`** guarda os dicionários `ROTEADORES` e `SWITCHES` no formato do `ConnectHandler` (`device_type`, `host`, `username`, `password`). Os dois scripts o importam, então **execute-os sempre de dentro da pasta `netmiko/`**.
- **`vlans.py`** monta uma lista de objetos `ConnectHandler` (um por switch) e uma lista de tuplas `(id, nome)` com as VLANs.
- **`snmp_octetos.py`** usa uma lista de roteadores e uma lista paralela de *community strings* (`ifpb-r1`, `ifpb-r2`, `ifpb-r3`).

---

## 4. Pré-requisitos

### Máquina que executa os scripts

- Python **3.9 ou superior**.
- Alcance IP até os dispositivos (veja a [seção 5.1](#51-conectividade-entre-a-máquina-de-scripts-e-o-laboratório)).

Instalação recomendada, em ambiente virtual:

```bash
cd netmiko
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

> O `pysnmp` instalado é a versão 7 ou superior, que usa a API **assíncrona** (`asyncio`). O exemplo do roteiro usa a API síncrona antiga (`getCmd`), por isso o código foi escrito para a versão nova.

### Laboratório

- Imagens de roteador e switch Cisco IOS (as fornecidas na disciplina), com a topologia montada e todos os nós **ligados**.
- Endereços IP configurados, como na prática anterior.

---

## 5. Preparando o laboratório

### 5.1 Conectividade entre a máquina de scripts e o laboratório

Os scripts abrem conexões SSH (porta 22) e SNMP (UDP 161) até os IPs dos dispositivos. A máquina que os executa precisa **enxergar esses IPs**.

- O nó **Cloud1** da topologia faz essa ponte. No **GNS3**, ele é ligado a uma interface do host. No **PNETLab**, o equivalente é um nó de rede (Cloud/`pnet`) ligado ao SW1.
- A interface do host (ou da VM do PNETLab) usada pelo Cloud1 e o IP de gerência do SW1 precisam estar na **mesma rede**.
- Se os scripts rodam em outra máquina, ela precisa de rota até as redes `192.168.x.0/24` do laboratório.

**Teste antes de qualquer script:**

```bash
ping 192.168.1.101
ssh thiago@192.168.1.101
```

Se o `ping` ou o `ssh` falhar, os scripts também vão falhar. Resolva isso primeiro.

### 5.2 SSH em todos os dispositivos (roteadores e switches)

Cada equipamento precisa de SSH habilitado e de um usuário local com **privilégio 15**. Com esse privilégio, o Netmiko entra em modo de configuração sem precisar de senha de `enable`.

```text
enable
conf t
 hostname R1
 ip domain-name ifpb.edu.br
 crypto key generate rsa modulus 1024
 ip ssh version 2
 username ruan privilege 15 secret gomes
 line vty 0 4
  login local
  transport input ssh
end
write memory
```

Repita em cada dispositivo, trocando o `hostname`.

### 5.3 Checklist antes de rodar

| Verificação                      | Comando no equipamento                     |
| ---------------------------------- | ------------------------------------------ |
| SSH ativo, versão 2               | `show ip ssh`                            |
| Usuário existe                    | `show running-config \| include username` |
| IP de gerência configurado        | `show ip interface brief`                |
| Rota entre as redes dos roteadores | `show ip route`                          |

---

## 6. Configurando o inventário

Edite o `dispositivos.py` e ajuste os IPs dos switches (as linhas marcadas com `# AJUSTAR`) e, se necessário, o usuário e a senha:

```python
USUARIO = "thiago"
SENHA = "gouveia"

SWITCHES = {
    "SW1": _cisco_ios("192.168.1.201"),  
    ...
}
```

No `vlans.py`, defina quais switches recebem as VLANs. O padrão segue o roteiro (S1, S2 e S3):

```python
SWITCHES_ALVO = ["SW1", "SW2", "SW3"]
```

---

## 7. Quando e como executar cada script

### Ordem recomendada

| Etapa | Quando                                                         | Ação                                                          |
| ----- | -------------------------------------------------------------- | --------------------------------------------------------------- |
| 1     | Topologia ligada                                               | Configurar IPs e SSH ([seção 5](#5-preparando-o-laboratório)) |
| 2     | Antes dos scripts                                              | Testar `ping` e `ssh` até os dispositivos                  |
| 3     | SSH funcionando nos **switches**                         | Executar `vlans.py`                                           |
| 4     | SSH funcionando nos **roteadores**, com rotas entre eles | Executar `snmp_octetos.py`                                    |

Os dois scripts são independentes: um não precisa do outro. O `vlans.py` só exige SSH nos switches. O `snmp_octetos.py` só exige SSH e alcance IP nos roteadores.

### 7.1 `vlans.py`: criar as VLANs

**Quando usar:** com os switches acessíveis por SSH e antes de atribuir portas às VLANs.

```bash
python3 vlans.py
```

**O que acontece:**

1. Conecta em cada switch de `SWITCHES_ALVO`. Se um falhar (timeout ou autenticação), registra o erro e segue para o próximo.
2. Envia, para cada VLAN, `vlan N`, `name X` e `exit` com `send_config_set`.
3. Executa `show vlan brief` e imprime o resultado.
4. Salva com `save_config` (`running-config` para `startup-config`).
5. Desconecta de todos os switches.

**Saída esperada (por switch):**

```text
===== SW2 (192.168.1.202) =====
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Gi0/0, Gi0/1, ...
2    Alunos                           active
3    Professores                      active
4    Técnicos                         active
...
[OK] SW2: configuração salva
```

Pode rodar o script mais de uma vez. As VLANs já existentes são apenas reaplicadas.

### 7.2 `snmp_octetos.py`: habilitar o SNMP e monitorar

**Quando usar:** com os roteadores acessíveis por SSH e com tráfego passando pela Gi0/0 (por exemplo, `ping` entre os roteadores), para que os contadores variem.

```bash
python3 snmp_octetos.py
```

**O que acontece:**

1. **Fase Netmiko:** conecta em R1, R2 e R3 e aplica `snmp-server community <string> RO`, com uma community diferente por roteador. Salva a configuração e fecha as sessões SSH.
2. **Descoberta:** por SNMP, percorre a tabela `ifDescr` para achar o `ifIndex` da `GigabitEthernet0/0` em cada roteador.
3. **Monitoramento:** a cada 10 segundos, lê `ifInOctets` e `ifOutOctets` dessa interface nos três roteadores ao mesmo tempo e imprime os valores.

**Saída esperada:**

```text
[OK] R1: SNMP habilitado (community 'ifpb-r1')
[OK] R2: SNMP habilitado (community 'ifpb-r2')
[OK] R3: SNMP habilitado (community 'ifpb-r3')
============
R1 = in: 100 out: 120
R2 = in: 132 out: 133
R3 = in: 112 out: 111
============
```

Encerre com **Ctrl+C**.

**Como interpretar:** os valores são os **contadores acumulados** da interface (SNMPv2c, `ifInOctets` e `ifOutOctets`), não a variação por intervalo. Para ver os números mudando, gere tráfego, por exemplo `ping 192.168.2.102 repeat 1000` a partir de outro roteador.

**Verificar no roteador:**

```text
show running-config | include snmp
show snmp community
```

---

## 8. Solução de problemas

| Sintoma                                              | Causa provável                                                       | O que fazer                                                                                             |
| ---------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `NetmikoTimeoutException`                          | Sem alcance IP ou SSH desligado                                       | Teste `ping` e `ssh` manualmente; confira a ligação do Cloud1 e as rotas                          |
| `NetmikoAuthenticationException`                   | Usuário ou senha errados                                             | Confira `dispositivos.py` e o `username ... secret ...` no equipamento                              |
| Erro ao entrar em modo de configuração             | Usuário sem privilégio 15                                           | Use `username ruan privilege 15 secret gomes`                                                         |
| `no matching key exchange method` / falha de cifra | SSH antigo do IOS                                                     | `ip ssh version 2` e, se persistir, chave RSA de 2048 bits (`crypto key generate rsa modulus 2048`) |
| `% Invalid input` ao criar a VLAN "Técnicos"      | Acento no nome                                                        | Troque por `Tecnicos` na lista `VLANS` do `vlans.py`                                              |
| `No SNMP response received before timeout`         | SNMP não habilitado, community errada, UDP 161 bloqueado ou sem rota | Veja `show snmp community`, teste o `ping` e verifique ACLs                                         |
| `interface GigabitEthernet0/0 não encontrada`     | Nome da interface diferente na imagem                                 | Rode `show interfaces` no roteador e ajuste `INTERFACE` no `snmp_octetos.py`                      |
| `ModuleNotFoundError: dispositivos`                | Script executado fora da pasta                                        | Faça `cd netmiko` antes de rodar                                                                     |
| Valores `in`/`out` não mudam                    | Sem tráfego na Gi0/0                                                 | Gere tráfego com `ping` entre os roteadores                                                          |

---

## 9. Observações

- **Credenciais em texto claro:** usuário e senha ficam no `dispositivos.py` por simplicidade, o que é aceitável para um laboratório acadêmico. Em ambientes reais, use variáveis de ambiente ou um cofre de segredos.
- **SNMPv2c:** a community trafega sem criptografia. O roteiro pede SNMPv2; em produção prefira SNMPv3.
- **Persistência:** os dois scripts usam `save_config`, então as alterações sobrevivem a um reinício do equipamento. Em GNS3 e PNETLab, lembre-se também de que reiniciar o nó sem salvar o laboratório pode descartar o estado.
- **Entrega:** conforme o roteiro, entregue os códigos Python (`vlans.py`, `snmp_octetos.py` e o `dispositivos.py` de apoio).

## Referências

- Netmiko (GitHub): [https://github.com/ktbyers/netmiko](https://github.com/ktbyers/netmiko)
- Netmiko (blog): [https://pynet.twb-tech.com/blog/netmiko-python-library.html](https://pynet.twb-tech.com/blog/netmiko-python-library.html)
- pysnmp: [https://pysnmp.readthedocs.io/](https://pysnmp.readthedocs.io/)
