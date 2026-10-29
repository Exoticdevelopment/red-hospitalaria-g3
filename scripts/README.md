# Scripts

## Linux (Ubuntu) · `scripts/linux/`

| Script | Para qué | Uso |
|---|---|---|
| `preparar_con_internet.sh` | Instala todo **antes** del lab (luego no hay internet) | `sudo bash preparar_con_internet.sh` |
| `cisco_auto.py` | Configura un equipo Cisco por el cable de consola | `sudo python3 cisco_auto.py Switch0 [--borrar]` |
| | Solo guarda los `show` como evidencia | `sudo python3 cisco_auto.py Router0 --evidencia` |
| `configurar_pc_linux.sh` | IP de un PC o servidor | `sudo bash configurar_pc_linux.sh 1..8\|dns\|http` |
| | Deja el PC como estaba | `sudo bash configurar_pc_linux.sh restaurar` |
| `servidor_dns.sh` | Monta el DNS (dnsmasq) | `sudo bash servidor_dns.sh` |
| `mini_dns.py` | DNS de respaldo en Python (si no hay dnsmasq) | lo abre `servidor_dns.sh` solo |
| `servidor_http.sh` | Monta el servidor web (Apache o Python) | `sudo bash servidor_http.sh ["Grupo 3" "Nombres"]` |
| `recorrido_lan.sh` | Prueba de las LAN cambiando IPs, área por área, con evidencia | `sudo bash recorrido_lan.sh 2 6 7 8` |
| `diagnostico.sh` | Revisa capa por capa y dice dónde falla | `bash diagnostico.sh` |
| `pruebas.sh` | Pruebas finales que sirven de evidencia | `bash pruebas.sh \| tee evidencia.txt` |

## Windows · `scripts/windows/`

| Script | Para qué |
|---|---|
| `configurar_pc_windows.bat` | Doble clic → menú 1..8 para poner la IP · **R** para restaurar |
| `configurar_pc_windows.ps1` | El código real (lo abre el .bat como administrador) |
| `recorrido_windows.bat` / `.ps1` | Prueba de las LAN cambiando IPs, área por área, con evidencia |
| `diagnostico_windows.bat` / `.ps1` | Revisa capa por capa y dice dónde falla |
| `pruebas_windows.bat` | Pruebas finales que guardan `evidencia_<PC>.txt` |

## Qué arreglan solos en un PC que usaron otros
Wi-Fi prendido · otras tarjetas con gateway (VPN, VirtualBox) · IPs y DNS viejos · sufijo DNS · proxy del navegador · `hospital.local` en el archivo hosts · firewall que bloquea el ping · perfiles de red que se reactivan · `.local` mandado a mDNS (Ubuntu) · puertos 53/80 ocupados por otro servicio (servidores) · cable sin conectar (avisa).

Todo lo que cambian queda respaldado en `/root/g3_backup` (Linux) o `C:\G3_backup` (Windows).

👉 Explicación detallada: [docs/06](../docs/06_pcs_windows_y_linux.md) y [docs/07](../docs/07_servidores_dns_y_http.md).
