#!/usr/bin/env bash
# =====================================================================
#  servidor_dns.sh - Monta el servidor DNS del Hospital G3 (Ubuntu)
#  IP: 172.16.3.130/27 (R4 Farmacia, Switch1 Fa0/3, VLAN 240)
#  Registro A: www.hospital.local -> 172.16.3.66 (servidor HTTP)
#
#  Uso: sudo bash servidor_dns.sh
#  IMPORTANTE: instala dnsmasq ANTES, con internet:
#        sudo apt install -y dnsmasq dnsutils
# =====================================================================
set -e
command -v dnsmasq >/dev/null || { echo "[!] Falta dnsmasq: sudo apt install -y dnsmasq dnsutils"; exit 1; }

# 1) IP del servidor (reutiliza el script de PCs)
bash "$(dirname "$0")/configurar_pc_linux.sh" dns || true

# 2) systemd-resolved ocupa el puerto 53 (DNS) en 127.0.0.53 -> lo apagamos
systemctl disable --now systemd-resolved || true
rm -f /etc/resolv.conf
echo "nameserver 172.16.3.130" > /etc/resolv.conf

# 3) Configuracion de dnsmasq
cat > /etc/dnsmasq.d/hospital.conf <<'CONF'
# Escuchar solo en la IP del servidor
listen-address=172.16.3.130
bind-interfaces
# No reenviar consultas a internet (no hay internet en el laboratorio)
no-resolv
# REGISTRO A: nombre -> IPv4 del servidor HTTP
address=/www.hospital.local/172.16.3.66
# Registrar cada consulta en el log (sirve como evidencia)
log-queries
CONF

systemctl enable dnsmasq
systemctl restart dnsmasq
sleep 2

echo ">>> Prueba local del DNS:"
nslookup www.hospital.local 172.16.3.130
echo ">>> Ver consultas en vivo:  sudo journalctl -u dnsmasq -f"
