#!/usr/bin/env bash
# =====================================================================
#  diagnostico.sh  -  "Donde se rompe?"  Revisa la red CAPA POR CAPA
#  y dice que revisar segun el primer paso que falle.
#
#  USO:  bash diagnostico.sh
# =====================================================================
DNS=172.16.3.130; HTTP=172.16.3.66
V="\e[32m"; R="\e[31m"; A="\e[33m"; N="\e[0m"
ok(){ echo -e "  ${V}[OK]${N}    $1"; }
mal(){ echo -e "  ${R}[FALLA]${N} $1"; echo -e "          ${A}-> $2${N}"; }
p(){ ping -c 2 -W 2 "$1" >/dev/null 2>&1; }

echo "================ DIAGNOSTICO RED HOSPITAL G3 ================"

# --- Capa 1: cable ---
IFACE=$(ip -o -4 route show default | awk '{print $5; exit}')
[ -z "$IFACE" ] && IFACE=$(ls /sys/class/net | while read i; do [ -e /sys/class/net/$i/device ] && [ ! -d /sys/class/net/$i/wireless ] && echo $i; done | head -1)
echo "Tarjeta: $IFACE"
if [ "$(cat /sys/class/net/$IFACE/carrier 2>/dev/null)" = "1" ]; then ok "Capa 1: el cable tiene link"
else mal "Capa 1: no hay link en $IFACE" "cable suelto/danado o puerto del switch apagado (shutdown)"; exit 1; fi

# --- Capa 3 local: IP y gateway ---
IP=$(ip -4 -br addr show "$IFACE" | awk '{print $3}')
GW=$(ip route | awk '/default/{print $3; exit}')
[ -n "$IP" ] && ok "IP: $IP" || { mal "No hay IP" "corre: sudo bash configurar_pc_linux.sh <rol>"; exit 1; }
[ -n "$GW" ] && ok "Gateway: $GW" || { mal "No hay gateway" "corre otra vez configurar_pc_linux.sh"; exit 1; }
if ip -br link | grep -v "^$IFACE" | grep -q "UP" && ip route | grep default | grep -vq "$IFACE"; then
  mal "Hay OTRA ruta por defecto (Wi-Fi u otra tarjeta)" "apaga el Wi-Fi: nmcli radio wifi off"
fi

# --- Capa 2/3: gateway ---
if p "$GW"; then ok "Ping al gateway $GW (VLAN + trunk + subinterfaz)"
else mal "No responde el gateway $GW" "puerto en VLAN equivocada (show vlan brief), trunk caido (show interfaces trunk) o subinterfaz mal (show ip interface brief)"; exit 1; fi

# --- Capa 3: red de transito y routers ---
for r in 172.16.3.193 172.16.3.194 172.16.3.195 172.16.3.196; do
  p $r && ok "Router en R5: $r" || mal "No responde $r" "cable del router al Switch4, o falta ruta de regreso en ese router (show ip route)"
done

# --- Capa 3: servidores ---
p $DNS  && ok "Ping al servidor DNS $DNS"  || mal "No llega al DNS $DNS"  "rutas estaticas hacia 172.16.3.128/27, o el servidor apagado/firewall"
p $HTTP && ok "Ping al servidor HTTP $HTTP" || mal "No llega al HTTP $HTTP" "rutas estaticas hacia 172.16.3.64/26, o el servidor apagado/firewall"

# --- Capa 7: DNS ---
grep -q "$DNS" /etc/resolv.conf && ok "El PC usa el DNS $DNS" || mal "El PC NO usa el DNS del hospital" "corre otra vez configurar_pc_linux.sh"
R=$(nslookup www.hospital.local $DNS 2>/dev/null | awk '/^Address: /{print $2}' | tail -1)
[ "$R" = "$HTTP" ] && ok "nslookup www.hospital.local -> $R" || mal "El DNS no resuelve www.hospital.local" "en el servidor DNS: sudo systemctl status dnsmasq"
getent hosts www.hospital.local >/dev/null && ok "El sistema resuelve el nombre (getent)" || mal "nslookup si pero el sistema no" "/etc/nsswitch.conf debe decir: hosts: files dns"

# --- Capa 7: HTTP ---
if curl -s -m 5 --noproxy '*' http://www.hospital.local | grep -qi "hospital"; then ok "Pagina web por nombre: http://www.hospital.local"
else mal "No carga la pagina" "en el servidor HTTP: sudo systemctl status apache2 ; revisar proxy del navegador"; fi
echo "============================================================="
