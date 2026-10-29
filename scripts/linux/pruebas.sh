#!/usr/bin/env bash
# =====================================================================
#  pruebas.sh - Pruebas finales desde un PC cliente (genera evidencia)
#  Uso: bash pruebas.sh | tee evidencia_$(hostname).txt
# =====================================================================
GW=$(ip route | awk '/default/{print $3; exit}')
ok(){ ping -c 3 -W 2 "$1" >/dev/null 2>&1 && echo "  [OK]    $2 ($1)" || echo "  [FALLA] $2 ($1)"; }

echo "===== $(date)  |  equipo: $(hostname) ====="
ip -4 -br addr | grep -v '^lo'
echo "Gateway: $GW"
echo; echo "--- Conectividad (capas 1-3) ---"
ok "$GW"          "Gateway propio (subinterfaz del router)"
echo; echo "--- Los 8 gateways (las 8 LAN) ---"
ok 172.16.2.1     "R1 Urgencias       (Router0 Gi0/0.210)"
ok 172.16.0.1     "R2 Hospitalizacion (Router0 Gi0/0.220)"
ok 172.16.3.1     "R3 Laboratorio     (Router1 Gi0/0.230)"
ok 172.16.3.129   "R4 Farmacia        (Router1 Gi0/0.240)"
ok 172.16.1.1     "R6 Consulta        (Router2 Gi0/0.250)"
ok 172.16.2.129   "R7 Imagenes        (Router2 Gi0/0.260)"
ok 172.16.3.65    "R8 Administracion  (Router3 Gi0/0.270)"
ok 172.16.3.161   "R9 Ing. biomedica  (Router3 Gi0/0.280)"
echo; echo "--- Routers y servidores ---"
ok 172.16.3.193   "Router0 en R5"
ok 172.16.3.194   "Router1 en R5"
ok 172.16.3.195   "Router2 en R5"
ok 172.16.3.196   "Router3 en R5"
ok 172.16.3.130   "Servidor DNS (R4)"
ok 172.16.3.66    "Servidor HTTP (R8)"
ok 172.16.2.10    "PC1 Urgencias (R1)"
ok 172.16.1.10    "PC2 Consulta (R6)"
echo; echo "--- DNS (capa 7, UDP 53) ---"
nslookup www.hospital.local 172.16.3.130 || echo "  [FALLA] nslookup"
echo; echo "--- HTTP por nombre (capa 7, TCP 80) ---"
curl -s -m 5 --noproxy '*' http://www.hospital.local | grep -o '<h1>.*</h1>' || echo "  [FALLA] HTTP por nombre"
echo; echo "--- Camino hasta el HTTP ---"
command -v traceroute >/dev/null && traceroute -n -m 5 172.16.3.66 || tracepath -n 172.16.3.66
