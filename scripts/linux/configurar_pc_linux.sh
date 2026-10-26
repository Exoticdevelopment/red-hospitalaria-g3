#!/usr/bin/env bash
# =====================================================================
#  configurar_pc_linux.sh - Pone IP estatica a un PC Ubuntu (Hospital G3)
#
#  Uso:   sudo bash configurar_pc_linux.sh <opcion>
#  Ej.:   sudo bash configurar_pc_linux.sh 1      (PC1 Urgencias)
#         sudo bash configurar_pc_linux.sh dns    (Servidor DNS)
#
#  Requiere NetworkManager (nmcli), que trae Ubuntu Desktop.
# =====================================================================
set -e

# --- Tabla de direccionamiento (sale del Excel VLSM) -----------------
# formato: "IP/prefijo GATEWAY descripcion"
case "$1" in
  1)    DATOS="172.16.2.10/25   172.16.2.1   PC1_Urgencias(Switch0_Fa0/1,VLAN210)";;
  2)    DATOS="172.16.1.10/24   172.16.1.1   PC2_Consulta(Switch2_Fa0/1,VLAN250)";;
  3)    DATOS="172.16.0.10/24   172.16.0.1   PC_Hospitalizacion(Switch0_Fa0/2,VLAN220)";;
  4)    DATOS="172.16.3.10/26   172.16.3.1   PC_Laboratorio(Switch1_Fa0/1,VLAN230)";;
  5)    DATOS="172.16.3.138/27  172.16.3.129 PC_Farmacia(Switch1_Fa0/2,VLAN240)";;
  6)    DATOS="172.16.2.138/25  172.16.2.129 PC_Imagenes(Switch2_Fa0/2,VLAN260)";;
  7)    DATOS="172.16.3.74/26   172.16.3.65  PC_Administracion(Switch3_Fa0/1,VLAN270)";;
  8)    DATOS="172.16.3.170/27  172.16.3.161 PC_Ing_Biomedica(Switch3_Fa0/2,VLAN280)";;
  dns)  DATOS="172.16.3.130/27  172.16.3.129 Servidor_DNS(Switch1_Fa0/3,VLAN240)";;
  http) DATOS="172.16.3.66/26   172.16.3.65  Servidor_HTTP(Switch3_Fa0/3,VLAN270)";;
  *) echo "Uso: sudo bash $0 {1..8|dns|http}"; exit 1;;
esac
read -r IP GW DESC <<< "$DATOS"
DNS=172.16.3.130     # todos los equipos usan el servidor DNS del hospital

# --- Buscar la conexion cableada (TYPE=ethernet) ---------------------
# nmcli -t imprime en formato "campo:campo" para poder procesarlo
CON=$(nmcli -t -f NAME,TYPE con show | grep ':802-3-ethernet' | head -1 | cut -d: -f1)
if [ -z "$CON" ]; then
  echo "[!] No encontre una conexion de cable. Revisa: nmcli con show"; exit 1
fi
echo ">>> Configurando $DESC en la conexion \"$CON\""
echo "    IP $IP  gateway $GW  DNS $DNS"

# --- Apagar Wi-Fi: si no, el PC podria salir por otra red ------------
nmcli radio wifi off || true

# --- Aplicar IP estatica ---------------------------------------------
# ipv4.method manual -> IP fija (no DHCP)
nmcli con mod "$CON" ipv4.method manual ipv4.addresses "$IP" \
      ipv4.gateway "$GW" ipv4.dns "$DNS" ipv6.method disabled
nmcli con up "$CON"

# --- Ubuntu trata ".local" como mDNS (Avahi) y no pregunta al DNS ----
# Cambiamos la linea "hosts:" para que use primero files y luego dns.
if grep -q '^hosts:' /etc/nsswitch.conf; then
  cp -n /etc/nsswitch.conf /etc/nsswitch.conf.bak
  sed -i 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf
fi

sleep 3
echo; ip -4 addr show | grep inet
echo; echo ">>> Ping al gateway $GW"
ping -c 4 "$GW" && echo ">>> OK: la VLAN, el trunk y la subinterfaz funcionan"
