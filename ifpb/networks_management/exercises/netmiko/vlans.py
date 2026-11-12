"""Seção 4 - Criação automatizada de VLANs com Netmiko."""

from netmiko import (
    ConnectHandler,
    NetmikoAuthenticationException,
    NetmikoTimeoutException,
)

from dispositivos import SWITCHES

SWITCHES_ALVO = ["SW1", "SW2", "SW3"]

VLANS = [
    (2, "Alunos"),
    (3, "Professores"),
    (4, "Tecnicos"),  
]

def montar_comandos(vlans):
    """Gera: vlan N / name X / exit, para cada VLAN."""
    comandos = []
    for vlan_id, nome in vlans:
        comandos += [f"vlan {vlan_id}", f"name {nome}", "exit"]
    return comandos


def conectar(nomes):
    """Cria a lista de objetos ConnectHandler (um por switch)."""
    conexoes = []
    for nome in nomes:
        try:
            conexoes.append((nome, ConnectHandler(**SWITCHES[nome])))
        except (NetmikoTimeoutException, NetmikoAuthenticationException) as erro:
            print(f"[ERRO] {nome}: não foi possível conectar ({erro.__class__.__name__})")
    return conexoes


def main():
    conexoes = conectar(SWITCHES_ALVO)
    comandos = montar_comandos(VLANS)

    try:
        for nome, conn in conexoes:
            print(f"\n===== {nome} ({conn.host}) =====")

            conn.send_config_set(comandos)

            print(conn.send_command("show vlan brief"))

            conn.save_config()
            print(f"[OK] {nome}: configuração salva")
    finally:
        for _, conn in conexoes:
            conn.disconnect()

    print("\nScript finalizado")


if __name__ == "__main__":
    main()