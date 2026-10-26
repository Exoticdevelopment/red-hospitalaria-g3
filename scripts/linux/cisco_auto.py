#!/usr/bin/env python3
"""
cisco_auto.py - Configura por consola los equipos del examen Hospital G3.

Uso (con el cable de consola ya conectado al equipo):
    sudo python3 cisco_auto.py Switch2
    sudo python3 cisco_auto.py Router0 --borrar
    sudo python3 cisco_auto.py Switch4 --puerto /dev/ttyUSB0

  --borrar  hace write erase (+ delete vlan.dat en switches) y reload antes de configurar.
  --evidencia  NO configura nada: solo corre los "show" y los guarda en <Equipo>_evidencia.txt
             sudo python3 cisco_auto.py Router0 --evidencia
Equipos: Switch0 Switch1 Switch2 Switch3 Switch4 Router0 Router1 Router2 Router3
Requiere: sudo apt install python3-serial
"""
# ---------------------------------------------------------------------
# COMO FUNCIONA (resumen para estudiar)
#  1. Abre el puerto serie (/dev/ttyUSB0) a 9600 8N1, igual que picocom.
#  2. Escribe cada comando LETRA POR LETRA (pausa de 10 ms) para que el
#     equipo no pierda caracteres (problema real que tuvimos en el lab).
#  3. Despues de cada comando ESPERA el prompt correcto con expresiones
#     regulares: "Switch2(config)#", "Router0#", "Password:", etc.
#  4. Reacciona a lo que ve: responde "no" al dialogo inicial, prueba
#     contrasenas, confirma [confirm], cancela "Save?" en el reload.
#  5. Aplica la lista de comandos del equipo (CONFIGS), guarda con
#     copy run start y muestra la verificacion.
#  La configuracion de cada equipo se GENERA con funciones (sw_acceso y
#  router) para no repetir texto y evitar errores de digitacion.
#  AVISO lab fisico: en routers NO usar --borrar con la consola conectada
#  (reload + cable USB dejo routers en bucle "ROMMON initialized").
# ---------------------------------------------------------------------
import argparse, re, sys, time

try:
    import serial
except ImportError:
    sys.exit("Falta pyserial. Instala con:  sudo apt install python3-serial")

PASSWORDS = ["cisco", "class", ""]   # se prueban si el equipo pide contraseña

# ---------------------------------------------------------------- configs
def sw_acceso(nombre, v1, n1, v2, n2, servidor_vlan=None):
    c = [f"hostname {nombre}", "no ip domain-lookup",
         f"vlan {v1}", f"name {n1}", "exit",
         f"vlan {v2}", f"name {n2}", "exit",
         "interface GigabitEthernet0/1", "description TRUNK_A_ROUTER",
         "switchport mode trunk", f"switchport trunk allowed vlan {v1},{v2}",
         "no shutdown", "exit"]
    puertos = [("FastEthernet0/1", v1), ("FastEthernet0/2", v2)]
    if servidor_vlan:
        puertos.append(("FastEthernet0/3", servidor_vlan))
    for p, v in puertos:
        c += [f"interface {p}", "switchport mode access",
              f"switchport access vlan {v}", "spanning-tree portfast",
              "no shutdown", "exit"]
    return c

def router(nombre, sub, transito, rutas):
    c = [f"hostname {nombre}", "no ip domain-lookup",
         "interface GigabitEthernet0/0", "description TRUNK_AL_SWITCH_DE_ACCESO",
         "no ip address", "no shutdown", "exit"]
    for vlan, ip, mask in sub:
        c += [f"interface GigabitEthernet0/0.{vlan}", f"encapsulation dot1Q {vlan}",
              f"ip address {ip} {mask}", "exit"]
    c += ["interface GigabitEthernet0/1", "description R5_TRANSITO",
          f"ip address {transito} 255.255.255.248", "no shutdown", "exit"]
    c += [f"ip route {r}" for r in rutas]
    return c

M24, M25, M26, M27 = "255.255.255.0", "255.255.255.128", "255.255.255.192", "255.255.255.224"
R0, R1, R2, R3 = "172.16.3.193", "172.16.3.194", "172.16.3.195", "172.16.3.196"
LAN = {  # red: (destino, mascara, router dueño)
    "R1": ("172.16.2.0", M25, R0),   "R2": ("172.16.0.0", M24, R0),
    "R3": ("172.16.3.0", M26, R1),   "R4": ("172.16.3.128", M27, R1),
    "R6": ("172.16.1.0", M24, R2),   "R7": ("172.16.2.128", M25, R2),
    "R8": ("172.16.3.64", M26, R3),  "R9": ("172.16.3.160", M27, R3),
}
def rutas_para(propio):
    return [f"{d} {m} {nh}" for d, m, nh in LAN.values() if nh != propio]

