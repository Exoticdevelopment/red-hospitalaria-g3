#!/usr/bin/env python3
"""
mini_dns.py - Servidor DNS MINIMO de respaldo (solo Python, sin instalar nada).

Se usa SOLO si dnsmasq no esta instalado y no hay internet para instalarlo.
Responde un unico registro A:   www.hospital.local -> 172.16.3.66
Cualquier otro nombre -> "no existe" (NXDOMAIN).

Uso:  sudo python3 mini_dns.py            (deja la terminal ABIERTA)

Como funciona (para estudiar):
  - DNS usa UDP puerto 53. Abrimos un socket UDP en 172.16.3.130:53.
  - Cada pregunta DNS trae: cabecera de 12 bytes + el nombre + tipo + clase.
  - Copiamos la pregunta y le agregamos una "respuesta" de tipo A (IPv4).
"""
import socket, struct, sys

ESCUCHAR = "172.16.3.130"
REGISTROS = {"www.hospital.local": "172.16.3.66", "hospital.local": "172.16.3.66"}

def leer_nombre(datos, pos):
    partes = []
    while datos[pos] != 0:
        n = datos[pos]
        partes.append(datos[pos + 1:pos + 1 + n].decode(errors="replace"))
        pos += n + 1
    return ".".join(partes).lower(), pos + 1

def responder(consulta):
    ident, flags = struct.unpack("!HH", consulta[:4])
    nombre, fin = leer_nombre(consulta, 12)
    tipo, clase = struct.unpack("!HH", consulta[fin:fin + 4])
    pregunta = consulta[12:fin + 4]
    ip = REGISTROS.get(nombre)
    if ip and tipo == 1:                      # tipo 1 = registro A (IPv4)
        cab = struct.pack("!HHHHHH", ident, 0x8580, 1, 1, 0, 0)
        resp = struct.pack("!HHHIH", 0xC00C, 1, 1, 60, 4) + socket.inet_aton(ip)
        print(f"  {nombre} A -> {ip}")
        return cab + pregunta + resp
    if ip:                                    # existe pero piden AAAA u otro: respuesta vacia
        return struct.pack("!HHHHHH", ident, 0x8580, 1, 0, 0, 0) + pregunta
    print(f"  {nombre} -> no existe")
    return struct.pack("!HHHHHH", ident, 0x8583, 1, 0, 0, 0) + pregunta   # rcode 3 = NXDOMAIN

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.bind((ESCUCHAR, 53))
    except OSError as e:
        sys.exit(f"[!] No pude abrir {ESCUCHAR}:53 ({e}). Revisa que la IP este puesta y que nada mas use el puerto 53:  sudo ss -lunp | grep :53")
    print(f">>> mini DNS escuchando en {ESCUCHAR}:53  (Ctrl+C para salir)")
    while True:
        datos, cliente = s.recvfrom(512)
        try:
            s.sendto(responder(datos), cliente)
        except Exception as e:
            print("  consulta rara ignorada:", e)

if __name__ == "__main__":
    main()
