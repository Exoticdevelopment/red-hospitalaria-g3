# 02 · Guía del laboratorio físico (paso a paso)

## Inventario
4 routers Cisco 2901 · 5 switches Catalyst 2960‑24TT‑L · 1 cable de consola USB · cables directos (no hacen falta cruzados: auto‑MDIX) · 2 servidores + 2 PCs.

## 1. Cableado
| Desde | Hacia |
|---|---|
| RouterN **Gi0/0** | **Gi0/1** (puerto Gigabit "1" de la derecha) de SwitchN |
| Router0 Gi0/1 | Switch4 Fa0/1 |
| Router1 Gi0/1 | Switch4 Fa0/2 |
| Router2 Gi0/1 | Switch4 Fa0/3 |
| Router3 Gi0/1 | Switch4 Fa0/4 |
| PCs | Fa0/1 y Fa0/2 (bloque de 24, izquierda) |
| DNS | Switch1 Fa0/3 |
| HTTP | Switch3 Fa0/3 |

⚠️ El switch tiene **dos puertos "1"**: Fa0/1 (izquierda, PCs) y Gi0/1 (derecha, router).

**Verificar con:** `show cdp neighbors` en cada router.

## 2. Consola desde Ubuntu
```bash
ls /dev/ttyUSB*                              # debe aparecer ttyUSB0
sudo systemctl stop ModemManager             # interfiere con adaptadores USB-serie
sudo lsof /dev/ttyUSB0                       # NO debe haber otro programa usando el puerto
sudo picocom -b 9600 --flow n /dev/ttyUSB0   # salir: Ctrl+A, Ctrl+X
```
- Si `dmesg` menciona **brltty**: `sudo apt remove brltty`.
- Nunca dejar abiertos `screen` y `picocom` a la vez (letras duplicadas/perdidas).
- No hacer clic dentro de la ventana (clic derecho/medio pega texto).

## 3. Borrar configuraciones viejas
```
enable
write erase          (Enter en [confirm])
delete flash:vlan.dat   (Enter, Enter — solo switches)
reload               ("Save?" → no; [confirm] → Enter)
```
Al arrancar: **"initial configuration dialog?" → escribir `no`** (no presionar solo Enter).

## 4. Configurar
Por equipo, pegar `configs/<Equipo>.ios` una línea a la vez, **o**:
```bash
sudo python3 scripts/linux/cisco_auto.py Switch2 --borrar
sudo python3 scripts/linux/cisco_auto.py Router2         # routers sin --borrar
```

## 5. Verificar (en orden de capas)
| Capa | Comando | Esperado |
|---|---|---|
| 1 | `show cdp neighbors` | cada cable en su puerto |
| 2 | `show vlan brief` | PCs en su VLAN |
| 2 | `show interfaces trunk` | Gi0/1 trunking con 2 VLAN |
| 3 | `show ip interface brief` | subinterfaces y Gi0/1 up/up |
| 3 | `show ip route` | 3 C + 6 S |
| 3 | `ping 172.16.3.193..196` | los 4 routers responden |
| — | `show version \| include register` | 0x2102 |

## 6. PCs y servidores
Ver `README.md` sección *Uso rápido* y `docs/05`.

## 7. Guardar evidencia de configuraciones (entregable B)
En cada equipo, con picocom grabando a archivo:
```bash
sudo picocom -b 9600 --flow n --logfile Router0_running.txt /dev/ttyUSB0
```
Luego en el equipo: `terminal length 0` y `show running-config`.