CONFIGS = {
    "Switch0": sw_acceso("Switch0", 210, "R1_Urgencias", 220, "R2_Hospitalizacion"),
    "Switch1": sw_acceso("Switch1", 230, "R3_Laboratorio", 240, "R4_Farmacia", servidor_vlan=240),
    "Switch2": sw_acceso("Switch2", 250, "R6_Consulta", 260, "R7_Imagenes"),
    "Switch3": sw_acceso("Switch3", 270, "R8_Administracion", 280, "R9_Ing_Biomedica", servidor_vlan=270),
    "Switch4": ["hostname Switch4", "no ip domain-lookup",
                "interface range FastEthernet0/1 - 4", "description R5_TRANSITO",
                "switchport mode access", "switchport access vlan 1",
                "spanning-tree portfast", "no shutdown", "exit"],
    "Router0": router("Router0", [(210, "172.16.2.1", M25), (220, "172.16.0.1", M24)], R0, rutas_para(R0)),
    "Router1": router("Router1", [(230, "172.16.3.1", M26), (240, "172.16.3.129", M27)], R1, rutas_para(R1)),
    "Router2": router("Router2", [(250, "172.16.1.1", M24), (260, "172.16.2.129", M25)], R2, rutas_para(R2)),
    "Router3": router("Router3", [(270, "172.16.3.65", M26), (280, "172.16.3.161", M27)], R3, rutas_para(R3)),
}
VERIFICAR_SW = ["show vlan brief", "show interfaces trunk"]
VERIFICAR_RT = ["show ip interface brief", "show ip route"]
EVIDENCIA_SW = ["show cdp neighbors", "show vlan brief", "show interfaces trunk", "show running-config"]
EVIDENCIA_RT = ["show cdp neighbors", "show ip interface brief", "show ip route",
                "show version | include register", "show running-config"]

# ---------------------------------------------------------------- consola
class Consola:
    def __init__(self, puerto, log):
        self.s = serial.Serial(puerto, 9600, bytesize=8, parity="N", stopbits=1,
                               timeout=0.2, xonxoff=False, rtscts=False, dsrdtr=False)
        self.log = log
        self.buf = ""

    def enviar(self, texto, fin="\r"):
        for ch in texto + fin:              # despacio: evita perder caracteres
            self.s.write(ch.encode())
            time.sleep(0.01)

    def esperar(self, patrones, segundos):
        """Lee hasta que aparezca alguno de los patrones (regex). Devuelve índice o -1."""
        fin = time.time() + segundos
        acc = ""
        while time.time() < fin:
            d = self.s.read(512).decode(errors="replace")
            if d:
                acc += d
                sys.stdout.write(d); sys.stdout.flush()
                self.log.write(d)
                for i, p in enumerate(patrones):
                    if re.search(p, acc[-400:], re.I):
                        self.buf = acc
                        return i
        self.buf = acc
        return -1

# ---------------------------------------------------------------- lógica
DIALOGO = r"initial configuration dialog\?"
AUTOINST = r"terminate autoinstall\?"
PASS = r"Password:\s*$"
MORE = r"--More--"
USER_P = r"[\w.\-]+>\s*$"
PRIV_P = r"[\w.\-]+#\s*$"
CONF_P = r"[\w.\-]+\(config[\w\-]*\)#\s*$"

def llegar_a_priv(c):
    """Despierta el equipo y llega a modo privilegiado (#)."""
    claves = list(PASSWORDS)
    for intento in range(25):
        c.enviar("")
        i = c.esperar([DIALOGO, AUTOINST, PASS, MORE, CONF_P, PRIV_P, USER_P,
                       r"\[yes/no\]", r"\[confirm\]"], 8)
        if i == 0 or i == 7:
            c.enviar("no")
        elif i == 1:
            c.enviar("yes")
        elif i == 2:
            if not claves:
                sys.exit("\n[!] El equipo pide una contraseña desconocida. Avisen al docente.")
            c.enviar(claves.pop(0))
        elif i == 3:
            c.enviar(" ", fin="")
        elif i == 4:
            c.enviar("end")
        elif i == 5:
            return
        elif i == 6:
            claves = list(PASSWORDS)   # lista nueva para enable
            c.enviar("enable")
            j = c.esperar([PASS, PRIV_P], 6)
            while j == 0:
                if not claves:
                    sys.exit("\n[!] enable pide contraseña desconocida.")
                c.enviar(claves.pop(0))
                j = c.esperar([PASS, PRIV_P, r"Bad pass"], 6)
                if j == 2:
                    break
            if re.search(PRIV_P, c.buf[-200:]):
                return
        elif i == 8:
            c.enviar("")
        else:
            time.sleep(2)   # quizá está arrancando
    sys.exit("\n[!] No pude llegar a modo privilegiado. ¿El cable está en CONSOLE y el equipo encendido?")

