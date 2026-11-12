"""Inventário dos dispositivos da topologia PnetLab.
Roteadores: IPs conforme os exemplos do roteiro.
Switches: IPs não foram detalhados, então eu os ajustei de 
acordo com minha preferência.
"""

USUARIO = "thiago"
SENHA = "gouveia"


def _cisco_ios(host: str) -> dict:
    return {
        "device_type": "cisco_ios",
        "host": host,
        "username": USUARIO,
        "password": SENHA,
    }


ROTEADORES = {
    "R1": _cisco_ios("192.168.1.101"),
    "R2": _cisco_ios("192.168.2.102"),
    "R3": _cisco_ios("192.168.3.103"),
}

SWITCHES = {
    "SW1": _cisco_ios("192.168.1.201"), 
    "SW2": _cisco_ios("192.168.1.202"),  
    "SW3": _cisco_ios("192.168.1.203"),  
    "SW4": _cisco_ios("192.168.1.204"),  
}
