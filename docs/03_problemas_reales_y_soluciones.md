# 03 · Problemas reales del laboratorio y cómo se resolvieron

Bitácora de lo que pasó el 26‑oct‑2026. **El docente suele preguntar "¿qué harías si…?"**: estos casos son la mejor respuesta.

| # | Síntoma | Causa | Solución |
|---|---|---|---|
| 1 | Consola en blanco con `screen` | Switch arrancando / sin Enter | Presionar Enter; revisar LED SYST verde |
| 2 | Letras perdidas y duplicadas (`eeennnaable`, `se`ret`) | **3 programas** leyendo `/dev/ttyUSB0` (2 `screen` + `picocom`) | `sudo lsof /dev/ttyUSB0`, `kill` los procesos, `systemctl stop ModemManager`, abrir solo picocom |
| 3 | Errores en bucle "Invalid input" | Se **pegó en la consola** el texto de la propia consola (clic derecho) | No hacer clic dentro de picocom; pegar una línea a la vez |
| 4 | Prompt `SW-LAB`, `S1`, `S2`, `R1`, `R2` | Configuración de otros grupos | `write erase` + `delete flash:vlan.dat` + `reload` |
| 5 | Tras `reload` sigue el nombre viejo | Al pegar todo junto, la línea siguiente "respondió" el `[confirm]` | Escribir comando por comando y esperar el prompt |
| 6 | Se entró al asistente inicial y guardó contraseñas `cisco` | Se presionó Enter / `yes` en "initial configuration dialog" | `enable` (cisco) → `no enable secret`, `no enable password`, `line vty 0 15` → `no password` |
| 7 | Se ejecutó `write erase` en el switch equivocado | El cable de consola seguía en Switch0 | Como la running‑config seguía en RAM: `copy running-config startup-config`. **Siempre mirar el prompt antes de borrar** |
| 8 | Routers en bucle infinito `ROMMON initialized` | Reinicio con la consola USB conectada / tiempo de arranque | Desconectar consola, apagar/encender, esperar 3 min a SYS **verde fijo**, conectar consola, configurar **sin `--borrar`** |
| 9 | `enable` pedía contraseña; el script fallaba | Script usaba la misma lista de claves para login de consola y para enable | Corregido en `cisco_auto.py` (lista nueva para enable) |
| 10 | `STARTUP_CONFIG_IGNORED` en Router2 | `config-register 0x2142` (modo recuperación) | `config-register 0x2102` + `copy run start` |
| 11 | Ping a .193 y .194 fallaba, a .196 funcionaba | Router0 Gi0/1 conectado a **Switch2 Fa0/1** (un compañero conectó el Switch2 como si fuera el central) | `show cdp neighbors` lo reveló; se movió el cable a **Switch4 Fa0/1** |
| 12 | Router2 Gi0/0 → Switch3 y Router3 Gi0/0 → Switch2 | Cables de trunk intercambiados | Intercambiar los dos cables en los Gigabit 1 de Switch2/Switch3 |
| 13 | Escribir una IP sola dio `Trying ... Open` | En IOS, escribir solo una IP = **telnet** a esa IP | Usar siempre `ping <IP>` |

## Lecciones
1. **Una sola consola abierta a la vez.**
2. **Mirar el prompt** antes de cualquier comando destructivo.
3. **`show cdp neighbors`** es la forma más rápida de comprobar el cableado real.
4. Diagnosticar **por capas**: cable (CDP/luces) → VLAN/trunk → IP/subinterfaz → rutas → servicio.
5. Un `up/up` no garantiza que el cable vaya al lugar correcto (caso 11: Gi0/1 estaba up… pero en otro switch).