def nombre_actual(c):
    c.enviar("")
    c.esperar([PRIV_P], 5)
    m = re.findall(r"([\w.\-]+)#\s*$", c.buf, re.M)
    return m[-1] if m else "?"

def borrar_y_recargar(c, es_switch):
    print("\n\n=== Borrando configuración ===")
    c.enviar("write erase")
    if c.esperar([r"\[confirm\]"], 15) == 0:
        c.enviar("")
    c.esperar([PRIV_P], 30)
    if es_switch:
        c.enviar("delete flash:vlan.dat")
        for _ in range(3):
            i = c.esperar([r"Delete filename", r"\[confirm\]", PRIV_P], 10)
            if i in (0, 1):
                c.enviar("")
            else:
                break
    print("\n\n=== Reiniciando (puede tardar 2-5 min) ===")
    c.enviar("reload")
    for _ in range(4):
        i = c.esperar([r"Save\?", r"\[yes/no\]", r"\[confirm\]"], 15)
        if i in (0, 1):
            c.enviar("no")
        elif i == 2:
            c.enviar("")
            break
        else:
            break
    i = c.esperar([DIALOGO, r"Press RETURN to get started", AUTOINST], 600)
    if i == -1:
        print("\n[!] No vi el final del arranque; intento continuar igual.")
    time.sleep(3)

def configurar(c, lineas):
    print("\n\n=== Configurando ===")
    c.enviar("terminal length 0"); c.esperar([PRIV_P], 5)
    c.enviar("configure terminal"); c.esperar([CONF_P], 10)
    for l in lineas:
        c.enviar(l)
        i = c.esperar([CONF_P, r"% (Invalid|Incomplete|Ambiguous)"], 10)
        if i == 1:
            print(f"\n[!] ERROR en la línea: {l}")
            c.esperar([CONF_P], 3)
    c.enviar("end"); c.esperar([PRIV_P], 10)
    print("\n\n=== Guardando ===")
    c.enviar("copy running-config startup-config")
    if c.esperar([r"Destination filename", r"\[OK\]"], 15) == 0:
        c.enviar("")
        c.esperar([r"\[OK\]"], 30)
    c.esperar([PRIV_P], 10)

def main():
    ap = argparse.ArgumentParser(description="Configura un equipo Cisco del Hospital G3 por consola")
    ap.add_argument("equipo", choices=CONFIGS.keys())
    ap.add_argument("--borrar", action="store_true", help="write erase + reload antes de configurar")
    ap.add_argument("--puerto", default="/dev/ttyUSB0")
    ap.add_argument("--si", action="store_true", help="no pedir confirmación")
    ap.add_argument("--evidencia", action="store_true", help="solo guardar los show (no configura)")
    a = ap.parse_args()

    if a.evidencia:
        es_sw = a.equipo.startswith("Switch")
        with open(f"{a.equipo}_evidencia.txt", "w") as log:
            c = Consola(a.puerto, log)
            llegar_a_priv(c)
            c.enviar("terminal length 0"); c.esperar([PRIV_P], 5)
            for cmd in (EVIDENCIA_SW if es_sw else EVIDENCIA_RT):
                c.enviar(cmd); c.esperar([PRIV_P], 30)
        print(f"\n\n>>> Evidencia guardada en {a.equipo}_evidencia.txt")
        return

    es_switch = a.equipo.startswith("Switch")
    with open(f"log_{a.equipo}.txt", "a") as log:
        c = Consola(a.puerto, log)
        print(f">>> Conectado a {a.puerto}. Despertando el equipo...\n")
        llegar_a_priv(c)
        actual = nombre_actual(c)
        print(f"\n\n>>> El equipo conectado se llama: {actual}")
        print(f">>> Se va a configurar como: {a.equipo}" + ("  (BORRANDO primero)" if a.borrar else ""))
        if actual not in ("Switch", "Router", "?", a.equipo) and not a.si:
            print(">>> OJO: el nombre no coincide. ¿Seguro que el cable está en el equipo correcto?")
        if not a.si and input(">>> ¿Continuar? (s/n): ").strip().lower() != "s":
            sys.exit("Cancelado.")

        if a.borrar:
            borrar_y_recargar(c, es_switch)
            llegar_a_priv(c)

        configurar(c, CONFIGS[a.equipo])

        print("\n\n=== Verificación ===")
        for cmd in (VERIFICAR_SW if es_switch else VERIFICAR_RT):
            c.enviar(cmd)
            c.esperar([PRIV_P], 20)
        print(f"\n\n>>> LISTO: {a.equipo} configurado y guardado. Log en log_{a.equipo}.txt")

if __name__ == "__main__":
    main()
