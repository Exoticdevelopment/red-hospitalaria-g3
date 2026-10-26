# 05 · Pruebas finales y evidencias (entregable D)

## Matriz mínima
| # | Desde | Prueba | Esperado | Captura |
|---|---|---|---|---|
| 1 | Cada router | `show ip interface brief` | Gi0/0.x y Gi0/1 up/up | ☐ |
| 2 | Cada switch acceso | `show vlan brief` / `show interfaces trunk` | VLAN y trunk OK | ☐ |
| 3 | Router0 | `ping 172.16.3.194/.195/.196` | !!!!! | ☑ |
| 4 | Cada router | `show ip route` | 3 C + 6 S | ☑ |
| 5 | PC1 | `ping 172.16.2.1` | responde | ☐ |
| 6 | PC1 | `ping 172.16.1.10` (PC2) | responde | ☐ |
| 7 | PC1 | `ping 172.16.3.130` / `172.16.3.66` | responde | ☐ |
| 8 | PC1 | `nslookup www.hospital.local` | 172.16.3.66 | ☐ |
| 9 | PC1 | navegador `http://www.hospital.local` | página G3 | ☐ |
| 10 | PC1 | `traceroute 172.16.3.66` | .1 → .196 → .66 | ☐ |
| 11 | Todos | `show startup-config` | guardado | ☐ |

## Cómo capturar
- Ubuntu: `bash scripts/linux/pruebas.sh | tee evidencia_PC1.txt` + captura de pantalla del navegador (`Impr Pant`).
- Windows: `pruebas_windows.bat` (genera `evidencia_<PC>.txt`).
- Cisco: `picocom --logfile <equipo>.txt` y luego `show running-config`.

En cada captura debe verse: **equipo, comando y resultado**. No presentar resultados esperados como si fueran reales.

## Diagnóstico rápido
| Síntoma | Revisar en orden |
|---|---|
| PC no llega a su gateway | IP/máscara → cable → `show vlan brief` (puerto en VLAN correcta) → trunk permitido → subinterfaz dot1Q |
| Llega al gateway, no a otra LAN | Gi0/1 up → ping en R5 → `show ip route` (S presente) → ruta de retorno en el otro router |
| Ping OK, nombre no | DNS del cliente = 172.16.3.130 → ping al DNS → dnsmasq activo → `nsswitch.conf` |
| Resuelve, pero no abre la web | ping al HTTP → apache activo → URL con `http://` |
| Windows no responde ping | Firewall: regla ICMP (`configurar_pc_windows.bat` la crea) |
