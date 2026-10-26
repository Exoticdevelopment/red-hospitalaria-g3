#!/usr/bin/env bash
# =====================================================================
#  configurar_pc_linux.sh  -  IP estatica para un PC/servidor Ubuntu
#  Red hospitalaria G3 (Universidad Libre Cali, Redes 2026-2)
#
#  USO:
#     sudo bash configurar_pc_linux.sh <rol>
#        rol = 1..8 | dns | http        (ver tabla abajo)
#     sudo bash configurar_pc_linux.sh restaurar
#        deja el PC como estaba (DHCP, Wi-Fi, DNS original)
#
#  PENSADO PARA PCs DEL LABORATORIO QUE USARON OTROS GRUPOS:
#   - detecta solo la tarjeta de CABLE (ignora Wi-Fi, docker, VirtualBox)
#   - avisa si el cable no esta conectado (sin "link")
#   - desactiva las conexiones viejas de esa tarjeta y crea una nueva "G3-<rol>"
#   - borra IPs y rutas viejas de la tarjeta
#   - apaga el Wi-Fi (si no, el PC puede salir por internet y no por la red del lab)
#   - quita proxys de la terminal y pone el DNS del hospital
#   - arregla el ".local" (Ubuntu lo manda a mDNS en vez de al DNS)
#   - si hay firewall (ufw) activo, deja pasar el trafico de 172.16.0.0/22
#   - guarda copias de seguridad para poder "restaurar"
# =====================================================================
set -u

# ---------- 0. Debe correr como root (sudo) ----------
if [ "$(id -u)" -ne 0 ]; then
  echo "[!] Ejecuta con sudo:  sudo bash $0 ${1:-<rol>}"; exit 1
fi

DNS=172.16.3.130          # el servidor DNS del hospital (R4 Farmacia)
BK=/root/g3_backup        # carpeta de copias de seguridad
mkdir -p "$BK"

# ---------- 1. Tabla de direccionamiento (sale del Excel VLSM) ----------
#   formato:  "IP/prefijo  GATEWAY  descripcion"
case "${1:-}" in
  1)    DATOS="172.16.2.10/25   172.16.2.1   PC1-Urgencias(Switch0-Fa0/1,VLAN210)";;
  2)    DATOS="172.16.1.10/24   172.16.1.1   PC2-Consulta(Switch2-Fa0/1,VLAN250)";;
  3)    DATOS="172.16.0.10/24   172.16.0.1   PC-Hospitalizacion(Switch0-Fa0/2,VLAN220)";;
  4)    DATOS="172.16.3.10/26   172.16.3.1   PC-Laboratorio(Switch1-Fa0/1,VLAN230)";;
  5)    DATOS="172.16.3.138/27  172.16.3.129 PC-Farmacia(Switch1-Fa0/2,VLAN240)";;
  6)    DATOS="172.16.2.138/25  172.16.2.129 PC-Imagenes(Switch2-Fa0/2,VLAN260)";;
  7)    DATOS="172.16.3.74/26   172.16.3.65  PC-Administracion(Switch3-Fa0/1,VLAN270)";;
  8)    DATOS="172.16.3.170/27  172.16.3.161 PC-Ing-Biomedica(Switch3-Fa0/2,VLAN280)";;
  dns)  DATOS="172.16.3.130/27  172.16.3.129 Servidor-DNS(Switch1-Fa0/3,VLAN240)";;
  http) DATOS="172.16.3.66/26   172.16.3.65  Servidor-HTTP(Switch3-Fa0/3,VLAN270)";;
  restaurar) DATOS="";;
  *)
    echo "Uso: sudo bash $0 {1..8|dns|http|restaurar}"
    echo "  1 PC1 Urgencias 172.16.2.10   2 PC2 Consulta 172.16.1.10"
    echo "  3 Hospitalizacion  4 Laboratorio  5 Farmacia  6 Imagenes"
    echo "  7 Administracion   8 Ing. biomedica   dns   http"
    exit 1;;
esac

