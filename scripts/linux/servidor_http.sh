#!/usr/bin/env bash
# =====================================================================
#  servidor_http.sh - Monta el servidor HTTP del Hospital G3 (Ubuntu)
#  IP: 172.16.3.66/26 (R8 Administracion, Switch3 Fa0/3, VLAN 270)
#
#  Uso: sudo bash servidor_http.sh "Grupo X" "Integrante1, Integrante2"
#  Si apache2 no esta instalado, usa el servidor web de Python.
# =====================================================================
set -e
GRUPO="${1:-Grupo __}"
INTEG="${2:-Completar integrantes}"

bash "$(dirname "$0")/configurar_pc_linux.sh" http || true

# Pagina que pide el examen: identificar grupo y red
PAGINA='<!doctype html><html lang="es"><head><meta charset="utf-8">
<title>Hospital G3</title>
<style>body{font-family:sans-serif;max-width:640px;margin:40px auto;line-height:1.5}
td,th{border:1px solid #999;padding:4px 8px}table{border-collapse:collapse}</style></head><body>
<h1>Red hospitalaria G3</h1>
<p><b>'"$GRUPO"'</b> &mdash; '"$INTEG"'</p>
<p>Universidad Libre &middot; Seccional Cali &middot; Redes de Computadores 2026-2</p>
<table><tr><th>Servidor</th><td>HTTP (www.hospital.local)</td></tr>
<tr><th>IP</th><td>172.16.3.66/26</td></tr>
<tr><th>Red</th><td>R8 Administracion &middot; VLAN 270 &middot; 172.16.3.64/26</td></tr>
<tr><th>Gateway</th><td>172.16.3.65 (Router3 Gi0/0.270)</td></tr>
<tr><th>DNS</th><td>172.16.3.130 (R4 Farmacia)</td></tr></table>
<p>Si ves esta pagina por nombre, funcionan: VLAN, 802.1Q, rutas estaticas, DNS y HTTP.</p>
</body></html>'

if command -v apache2 >/dev/null; then
  echo "$PAGINA" > /var/www/html/index.html
  systemctl enable apache2
  systemctl restart apache2
  echo ">>> Apache publicando /var/www/html/index.html en el puerto 80"
else
  mkdir -p /srv/hospital && echo "$PAGINA" > /srv/hospital/index.html
  echo ">>> Apache no esta instalado: uso Python. Deja esta terminal ABIERTA."
  cd /srv/hospital && python3 -m http.server 80 --bind 172.16.3.66
fi
