"""Seção 5 - Habilita SNMP nos roteadores (Netmiko) e monitora octetos
de entrada/saída da Gi0/0 a cada 10 s (pysnmp, SNMPv2c).

Requer pysnmp >= 7 (API assíncrona).
"""

import asyncio

from netmiko import (
    ConnectHandler,
    NetmikoAuthenticationException,
    NetmikoTimeoutException,
)
from pysnmp.hlapi.v3arch.asyncio import (
    CommunityData,
    ContextData,
    ObjectIdentity,
    ObjectType,
    SnmpEngine,
    UdpTransportTarget,
    get_cmd,
    walk_cmd,
)

from dispositivos import ROTEADORES

ROTEADORES_ALVO = ["R1", "R2", "R3"]
# Uma community por roteador, na mesma ordem de ROTEADORES_ALVO.
COMUNIDADES = ["ifpb-r1", "ifpb-r2", "ifpb-r3"]

INTERFACE = "GigabitEthernet0/0"
INTERVALO = 10  # segundos

OID_IF_DESCR = "1.3.6.1.2.1.2.2.1.2"
OID_IF_IN_OCTETS = "1.3.6.1.2.1.2.2.1.10"
OID_IF_OUT_OCTETS = "1.3.6.1.2.1.2.2.1.16"


# ----------------------------- Netmiko -----------------------------
def conectar_roteadores():
    """Lista de (nome, ConnectHandler, community)."""
    conexoes = []
    for nome, comunidade in zip(ROTEADORES_ALVO, COMUNIDADES):
        try:
            conn = ConnectHandler(**ROTEADORES[nome])
            conexoes.append((nome, conn, comunidade))
        except (NetmikoTimeoutException, NetmikoAuthenticationException) as erro:
            print(f"[ERRO] {nome}: não foi possível conectar ({erro.__class__.__name__})")
    return conexoes


def habilitar_snmp(conexoes):
    for nome, conn, comunidade in conexoes:
        conn.send_config_set([f"snmp-server community {comunidade} RO"])
        conn.save_config()
        print(f"[OK] {nome}: SNMP habilitado (community '{comunidade}')")


# ------------------------------ SNMP -------------------------------
async def _alvo(host):
    return await UdpTransportTarget.create((host, 161), timeout=2, retries=1)


async def descobrir_ifindex(engine, host, comunidade, interface):
    """Faz walk em ifDescr e devolve o ifIndex da interface."""
    alvo = await _alvo(host)
    async for erro_ind, erro_stat, _, var_binds in walk_cmd(
        engine,
        CommunityData(comunidade, mpModel=1),
        alvo,
        ContextData(),
        ObjectType(ObjectIdentity(OID_IF_DESCR)),
        lexicographicMode=False,
    ):
        if erro_ind or erro_stat:
            raise RuntimeError(erro_ind or erro_stat.prettyPrint())
        for oid, valor in var_binds:
            if str(valor) == interface:
                return int(str(oid).rsplit(".", 1)[1])
    raise RuntimeError(f"interface {interface} não encontrada em {host}")


async def ler_octetos(engine, host, comunidade, ifindex):
    """Retorna (octetos_entrada, octetos_saida)."""
    alvo = await _alvo(host)
    erro_ind, erro_stat, _, var_binds = await get_cmd(
        engine,
        CommunityData(comunidade, mpModel=1),
        alvo,
        ContextData(),
        ObjectType(ObjectIdentity(f"{OID_IF_IN_OCTETS}.{ifindex}")),
        ObjectType(ObjectIdentity(f"{OID_IF_OUT_OCTETS}.{ifindex}")),
    )
    if erro_ind or erro_stat:
        raise RuntimeError(erro_ind or erro_stat.prettyPrint())
    return int(var_binds[0][1]), int(var_binds[1][1])


async def monitorar(conexoes):
    engine = SnmpEngine()
    roteadores = [(nome, conn.host, comunidade) for nome, conn, comunidade in conexoes]

    # ifIndex da Gi0/0 em cada roteador (descoberto uma única vez)
    ifindex = {}
    for nome, host, comunidade in roteadores:
        ifindex[nome] = await descobrir_ifindex(engine, host, comunidade, INTERFACE)

    while True:
        resultados = await asyncio.gather(
            *(ler_octetos(engine, host, com, ifindex[nome]) for nome, host, com in roteadores),
            return_exceptions=True,
        )
        print("============")
        for (nome, _, _), res in zip(roteadores, resultados):
            if isinstance(res, Exception):
                print(f"{nome} = erro: {res}")
            else:
                print(f"{nome} = in: {res[0]} out: {res[1]}")
        print("============")
        await asyncio.sleep(INTERVALO)


def main():
    conexoes = conectar_roteadores()
    if not conexoes:
        return
    try:
        habilitar_snmp(conexoes)
    finally:
        # o SNMP não usa a sessão SSH; libera as conexões antes do loop
        for _, conn, _ in conexoes:
            conn.disconnect()

    try:
        asyncio.run(monitorar(conexoes))
    except KeyboardInterrupt:
        print("\nMonitoramento encerrado")


if __name__ == "__main__":
    main()
