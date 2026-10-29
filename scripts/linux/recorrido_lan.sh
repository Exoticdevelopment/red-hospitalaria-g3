#!/usr/bin/env bash
# =====================================================================
#  recorrido_lan.sh  -  La prueba que pidio el profesor:
#  "con los PCs, cambiando las IPs, probar todas las LAN"
#
#  El PC va VISITANDO las areas una por una. En cada una:
#   1) te dice a que puerto del switch mover el cable y espera Enter
#   2) cambia la IP a la de esa area (usa configurar_pc_linux.sh)
#   3) prueba: gateway, routers, DNS, HTTP por nombre
#   4) guarda la evidencia en evidencias_recorrido/<area>.txt
#  Al final muestra un resumen y te deja en el area que elijas.
#
#  USO:
#    sudo bash recorrido_lan.sh              -> las 8 areas
#    sudo bash recorrido_lan.sh 2 6 7 8      -> solo esas (ej. PC2)
#    sudo bash recorrido_lan.sh 1 3 4 5      -> (ej. PC1 si es Ubuntu)
# =====================================================================
set -u
if [ "$(id -u)" -ne 0 ]; then echo "[!] Ejecuta con sudo"; exit 1; fi
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/../../evidencias/recorrido_$(hostname)"
mkdir -p "$OUT"

# opcion -> "AREA  PUERTO  IP  GATEWAY"
declare -A A=(
  [1]="R1_Urgencias        Switch0_Fa0/1  172.16.2.10   172.16.2.1"
  [2]="R6_Consulta         Switch2_Fa0/1  172.16.1.10   172.16.1.1"
  [3]="R2_Hospitalizacion  Switch0_Fa0/2  172.16.0.10   172.16.0.1"
  [4]="R3_Laboratorio      Switch1_Fa0/1  172.16.3.10   172.16.3.1"
  [5]="R4_Farmacia         Switch1_Fa0/2  172.16.3.138  172.16.3.129"
  [6]="R7_Imagenes         Switch2_Fa0/2  172.16.2.138  172.16.2.129"
  [7]="R8_Administracion   Switch3_Fa0/1  172.16.3.74   172.16.3.65"
  [8]="R9_Ing_Biomedica    Switch3_Fa0/2  172.16.3.170  172.16.3.161"
)
LISTA=("$@"); [ ${#LISTA[@]} -eq 0 ] && LISTA=(1 3 4 5 2 6 7 8)
p(){ ping -c 2 -W 2 "$1" >/dev/null 2>&1; }
RES=()

for n in "${LISTA[@]}"; do
  [ -n "${A[$n]:-}" ] || { echo "[!] Opcion $n no existe (1..8)"; continue; }
  read -r AREA PUERTO IP GW <<< "${A[$n]}"
  echo
  echo "################################################################"
  echo "  AREA $n: $AREA"
  echo "  1) Mueve el cable de este PC a:  ${PUERTO/_/ }"
  echo "  2) Presiona Enter cuando este conectado (o escribe s para saltar)"
  echo "################################################################"
  read -r r </dev/tty; [ "$r" = "s" ] && { RES+=("$AREA|saltada"); continue; }

  F="$OUT/$n-$AREA.txt"
  {
    echo "===== $(date)  |  $(hostname)  |  $AREA  |  $PUERTO ====="
    bash "$DIR/configurar_pc_linux.sh" "$n" | grep -v "^>>> Ping al gateway"
    echo; echo "--- Pruebas desde $AREA ($IP) ---"
    G=FALLA; p "$GW" && G=OK;            echo "Gateway $GW : $G"
    for r in 172.16.3.193 172.16.3.194 172.16.3.195 172.16.3.196; do
      p $r && echo "Router R5 $r : OK" || echo "Router R5 $r : FALLA"; done
    D=FALLA; nslookup www.hospital.local 172.16.3.130 2>/dev/null | grep -q "172.16.3.66" && D=OK
    echo "DNS www.hospital.local : $D"
    H=FALLA; curl -s -m 5 --noproxy '*' http://www.hospital.local | grep -qi hospital && H=OK
    echo "HTTP por nombre : $H"
    echo "--- Camino al servidor web ---"
    (command -v traceroute >/dev/null && traceroute -n -m 5 172.16.3.66) || tracepath -n 172.16.3.66
    echo "RESUMEN|$G|$D|$H"
  } 2>&1 | tee "$F"
  L=$(grep "^RESUMEN" "$F" | tail -1)
  RES+=("$AREA|${L#RESUMEN|}")
done

echo
echo "======================== RESUMEN DEL RECORRIDO ========================"
printf "%-22s %-9s %-6s %-6s\n" "AREA" "GATEWAY" "DNS" "HTTP"
for r in "${RES[@]}"; do IFS='|' read -r a g d h <<< "$r"; printf "%-22s %-9s %-6s %-6s\n" "$a" "$g" "${d:-}" "${h:-}"; done
echo "Evidencias guardadas en: $OUT"
echo
read -r -p "Numero del area donde dejar el PC al final (Enter = no cambiar): " FIN </dev/tty
[ -n "$FIN" ] && bash "$DIR/configurar_pc_linux.sh" "$FIN" >/dev/null && echo "PC dejado en la opcion $FIN (mueve el cable a ese puerto)."
