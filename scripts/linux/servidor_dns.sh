#!/usr/bin/env bash
# =====================================================================
#  servidor_dns.sh  -  Monta el servidor DNS del hospital (Ubuntu)
#
#  IP: 172.16.3.130/27  ->  R4 Farmacia, VLAN 240, Switch1 Fa0/3
#  Registro A:  www.hospital.local  ->  172.16.3.66  (el servidor HTTP)
#
#  USO:  sudo bash servidor_dns.sh
#
#  Pensado para un PC que otros usaron:
#   - libera el puerto 53 (systemd-resolved, bind9, otro dnsmasq)
#   - aparta configuraciones viejas de dnsmasq de otros grupos
#   - abre el firewall (ufw) para el puerto 53
#   - si dnsmasq NO esta instalado y no hay internet -> usa mini_dns.py
# =====================================================================
set -u
if [ "$(id -u)" -ne 0 ]; then echo "[!] Ejecuta con sudo"; exit 1; fi
DIR="$(cd "$(dirname "$0")" && pwd)"
IP=172.16.3.130

# ---------- 1. Poner la IP del servidor ----------
bash "$DIR/configurar_pc_linux.sh" dns

# ---------- 2. Liberar el puerto 53 ----------
# Solo UN programa puede escuchar en el puerto 53. En Ubuntu normalmente
# lo ocupa systemd-resolved (127.0.0.53). Otros grupos pudieron dejar bind9.
echo ">>> Liberando el puerto 53..."
for s in systemd-resolved bind9 named; do
  systemctl disable --now "$s" 2>/dev/null && echo "    apagado: $s" || true
done
systemctl stop dnsmasq 2>/dev/null || true
pkill -f mini_dns.py 2>/dev/null || true
printf "nameserver %s\n" "$IP" > /etc/resolv.conf     # el servidor se pregunta a si mismo

# ---------- 3. Abrir firewall ----------
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 53 >/dev/null && echo ">>> ufw: abierto el puerto 53"
fi

# ---------- 4a. Sin dnsmasq: plan B con Python ----------
if ! command -v dnsmasq >/dev/null; then
  echo "[!] dnsmasq no esta instalado."
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    apt install -y dnsmasq dnsutils
  else
    echo ">>> Sin internet: uso el DNS de respaldo en Python (mini_dns.py)."
    echo ">>> Deja ESTA terminal abierta mientras dure el examen."
    exec python3 "$DIR/mini_dns.py"
  fi
fi

# ---------- 4b. Configurar dnsmasq ----------
# Apartar configuraciones de otros grupos (no se borran, se mueven)
mkdir -p /root/g3_backup/dnsmasq.d
for f in /etc/dnsmasq.d/*; do
  [ -e "$f" ] || continue
  case "$(basename "$f")" in hospital.conf|README) ;; *) mv "$f" /root/g3_backup/dnsmasq.d/ && echo "    apartado: $f";; esac
done

cat > /etc/dnsmasq.d/hospital.conf <<CONF
# ---- DNS de la red hospitalaria G3 ----
# listen-address : solo responde en la IP del servidor
listen-address=$IP
# bind-interfaces: se "amarra" solo a esa IP (no choca con otros servicios)
bind-interfaces
# no-resolv      : no lee /etc/resolv.conf ni pregunta a internet (no hay)
no-resolv
# address=       : el REGISTRO A. Nombre -> IPv4 del servidor HTTP
address=/www.hospital.local/172.16.3.66
# log-queries    : anota cada pregunta (sirve de evidencia)
log-queries
CONF

# Probar que el archivo no tenga errores antes de arrancar
dnsmasq --test || { echo "[!] Error en la configuracion de dnsmasq"; exit 1; }
systemctl enable dnsmasq >/dev/null 2>&1
systemctl restart dnsmasq
sleep 2

# ---------- 5. Verificar ----------
echo
echo ">>> Quien escucha en el puerto 53:"
ss -lunp | grep ":53 " || echo "[!] Nadie escucha en el 53"
echo
echo ">>> Prueba local:"
nslookup www.hospital.local $IP
echo "(El 'REFUSED' de la pregunta AAAA/IPv6 es normal: la red es solo IPv4)"
echo
echo ">>> Ver las consultas en vivo (evidencia):  sudo journalctl -u dnsmasq -f"
