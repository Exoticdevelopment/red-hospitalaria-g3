#!/usr/bin/env bash
# =====================================================================
#  preparar_con_internet.sh  -  Instala TODO lo necesario ANTES del lab
#
#  POR QUE: cuando el PC queda conectado a la red del hospital (172.16.x.x)
#  ya NO tiene internet, y "apt install" falla. Por eso se instala antes,
#  con el Wi-Fi o el cable normal de la universidad.
#
#  USO:  sudo bash preparar_con_internet.sh
# =====================================================================
if [ "$(id -u)" -ne 0 ]; then echo "[!] Ejecuta con sudo"; exit 1; fi

echo ">>> Probando internet..."
if ! ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
  echo "[!] No hay internet. Conecta el Wi-Fi o el cable de la universidad y repite."
  exit 1
fi

# Paquetes y para que sirve cada uno:
#   picocom        -> abrir la consola de los equipos Cisco
#   python3-serial -> lo usa cisco_auto.py para hablar por el cable de consola
#   dnsmasq        -> servidor DNS (solo en el PC que hara de DNS)
#   dnsutils       -> trae nslookup y dig (para probar el DNS)
#   apache2        -> servidor web (solo en el PC que hara de HTTP)
#   curl           -> pedir la pagina web desde la terminal
#   traceroute     -> ver por que routers pasa un paquete
#   net-tools      -> trae ifconfig/netstat (por si el profe los pide)
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  picocom python3-serial dnsmasq dnsutils apache2 curl traceroute net-tools

# dnsmasq y apache2 arrancan solos al instalarse y pueden chocar con otros
# servicios. Los dejamos APAGADOS; los scripts de servidor los prenden.
systemctl disable --now dnsmasq apache2 2>/dev/null || true

# brltty (lector braille) "roba" los adaptadores USB-serie de consola
apt remove -y brltty 2>/dev/null || true
# ModemManager tambien toca los /dev/ttyUSB* y mete basura en la consola
systemctl disable --now ModemManager 2>/dev/null || true

echo
echo ">>> LISTO. Instalado:"
for p in picocom dnsmasq nslookup apache2 curl traceroute; do
  command -v $p >/dev/null || [ -x /usr/sbin/$p ] && echo "   [OK] $p" || echo "   [--] $p"
done
python3 -c "import serial" 2>/dev/null && echo "   [OK] python3-serial"
echo
echo ">>> Ahora si: desconecta el Wi-Fi, conecta el cable al switch y corre el script de tu rol."
