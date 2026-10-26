# 08 · Pruebas y evidencias

El examen (punto 7) pide comprobar: **VLAN, trunk, subinterfaces, tabla de rutas, ping entre redes, nslookup y acceso HTTP por nombre**. El entregable D pide las evidencias.

## El orden correcto: de abajo hacia arriba (por capas)

Si empiezas por la página web y falla, no sabes qué está mal. Si vas capa por capa, **la primera que falla te dice dónde está el problema**.

| # | Capa | Dónde | Comando | Resultado esperado |
|---|---|---|---|---|
| 1 | 1 · cables | Cada router | `show cdp neighbors` | Gi0/0 → su switch Gig 0/1 · Gi0/1 → Switch4 Fas 0/N |
| 2 | 2 · VLAN | Cada switch de acceso | `show vlan brief` | Cada puerto en su VLAN |
| 3 | 2 · trunk | Cada switch de acceso | `show interfaces trunk` | Gi0/1 trunking con sus 2 VLAN |
| 4 | 3 · subinterfaces | Cada router | `show ip interface brief` | Todo **up up** |
| 5 | 3 · rutas | Cada router | `show ip route` | 3 C + 6 S |
| 6 | 3 · R5 | Un router | `ping 172.16.3.193` … `.196` | `!!!!!` |
| 7 | 3 · gateway | Cada PC | `ping <su gateway>` | Responde |
| 8 | 3 · entre redes | PC1 | `ping 172.16.1.10` (PC2) | Responde, TTL=62 en Linux / 126 en Windows (2 routers) |
| 9 | 7 · DNS | PC1 | `nslookup www.hospital.local` | `Address: 172.16.3.66` |
| 10 | 7 · HTTP | PC1 | Navegador: `http://www.hospital.local` | La página del grupo |
| 11 | camino | PC1 | `tracert -d 172.16.3.66` | 172.16.2.1 → 172.16.3.196 → 172.16.3.66 |

> **Sobre el TTL que vimos:** PC1 recibió de PC2 (Ubuntu) **TTL=62**. Linux empieza en 64 y cada router resta 1: 64 − 2 = 62, o sea que el paquete cruzó **2 routers** (Router2 y Router0).

## Scripts de prueba (generan el archivo de evidencia)

| Equipo | Comando |
|---|---|
| Ubuntu | `bash scripts/linux/pruebas.sh \| tee evidencia_$(hostname).txt` |
| Windows | Doble clic en `scripts\windows\pruebas_windows.bat` (crea `evidencia_<PC>.txt` y abre la página) |
| Cualquiera, si algo falla | `diagnostico.sh` o `diagnostico_windows.bat` |

## Evidencias de los equipos Cisco (entregable B y D)

**Opción 1: picocom grabando**
```bash
cd ~/Descargas/red-hospitalaria-g3/evidencias
sudo picocom -b 9600 --flow n --logfile Router0_evidencia.txt /dev/ttyUSB0
```
Y en el equipo:
```
enable
terminal length 0
show cdp neighbors
show ip interface brief
show ip route
show running-config
```
(En switches: `show vlan brief` y `show interfaces trunk` en vez de `show ip route`.)

`terminal length 0` hace que el equipo muestre todo seguido, sin pausar en `--More--`.

**Opción 2: el script**
```bash
sudo python3 scripts/linux/cisco_auto.py Router0 --evidencia
```

**Antes de grabar el siguiente equipo:**
- Sal con `Ctrl+A` y luego `Ctrl+X`.
- Mira que el prompt sea el de **Ubuntu** (`usuario@pc:~$`) y no el del equipo. Si pegas el comando de picocom dentro de la consola del switch, se ensucia el archivo (nos pasó).
- Cambia el nombre del archivo en el comando.

**Arreglos comunes:**
```bash
sudo chown $USER:$USER *_evidencia.txt        # los archivos de sudo quedan de root
sed -i '/^Switch3>/,$d' Router3_evidencia.txt  # borrar del archivo todo lo que viene desde "Switch3>"
```

## Capturas de pantalla que deben tener

| # | Captura | Prueba qué |
|---|---|---|
| 1 | Navegador de PC1 con `http://www.hospital.local` | DNS + HTTP + rutas + VLAN, todo junto |
| 2 | `nslookup www.hospital.local` en PC1 | El DNS |
| 3 | `ping` de PC1 a PC2 | Conectividad entre áreas |
| 4 | `tracert -d 172.16.3.66` en PC1 | El camino por los routers |
| 5 | `show ip route` de un router | Las rutas estáticas |
| 6 | `show vlan brief` y `show interfaces trunk` de un switch | VLAN y 802.1Q |
| 7 | La salida del script del servidor DNS y del HTTP | Que los servidores quedaron arriba |

> No incluyan capturas de pruebas **fallidas** (por ejemplo, de antes de prender los servidores), salvo que expliquen cómo lo arreglaron.

Las capturas y explicaciones de nuestro laboratorio están en `informe/Informe_Red_Hospitalaria_G3.pdf`, y las salidas completas de los 9 equipos en `evidencias/`.
