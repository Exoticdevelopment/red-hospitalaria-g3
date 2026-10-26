# 03 · Cableado y consola

## Lo que hay en la mesa

| Equipo | Cantidad | Modelo |
|---|---|---|
| Routers | 4 | Cisco 2901 (Router0 a Router3) |
| Switches | 5 | Catalyst 2960 (Switch0 a Switch3 + Switch4 central) |
| Cable de consola | 1 | USB a RJ-45 (azul o negro) |
| Cables de red | 12+ | Directos (normales). **No hacen falta cruzados**: los equipos tienen auto-MDIX |
| PCs/servidores | 4 | 2 PCs + DNS + HTTP |

## Conocer los puertos

**Switch 2960:** a la izquierda hay **24 puertos FastEthernet** (Fa0/1 a Fa0/24). A la derecha hay **2 puertos Gigabit** (Gi0/1 y Gi0/2).

> ⚠️ **Trampa:** el switch tiene **dos puertos "1"**: **Fa0/1** (izquierda, para PCs) y **Gi0/1** (derecha, para el router). Confundirlos fue uno de nuestros errores.

**Router 2901:** atrás tiene **Gi0/0** y **Gi0/1** (los dos de red), el puerto **CONSOLE** (azul) y el puerto **AUX** (no se usa).

## Tabla de cableado

| Desde | Puerto | Hacia | Puerto | Tipo de enlace |
|---|---|---|---|---|
| Router0 | Gi0/0 | Switch0 | Gi0/1 | Trunk (VLAN 210, 220) |
| Router1 | Gi0/0 | Switch1 | Gi0/1 | Trunk (VLAN 230, 240) |
| Router2 | Gi0/0 | Switch2 | Gi0/1 | Trunk (VLAN 250, 260) |
| Router3 | Gi0/0 | Switch3 | Gi0/1 | Trunk (VLAN 270, 280) |
| Router0 | Gi0/1 | Switch4 | Fa0/1 | Tránsito R5 |
| Router1 | Gi0/1 | Switch4 | Fa0/2 | Tránsito R5 |
| Router2 | Gi0/1 | Switch4 | Fa0/3 | Tránsito R5 |
| Router3 | Gi0/1 | Switch4 | Fa0/4 | Tránsito R5 |
| PC1 (Windows) | tarjeta de red | Switch0 | Fa0/1 | Access VLAN 210 |
| PC2 (Ubuntu) | tarjeta de red | Switch2 | Fa0/1 | Access VLAN 250 |
| Servidor DNS | tarjeta de red | Switch1 | Fa0/3 | Access VLAN 240 |
| Servidor HTTP | tarjeta de red | Switch3 | Fa0/3 | Access VLAN 270 |

**Regla fácil de recordar:**
- El **RouterN** va a su **SwitchN** (mismo número) por los **Gigabit** (Gi0/0 → Gi0/1).
- El **RouterN** va al **Switch4** en el puerto **Fa0/(N+1)**: Router0 → Fa0/1, Router3 → Fa0/4.

## Las luces (LEDs)

| Luz | Significa |
|---|---|
| SYST/SYS verde fijo | El equipo terminó de arrancar |
| SYST ámbar o parpadeando | Está arrancando o tiene un error (espera 3 min) |
| Puerto verde | Hay cable y conexión |
| Puerto ámbar | El puerto está bloqueado por STP (unos 30 s; con portfast se salta) |
| Puerto apagado | No hay cable, el otro lado está apagado o el puerto tiene `shutdown` |

## Conectarse a la consola desde Ubuntu

La consola es la "pantalla" del equipo Cisco. Se usa el cable USB-consola y el programa **picocom**.

```bash
sudo bash scripts/linux/preparar_con_internet.sh   # una sola vez, con internet (instala picocom y más)
ls /dev/ttyUSB*                                    # debe salir /dev/ttyUSB0 = el cable de consola
sudo picocom -b 9600 --flow n /dev/ttyUSB0         # abre la consola
```

| Parte del comando | Qué significa |
|---|---|
| `sudo` | Como administrador (el puerto USB es del sistema) |
| `picocom` | El programa de terminal serial |
| `-b 9600` | Velocidad: 9600 baudios (la de fábrica en Cisco) |
| `--flow n` | Sin control de flujo |
| `/dev/ttyUSB0` | El cable de consola |
| `--logfile X.txt` | (opcional) guarda todo lo que sale en un archivo: sirve de **evidencia** |

- **Salir de picocom:** `Ctrl+A` y luego `Ctrl+X`.
- Al conectar, presiona **Enter** un par de veces para que aparezca el prompt (`Switch0>`).

### Problemas típicos de la consola

| Síntoma | Solución |
|---|---|
| `FATAL: cannot lock /dev/ttyUSB0` | Ya hay otro picocom abierto: `sudo pkill picocom`. Si sigue: `sudo rm -f /run/lock/LCK..ttyUSB0` |
| Letras perdidas o repetidas (`eennaable`) | Hay **dos programas** usando el puerto: `sudo lsof /dev/ttyUSB0`, cierra los demás y para ModemManager (`sudo systemctl stop ModemManager`) |
| No aparece `/dev/ttyUSB0` | Desconecta y conecta el USB; si `dmesg` menciona **brltty**: `sudo apt remove brltty` |
| Pantalla en blanco | Presiona Enter. Si sigue: el equipo puede estar arrancando (mira la luz SYST) |
| Salen cosas raras como `Invalid input` sin parar | Pegaste texto con clic derecho dentro de la consola. **No hagas clic dentro de picocom** |

## Conectarse a la consola desde Windows

1. Instala el driver del cable (si Windows no lo reconoce solo).
2. En **Administrador de dispositivos → Puertos (COM y LPT)** mira el número (por ejemplo, COM3).
3. Abre **PuTTY** → Connection type: **Serial** → Serial line: `COM3` → Speed: `9600` → Open.

## Los modos del IOS (el sistema de Cisco)

```
Switch0>                 ← modo USUARIO: solo mirar un poco
Switch0> enable
Switch0#                 ← modo PRIVILEGIADO: ver todo, guardar, borrar
Switch0# configure terminal
Switch0(config)#         ← modo CONFIGURACIÓN GLOBAL: cambiar el equipo
Switch0(config)# interface fa0/1
Switch0(config-if)#      ← configurar UN puerto
Switch0(config-if)# exit     ← sube un nivel
Switch0(config)# end         ← vuelve directo a #
```

**Mira siempre el prompt** antes de escribir: te dice en qué equipo y en qué modo estás.

### Atajos útiles
| Tecla | Hace |
|---|---|
| `?` | Muestra qué comandos existen en ese punto |
| `Tab` | Completa el comando (`conf` + Tab → `configure`) |
| Flecha arriba | Repite el comando anterior |
| `Ctrl+C` / `Ctrl+Shift+6` | Cancela algo que se quedó pegado |
| `do <comando>` | Corre un comando de `#` estando en `(config)#` (ej. `do show vlan brief`) |

Los comandos se pueden abreviar: `conf t` = `configure terminal`, `int gi0/1` = `interface GigabitEthernet0/1`, `sh run` = `show running-config`.
