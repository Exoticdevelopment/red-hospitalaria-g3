# Evidencias · entregables B y D

Salidas reales de los equipos del laboratorio (26-oct-2026), grabadas con `picocom --logfile`.

| Archivo | Comandos que contiene | Qué demuestra |
|---|---|---|
| `Router0_evidencia.txt` … `Router3_evidencia.txt` | `show cdp neighbors`, `show ip interface brief`, `show ip route`, `show running-config` | Cableado, subinterfaces up/up, 3 C + 6 S |
| `Switch0_evidencia.txt` … `Switch3_evidencia.txt` | `show vlan brief`, `show running-config` | VLAN por puerto y trunk 802.1Q |
| `Switch4_evidencia.txt` | `show vlan brief`, `show running-config` | Switch central solo con VLAN 1 |

Las capturas de las pruebas desde los PCs (página web, nslookup, ping, tracert) están en [`../informe/Informe_Red_Hospitalaria_G3.pdf`](../informe/).

**Para volver a sacarlas:** `sudo python3 scripts/linux/cisco_auto.py <Equipo> --evidencia` (ver [docs/08](../docs/08_pruebas_y_evidencias.md)).