# ---------- 2. Encontrar la tarjeta de red de CABLE ----------
# En /sys/class/net hay una carpeta por tarjeta. Una tarjeta fisica de
# cable tiene "device" (es hardware real) y NO tiene "wireless".
buscar_cable() {
  local mejor="" i
  for d in /sys/class/net/*; do
    i=$(basename "$d")
    [ -e "$d/device" ] || continue          # descarta lo virtual (lo, docker0, virbr0, veth...)
    [ -d "$d/wireless" ] && continue        # descarta el Wi-Fi
    [ -z "$mejor" ] && mejor=$i
    # si esta tiene el cable conectado (carrier=1), la preferimos
    ip link set "$i" up 2>/dev/null
    if [ "$(cat "$d/carrier" 2>/dev/null)" = "1" ]; then mejor=$i; break; fi
  done
  echo "$mejor"
}
sleep 1
IFACE=$(buscar_cable)
if [ -z "$IFACE" ]; then
  echo "[!] No encontre tarjeta de red de cable. Mira:  ip link"; exit 1
fi
TIENE_NM=0; command -v nmcli >/dev/null && systemctl is-active --quiet NetworkManager && TIENE_NM=1

# =====================================================================
#  MODO RESTAURAR: volver como estaba
# =====================================================================
if [ "${1}" = "restaurar" ]; then
  echo ">>> Restaurando $IFACE ..."
  if [ $TIENE_NM -eq 1 ]; then
    nmcli -t -f NAME con show | grep '^G3-' | while IFS= read -r c; do nmcli con delete "$c"; done
    nmcli -t -f NAME,TYPE con show | awk -F: '$2=="802-3-ethernet"{print $1}' | \
      while IFS= read -r c; do nmcli con mod "$c" connection.autoconnect yes; done
    nmcli radio wifi on || true
    nmcli dev connect "$IFACE" || true
  fi
  [ -f "$BK/nsswitch.conf" ] && cp "$BK/nsswitch.conf" /etc/nsswitch.conf
  if [ -L "$BK/resolv.conf.link" ] || [ -f "$BK/resolv.conf" ]; then
    rm -f /etc/resolv.conf
    if [ -f "$BK/resolv.target" ]; then ln -s "$(cat "$BK/resolv.target")" /etc/resolv.conf
    else cp "$BK/resolv.conf" /etc/resolv.conf; fi
  fi
  systemctl enable --now systemd-resolved 2>/dev/null || true
  echo ">>> Listo. El PC vuelve a DHCP y Wi-Fi."; exit 0
fi

read -r IP GW DESC <<< "$DATOS"
echo "================================================================"
echo " Configurando: $DESC"
echo " Tarjeta: $IFACE   IP: $IP   Gateway: $GW   DNS: $DNS"
echo "================================================================"

# ---------- 3. Revisar el cable (capa 1) ----------
if [ "$(cat /sys/class/net/$IFACE/carrier 2>/dev/null)" != "1" ]; then
  echo "[!] OJO: la tarjeta $IFACE NO detecta cable (sin link)."
  echo "    Revisa que el cable este en el puerto correcto del switch y que la luz del puerto prenda."
  echo "    Continuo igual; al conectar el cable la IP queda lista."
fi

# ---------- 4. Copias de seguridad (solo la primera vez) ----------
[ -f "$BK/nsswitch.conf" ] || cp /etc/nsswitch.conf "$BK/nsswitch.conf"
if [ ! -f "$BK/resolv.conf" ]; then
  cp -L /etc/resolv.conf "$BK/resolv.conf" 2>/dev/null || true
  [ -L /etc/resolv.conf ] && readlink /etc/resolv.conf > "$BK/resolv.target"
fi

# ---------- 5. Apagar Wi-Fi ----------
# Si el Wi-Fi sigue prendido el PC tiene DOS caminos y puede usar el equivocado.
if [ $TIENE_NM -eq 1 ]; then nmcli radio wifi off 2>/dev/null || true
else rfkill block wifi 2>/dev/null || true; fi

# ---------- 6. Poner la IP ----------
if [ $TIENE_NM -eq 1 ]; then
  # 6a. Desactivar y borrar perfiles viejos de ESTA tarjeta (los de otros grupos)
  #     Solo se borran los que dejamos nosotros (G3-*); los demas se desactivan.
  #     (se lee linea por linea porque los nombres tienen espacios: "Conexion cableada 1")
  nmcli -t -f NAME,DEVICE con show --active | awk -F: -v d="$IFACE" '$2==d{print $1}' | \
    while IFS= read -r c; do nmcli con down "$c" >/dev/null 2>&1; done
  nmcli -t -f NAME con show | grep '^G3-' | \
    while IFS= read -r c; do nmcli con delete "$c" >/dev/null 2>&1; done
  # Que los perfiles viejos de cable no se vuelvan a prender solos y nos quiten la IP
  nmcli -t -f NAME,TYPE con show | awk -F: '$2=="802-3-ethernet"{print $1}' | \
    while IFS= read -r c; do nmcli con mod "$c" connection.autoconnect no >/dev/null 2>&1; done
  # 6b. Crear nuestro perfil con IP fija
  #   ipv4.method manual  -> IP fija (no DHCP)
  #   ipv4.addresses      -> IP/prefijo
  #   ipv4.gateway        -> la subinterfaz del router de esa VLAN
  #   ipv4.dns            -> el servidor DNS del hospital
  #   ipv4.ignore-auto-dns-> no aceptar DNS de otro lado
  #   ipv6.method disabled-> sin IPv6 (la red del examen es solo IPv4)
  nmcli con add type ethernet ifname "$IFACE" con-name "G3-${1}" \
        ipv4.method manual ipv4.addresses "$IP" ipv4.gateway "$GW" \
        ipv4.dns "$DNS" ipv4.ignore-auto-dns yes ipv6.method disabled \
        connection.autoconnect yes >/dev/null
  ip addr flush dev "$IFACE"            # borra IPs viejas que hayan quedado
  nmcli con up "G3-${1}" >/dev/null || echo "[!] nmcli no pudo activar (normal si no hay cable)."
else
  # Sin NetworkManager (Ubuntu Server): con el comando ip (se pierde al reiniciar)
  ip addr flush dev "$IFACE"
  ip addr add "$IP" dev "$IFACE"
  ip link set "$IFACE" up
  ip route del default 2>/dev/null || true
  ip route add default via "$GW" dev "$IFACE"
fi

# ---------- 7. DNS del hospital ----------
# systemd-resolved hace de intermediario (127.0.0.53) y con ".local" falla.
# Dejamos /etc/resolv.conf apuntando directo al DNS del hospital.
rm -f /etc/resolv.conf
printf "# Red hospitalaria G3\nnameserver %s\n" "$DNS" > /etc/resolv.conf

# Ubuntu manda ".local" a mDNS (Avahi). Con "hosts: files dns" va al DNS.
sed -i 's/^hosts:.*/hosts:          files dns/' /etc/nsswitch.conf

# Si otro grupo dejo "www.hospital.local" en /etc/hosts, lo quitamos
sed -i '/hospital\.local/d' /etc/hosts

# ---------- 8. Proxy y firewall ----------
# Un proxy viejo hace que el navegador/curl no lleguen a la IP local
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
sed -i '/_proxy=/Id' /etc/environment 2>/dev/null || true
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow from 172.16.0.0/22 >/dev/null && echo ">>> Firewall ufw: permitido 172.16.0.0/22"
fi

# ---------- 9. Comprobar ----------
sleep 3
echo
echo ">>> Configuracion actual de $IFACE:"
ip -4 -br addr show "$IFACE"
ip route | grep default
echo
echo ">>> Ping al gateway $GW (la subinterfaz del router):"
if ping -c 4 -W 2 "$GW"; then
  echo ">>> OK: cable, puerto del switch, VLAN, trunk y subinterfaz funcionan."
else
  echo "[!] No responde el gateway. Revisa en este orden:"
  echo "    1) cable en el puerto correcto (ver tabla arriba)"
  echo "    2) en el switch: show vlan brief  (el puerto en la VLAN correcta)"
  echo "    3) en el switch: show interfaces trunk  (Gi0/1 trunk con la VLAN)"
  echo "    4) en el router: show ip interface brief  (subinterfaz up/up)"
  echo "    Tambien puedes correr:  sudo bash diagnostico.sh"
fi
