# 09 · Problemas y soluciones

## Parte A · Lo que nos pasó de verdad (26-oct-2026)

**El profesor suele preguntar "¿qué harías si…?".** Estos casos reales son la mejor respuesta.

| # | Síntoma | Causa | Solución |
|---|---|---|---|
| 1 | Letras perdidas o repetidas en la consola (`eeennaable`) | **3 programas** usando el cable a la vez (2 `screen` + `picocom`) | `sudo lsof /dev/ttyUSB0`, cerrar los demás, `sudo systemctl stop ModemManager`, usar solo picocom |
| 2 | Errores `Invalid input` sin parar | Se pegó texto con clic derecho **dentro** de la consola | No hacer clic dentro de picocom; escribir o pegar una línea a la vez |
| 3 | Equipos con nombres raros (`SW-LAB`, `S1`, `R1`) | Configuraciones de otros grupos | `write erase` + `delete flash:vlan.dat` + `reload` |
| 4 | El asistente inicial guardó contraseñas `cisco` | Se respondió Enter/yes a `initial configuration dialog` | Responder siempre **`no`**. Para quitarlas: `no enable secret`, `no enable password` |
| 5 | Se borró el switch equivocado | El cable de consola seguía en Switch0 | Como la config seguía en RAM: `copy running-config startup-config`. **Mirar el prompt antes de borrar** |
| 6 | Routers en bucle `ROMMON initialized` | Se reiniciaron con la consola conectada | Desconectar la consola, apagar y prender, esperar SYS verde, configurar **sin borrar** |
| 7 | Router2 olvidaba su configuración al reiniciar | `config-register 0x2142` | `config-register 0x2102` + guardar |
| 8 | Ping a .193 y .194 fallaba, a .196 sí | Router0 Gi0/1 conectado a **Switch2** (lo confundieron con el central) | `show cdp neighbors` lo mostró; se movió el cable a Switch4 |
| 9 | Router2 veía a Switch3 y Router3 a Switch2 | Cables de trunk intercambiados | Intercambiar los cables; verificar con CDP |
| 10 | Ruta rara `192.168.50.0` en Router0 | La dejó una práctica anterior | `no ip route 192.168.50.0 255.255.255.0 192.168.60.1` |
| 11 | PC2 (Ubuntu): `nslookup` funcionaba, el navegador no | Ubuntu manda `.local` a mDNS | `hosts: files dns` en `/etc/nsswitch.conf` y DNS directo en `/etc/resolv.conf` |
| 12 | El nombre del grupo salía cortado en la página | Los integrantes iban en comillas separadas | Todos dentro de **una sola** pareja de comillas |
| 13 | `copy run start` dio `%Error copying` | Se escribió otra cosa en `Destination filename?` | Repetir y presionar **solo Enter** |
| 14 | `FATAL: cannot lock /dev/ttyUSB0` | Quedó otro picocom abierto | `sudo pkill picocom` |
| 15 | Escribir solo una IP en el router dio `Trying… Open` | En IOS, una IP sola = **telnet** a esa IP | Usar siempre `ping <IP>` |
| 16 | La VLAN 280 se llamaba "R9_Ingenieria" | Error en el script (le faltaba "biomédica") | `vlan 280` → `name R9_Ing_Biomedica` + guardar |

## Parte B · Guía de diagnóstico: "no funciona X"

### El PC no hace ping a su gateway
1. ¿Prende la luz del puerto del switch? No → cable o puerto (`show interfaces status`).
2. ¿El cable está en el **puerto correcto**? (Fa0/1 y Fa0/2 a la izquierda, no Gi0/1).
3. En el switch: `show vlan brief` → ¿el puerto está en la VLAN correcta?
4. En el switch: `show interfaces trunk` → ¿Gi0/1 trunk con esa VLAN permitida?
5. En el router: `show ip interface brief` → ¿la subinterfaz está up up y con la IP correcta?
6. En el router: `show running-config interface gi0/0.210` → ¿`encapsulation dot1Q` con el número correcto?
7. En el PC: ¿IP y máscara en la misma red que el gateway? ¿Wi-Fi apagado?

### El PC llega a su gateway pero no a otra red
1. En **su** router: `show ip route` → ¿hay ruta S hacia la red destino?
2. En el router **destino**: ¿hay ruta de **regreso**? (falta de ruta de regreso = el ping se va pero no vuelve)
3. Desde el router: `ping` a la IP de R5 del otro router. Si falla → cable a Switch4 (`show cdp neighbors`).
4. ¿El equipo destino tiene bien **su** gateway? (si no, no sabe responder)
5. ¿El firewall del destino bloquea el ping? (Windows lo bloquea por defecto)

### Hay ping pero no resuelve el nombre
1. `nslookup www.hospital.local 172.16.3.130` → si falla, el problema es el **servidor DNS** (`systemctl status dnsmasq`).
2. Si eso funciona pero `nslookup www.hospital.local` (sin IP) no → el PC no tiene configurado el DNS 172.16.3.130.
3. Ubuntu: si `nslookup` funciona pero `getent hosts` no → arreglo del `.local` (`nsswitch.conf`).
4. Windows: revisa el archivo `C:\Windows\System32\drivers\etc\hosts` y corre `ipconfig /flushdns`.

### Resuelve el nombre pero no carga la página
1. `curl http://172.16.3.66` o abre la página por IP en el navegador → si falla, es Apache (`systemctl status apache2`).
2. ¿El navegador tiene **proxy**? Quítalo, o usa el script de PC que lo quita.
3. Prueba con `http://` explícito (algunos navegadores intentan `https://`).
4. Firewall del servidor: `sudo ufw status`.

## Parte C · Lecciones
1. **Una sola consola abierta a la vez.**
2. **Mira el prompt** antes de cualquier comando que borre.
3. **`show cdp neighbors`** es la forma más rápida de saber si los cables están bien.
4. **Diagnostica por capas:** cable → VLAN/trunk → IP/gateway → rutas → servicio.
5. Un **up/up** no garantiza que el cable vaya al lugar correcto (caso 8).
6. **Guarda** después de cada cambio (`copy running-config startup-config`).
