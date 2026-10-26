#!/usr/bin/env bash
# =====================================================================
#  servidor_http.sh  -  Monta el servidor web del hospital (Ubuntu)
#
#  IP: 172.16.3.66/26  ->  R8 Administracion, VLAN 270, Switch3 Fa0/3
#
#  USO:
#    sudo bash servidor_http.sh
#    sudo bash servidor_http.sh "Grupo 3" "Nombre1, Nombre2, Nombre3"
#    (OJO: los integrantes van TODOS dentro de UNAS SOLAS comillas)
#
#  Pensado para un PC que otros usaron:
#   - libera el puerto 80 (nginx, lighttpd, otro Python...)
#   - guarda una copia de la pagina que habia antes
#   - abre el firewall (ufw) para el puerto 80
#   - si apache2 no esta y no hay internet -> usa el servidor web de Python
# =====================================================================
set -u
if [ "$(id -u)" -ne 0 ]; then echo "[!] Ejecuta con sudo"; exit 1; fi
DIR="$(cd "$(dirname "$0")" && pwd)"
IP=172.16.3.66
GRUPO="${1:-Grupo 3}"
INTEG="${2:-Miguel Gonzalez, Pablo Arango, Daniel Celis, Julio Guachene, Herlyn Jhoan}"

# ---------- 1. IP del servidor ----------
bash "$DIR/configurar_pc_linux.sh" http

# ---------- 2. Liberar el puerto 80 ----------
# Solo un programa puede usar el puerto 80 a la vez.
echo ">>> Liberando el puerto 80..."
for s in nginx lighttpd caddy httpd; do
  systemctl disable --now "$s" 2>/dev/null && echo "    apagado: $s" || true
done
pkill -f "http.server" 2>/dev/null || true

# ---------- 3. Firewall ----------
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow 80/tcp >/dev/null && echo ">>> ufw: abierto el puerto 80"
fi

# ---------- 4. La pagina que pide el examen (identifica grupo y red) ----------
PAGINA=$(cat <<HTML
<!doctype html><html lang="es"><head><meta charset="utf-8"><title>Hospital G3</title>
<style>body{font-family:sans-serif;max-width:680px;margin:40px auto;line-height:1.5;padding:0 16px}
td,th{border:1px solid #999;padding:4px 10px;text-align:left}table{border-collapse:collapse}</style></head><body>
<h1>Red hospitalaria G3</h1>
<p><b>$GRUPO</b> &mdash; $INTEG</p>
<p>Universidad Libre &middot; Seccional Cali &middot; Redes de Computadores 2026-2</p>
<table>
<tr><th>Servidor</th><td>HTTP (www.hospital.local)</td></tr>
<tr><th>IP</th><td>172.16.3.66/26</td></tr>
<tr><th>Red</th><td>R8 Administracion &middot; VLAN 270 &middot; 172.16.3.64/26</td></tr>
<tr><th>Gateway</th><td>172.16.3.65 (Router3 Gi0/0.270)</td></tr>
<tr><th>DNS</th><td>172.16.3.130 (R4 Farmacia)</td></tr>
</table>
<p>Si ves esta pagina por nombre, funcionan: VLAN, 802.1Q, rutas estaticas, DNS y HTTP.</p>
</body></html>
HTML
)

# ---------- 5. Publicar ----------
if ! command -v apache2 >/dev/null && ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
  apt install -y apache2
fi

if command -v apache2 >/dev/null; then
  # Copia de la pagina anterior (de otro grupo o la de bienvenida de Apache)
  mkdir -p /root/g3_backup
  [ -f /var/www/html/index.html ] && cp -n /var/www/html/index.html /root/g3_backup/index.html.antes
  echo "$PAGINA" > /var/www/html/index.html
  systemctl enable apache2 >/dev/null 2>&1
  systemctl restart apache2
  sleep 1
  echo ">>> Apache publicando /var/www/html/index.html en el puerto 80"
  ss -ltnp | grep ":80 " || echo "[!] Nadie escucha en el puerto 80"
  echo ">>> Prueba local:"
  curl -s --noproxy '*' http://$IP | grep -o "<h1>.*</h1>"
else
  # Plan B: servidor web que trae Python (no hay que instalar nada)
  mkdir -p /srv/hospital && echo "$PAGINA" > /srv/hospital/index.html
  echo ">>> Apache no esta instalado y no hay internet: uso Python."
  echo ">>> Deja ESTA terminal abierta mientras dure el examen."
  cd /srv/hospital && exec python3 -m http.server 80 --bind $IP
fi
