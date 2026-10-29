# Guía de montaje completo · paso a paso

Montaje de **toda** la red hospitalaria G3 desde cero: cables, switches, routers, servidores y PCs. Cada paso se puede hacer **con script** (rápido) o **a mano** (si el script falla o el profe pide verlo).

**Lo que van a montar:** 4 routers, 5 switches, 2 servidores (DNS y HTTP) y 2 PCs (PC1 Windows y PC2 Ubuntu).

**Tiempo total:** de 60 a 90 minutos.

---

## Índice
- [Fase 0 · Antes de ir al laboratorio](#fase-0--antes-de-ir-al-laboratorio)
- [Fase 1 · Repartir el trabajo](#fase-1--repartir-el-trabajo)
- [Fase 2 · Conectar los cables](#fase-2--conectar-los-cables)
- [Fase 3 · Abrir la consola](#fase-3--abrir-la-consola)
- [Fase 4 · Configurar los 5 switches](#fase-4--configurar-los-5-switches)
- [Fase 5 · Configurar los 4 routers](#fase-5--configurar-los-4-routers)
- [Fase 6 · Servidor DNS](#fase-6--servidor-dns)
- [Fase 7 · Servidor HTTP](#fase-7--servidor-http)
- [Fase 8 · PC1 (Windows)](#fase-8--pc1-windows)
- [Fase 9 · PC2 (Ubuntu)](#fase-9--pc2-ubuntu)
- [Fase 10 · Pruebas finales](#fase-10--pruebas-finales)
- [Fase 11 · Prueba de las 8 LAN cambiando IPs](#fase-11--prueba-de-las-8-lan-cambiando-ips)
- [Fase 12 · Evidencias y cierre](#fase-12--evidencias-y-cierre)
- [Anexo · Configuración completa de los 9 equipos para copiar a mano](#anexo--configuración-completa-de-los-9-equipos-para-copiar-a-mano)

---

## Fase 0 · Antes de ir al laboratorio

En el laboratorio **no hay internet** una vez conectados a la red. Todo se instala antes.

**En el portátil Ubuntu con el cable de consola** y en **los PCs Ubuntu que serán servidores**:
```bash
git clone https://github.com/Exoticdevelopment/red-hospitalaria-g3.git
cd red-hospitalaria-g3
sudo bash scripts/linux/preparar_con_internet.sh
```
Instala picocom (consola), python3-serial (para el script de Cisco), dnsmasq (DNS), apache2 (web), curl y traceroute.

**Para el PC Windows:** copien la carpeta `scripts\windows` a una **USB**.

**Lleven:** el cable de consola USB, la USB con los scripts y esta guía abierta en el celular.

---

## Fase 1 · Repartir el trabajo

| Persona | Tarea | Fases |
|---|---|---|
| 1 | Cables + consola: switches y routers | 2, 3, 4, 5 |
| 2 | Servidor DNS | 6 |
| 3 | Servidor HTTP | 7 |
| 4 | PC1 Windows | 8 |
| 5 | PC2 Ubuntu + revisar con la tabla de la Fase 2 | 2, 9 |

Las personas 2 a 5 pueden trabajar **al mismo tiempo** que la 1. Las pruebas (Fase 10) solo funcionan cuando switches y routers están listos.

> ⚠️ La sustentación es **individual**: aunque cada uno haga una parte, **todos** deben entender todo.

---

## Fase 2 · Conectar los cables

### 2.1 Conocer los puertos
- **Switch 2960:** a la izquierda, 24 puertos **Fa0/1 a Fa0/24** (para PCs). A la derecha, 2 puertos **Gi0/1 y Gi0/2** (para el router).
- **Router 2901:** atrás, **Gi0/0** y **Gi0/1**, y el puerto azul **CONSOLE**.

> ⚠️ El switch tiene **dos puertos "1"**: Fa0/1 (izquierda) y Gi0/1 (derecha). No los confundan.

### 2.2 Tabla de cables (12 cables directos normales)

| # | Desde | Hacia | Para qué |
|---|---|---|---|
| 1 | Router0 **Gi0/0** | Switch0 **Gi0/1** | Trunk VLAN 210, 220 |
| 2 | Router1 **Gi0/0** | Switch1 **Gi0/1** | Trunk VLAN 230, 240 |
| 3 | Router2 **Gi0/0** | Switch2 **Gi0/1** | Trunk VLAN 250, 260 |
| 4 | Router3 **Gi0/0** | Switch3 **Gi0/1** | Trunk VLAN 270, 280 |
| 5 | Router0 **Gi0/1** | Switch4 **Fa0/1** | Red de tránsito R5 |
| 6 | Router1 **Gi0/1** | Switch4 **Fa0/2** | Red de tránsito R5 |
| 7 | Router2 **Gi0/1** | Switch4 **Fa0/3** | Red de tránsito R5 |
| 8 | Router3 **Gi0/1** | Switch4 **Fa0/4** | Red de tránsito R5 |
| 9 | **PC1** Windows | Switch0 **Fa0/1** | Urgencias (VLAN 210) |
| 10 | **PC2** Ubuntu | Switch2 **Fa0/1** | Consulta externa (VLAN 250) |
| 11 | **Servidor DNS** | Switch1 **Fa0/3** | Farmacia (VLAN 240) |
| 12 | **Servidor HTTP** | Switch3 **Fa0/3** | Administración (VLAN 270) |

**Regla para recordar:** el RouterN va a su SwitchN por los Gigabit, y al Switch4 en el puerto Fa0/(N+1).

### 2.3 Encender
1. Prendan los 9 equipos Cisco.
2. Esperen **3 minutos**, hasta que la luz **SYST/SYS** esté **verde fija**.
3. Las luces de los puertos con cable deben ponerse verdes (al principio pueden estar ámbar unos 30 s).

---

## Fase 3 · Abrir la consola

Con el **cable de consola** conectado del portátil Ubuntu al puerto **CONSOLE** del equipo:

```bash
ls /dev/ttyUSB*                                    # debe salir /dev/ttyUSB0
sudo picocom -b 9600 --flow n /dev/ttyUSB0         # abrir la consola
```
- Presiona **Enter** dos veces: debe salir algo como `Switch>` o `Router>`.
- **Salir:** `Ctrl+A` y luego `Ctrl+X`.
- **No hagas clic dentro de la ventana** (pega texto y daña todo).
- Si dice `cannot lock`: `sudo pkill picocom` y vuelve a abrir.

> Para cada equipo de las Fases 4 y 5: **mueve el cable de consola**, abre la consola y **mira el prompt** para confirmar en qué equipo estás.

---

## Fase 4 · Configurar los 5 switches

### Opción A · Con script (recomendada)
Cable de consola en el switch, **cierra picocom**, y corre:
```bash
cd ~/red-hospitalaria-g3
sudo python3 scripts/linux/cisco_auto.py Switch0 --borrar
```
1. El script te muestra el nombre actual del equipo y pregunta **"¿Continuar? (s/n)"** → `s`.
2. Borra la configuración vieja, reinicia (unos 3 minutos), configura, guarda y muestra la verificación.
3. Repite con `Switch1`, `Switch2`, `Switch3` y `Switch4`, moviendo el cable de consola cada vez.

### Opción B · A mano
1. **Borrar lo viejo** (si el prompt no es el nombre que esperas):
   ```
   enable
   write erase                ← Enter en [confirm]
   delete flash:vlan.dat      ← Enter, Enter
   reload                     ← "Save?" → no ; [confirm] → Enter
   ```
   Al prender: `initial configuration dialog? [yes/no]` → escribe **`no`**.
2. **Copiar el bloque** del switch desde el [Anexo](#anexo--configuración-completa-de-los-9-equipos-para-copiar-a-mano), **una línea a la vez**, esperando el prompt.
3. En `Destination filename [startup-config]?` presiona **solo Enter**.

### Comprobar cada switch
```
show vlan brief
show interfaces trunk
```
| Switch | `show vlan brief` debe mostrar |
|---|---|
| Switch0 | 210 → Fa0/1 · 220 → Fa0/2 |
| Switch1 | 230 → Fa0/1 · 240 → Fa0/2, Fa0/3 |
| Switch2 | 250 → Fa0/1 · 260 → Fa0/2 |
| Switch3 | 270 → Fa0/1, Fa0/3 · 280 → Fa0/2 |
| Switch4 | Solo la VLAN 1 (Fa0/1 a Fa0/24) |

`show interfaces trunk` (Switch0–3): **Gi0/1** en modo **trunking** con sus 2 VLAN.

📖 Qué hace cada comando: [docs/04](docs/04_switches_comando_por_comando.md)

---

## Fase 5 · Configurar los 4 routers

### Opción A · Con script
```bash
sudo python3 scripts/linux/cisco_auto.py Router0
```
⚠️ En routers **NO usen `--borrar`**: dos routers se quedaron en un bucle `ROMMON` al reiniciarlos con la consola conectada.

Repitan con `Router1`, `Router2` y `Router3`.

### Opción B · A mano
1. Copia el bloque del router desde el [Anexo](#anexo--configuración-completa-de-los-9-equipos-para-copiar-a-mano), **una línea a la vez**.
2. Revisa si quedaron **rutas de otros grupos**:
   ```
   show running-config | include ip route
   ```
   Deben salir **exactamente 6**. Si hay otra, bórrala con `no` + la línea completa, por ejemplo:
   ```
   configure terminal
   no ip route 192.168.50.0 255.255.255.0 192.168.60.1
   end
   copy running-config startup-config
   ```

### Comprobar cada router
```
show cdp neighbors
show ip interface brief
show ip route
show version | include register
```
| Comando | Debe mostrar |
|---|---|
| `show cdp neighbors` | Gi0/0 → **su switch** Gig 0/1 · Gi0/1 → **Switch4** Fas 0/N |
| `show ip interface brief` | Gi0/0, las 2 subinterfaces y Gi0/1 en **up up** |
| `show ip route` | **3 C** + **6 S** |
| `show version \| include register` | **0x2102** |

**Prueba entre routers** (desde cualquiera):
```
ping 172.16.3.193
ping 172.16.3.194
ping 172.16.3.195
ping 172.16.3.196
```
Todos deben dar `!!!!!`. Si alguno da `.....`, revisa su cable al Switch4 con `show cdp neighbors`.

📖 Qué hace cada comando: [docs/05](docs/05_routers_comando_por_comando.md)

---

## Fase 6 · Servidor DNS

**PC Ubuntu, cable en Switch1 Fa0/3.**

### Opción A · Con script
```bash
cd ~/red-hospitalaria-g3
sudo bash scripts/linux/servidor_dns.sh
```
Al final debe salir:
```
Name:    www.hospital.local
Address: 172.16.3.66
```
(Un `REFUSED` para IPv6 es normal.)

### Opción B · A mano
```bash
# 1. IP del servidor
nmcli radio wifi off
sudo nmcli con add type ethernet ifname <tarjeta> con-name G3-dns \
   ipv4.method manual ipv4.addresses 172.16.3.130/27 \
   ipv4.gateway 172.16.3.129 ipv4.dns 172.16.3.130 ipv6.method disabled
sudo nmcli con up G3-dns

# 2. Liberar el puerto 53
sudo systemctl disable --now systemd-resolved
echo "nameserver 172.16.3.130" | sudo tee /etc/resolv.conf

# 3. Configurar el registro A
sudo nano /etc/dnsmasq.d/hospital.conf
```
Escribe esto en el archivo y guarda (`Ctrl+O`, Enter, `Ctrl+X`):
```
listen-address=172.16.3.130
bind-interfaces
no-resolv
address=/www.hospital.local/172.16.3.66
log-queries
```
```bash
# 4. Arrancar y probar
sudo systemctl restart dnsmasq
nslookup www.hospital.local 172.16.3.130
```
(`<tarjeta>` es el nombre que sale en `ip link`, por ejemplo `eno1`.)

**Comprobar:** `ping 172.16.3.129` (su gateway) debe responder.

📖 [docs/07](docs/07_servidores_dns_y_http.md)

---

## Fase 7 · Servidor HTTP

**PC Ubuntu, cable en Switch3 Fa0/3.**

### Opción A · Con script
```bash
cd ~/red-hospitalaria-g3
sudo bash scripts/linux/servidor_http.sh
```
Al final debe salir `<h1>Red hospitalaria G3</h1>`.

### Opción B · A mano
```bash
# 1. IP del servidor
nmcli radio wifi off
sudo nmcli con add type ethernet ifname <tarjeta> con-name G3-http \
   ipv4.method manual ipv4.addresses 172.16.3.66/26 \
   ipv4.gateway 172.16.3.65 ipv4.dns 172.16.3.130 ipv6.method disabled
sudo nmcli con up G3-http

# 2. Página web
sudo nano /var/www/html/index.html
```
Pega una página que diga el grupo y la red (IP 172.16.3.66/26, VLAN 270, gateway 172.16.3.65, DNS 172.16.3.130). Luego:
```bash
sudo systemctl restart apache2
curl http://172.16.3.66
```

**Comprobar:** `ping 172.16.3.65` (su gateway) debe responder.

---

## Fase 8 · PC1 (Windows)

**Cable en Switch0 Fa0/1 (Urgencias, VLAN 210).**

### Opción A · Con script
1. Abre la carpeta `scripts\windows` desde la USB.
2. Doble clic en **`configurar_pc_windows.bat`** → **Sí** (administrador).
3. Escribe **`1`** y Enter.
4. Debe salir **[OK] Gateway**, **[OK] Servidor DNS** y **[OK] Servidor HTTP**.

### Opción B · A mano
1. `Windows + R` → `ncpa.cpl` → Enter.
2. Clic derecho en **Ethernet** → **Propiedades** → **Protocolo de Internet versión 4 (TCP/IPv4)** → **Propiedades**.
3. Escribe:

   | Campo | Valor |
   |---|---|
   | Dirección IP | 172.16.2.10 |
   | Máscara de subred | 255.255.255.128 |
   | Puerta de enlace | 172.16.2.1 |
   | Servidor DNS preferido | 172.16.3.130 |

4. **Aceptar** → **Aceptar**. **Apaga el Wi-Fi.**
5. Para que los demás le puedan hacer ping, en **cmd como administrador**:
   ```
   netsh advfirewall firewall add rule name="G3-ICMP" protocol=icmpv4:8,any dir=in action=allow
   ```

**Comprobar** (cmd):
```
ipconfig
ping 172.16.2.1
```

---

## Fase 9 · PC2 (Ubuntu)

**Cable en Switch2 Fa0/1 (Consulta externa, VLAN 250).**

### Opción A · Con script
```bash
cd ~/red-hospitalaria-g3
sudo bash scripts/linux/configurar_pc_linux.sh 2
```
Debe terminar con: `OK: cable, puerto del switch, VLAN, trunk y subinterfaz funcionan.`

### Opción B · A mano
```bash
nmcli radio wifi off
sudo nmcli con add type ethernet ifname <tarjeta> con-name G3-2 \
   ipv4.method manual ipv4.addresses 172.16.1.10/24 \
   ipv4.gateway 172.16.1.1 ipv4.dns 172.16.3.130 ipv6.method disabled
sudo nmcli con up G3-2
# Arreglo para que funcione el ".local" en Ubuntu:
sudo sed -i 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf
echo "nameserver 172.16.3.130" | sudo tee /etc/resolv.conf
```

**Comprobar:**
```bash
ip -4 addr
ping -c 4 172.16.1.1
```

---

## Fase 10 · Pruebas finales

Desde **PC1 (Windows)**, en cmd:

| # | Comando | Debe salir | Prueba |
|---|---|---|---|
| 1 | `ping 172.16.2.1` | Respuestas | Su gateway (VLAN, trunk, subinterfaz) |
| 2 | `ping 172.16.1.10` | Respuestas con **TTL=62** | Llega a PC2 pasando por 2 routers |
| 3 | `ping 172.16.3.130` | Respuestas | Llega al DNS (Router1) |
| 4 | `ping 172.16.3.66` | Respuestas | Llega al HTTP (Router3) |
| 5 | `nslookup www.hospital.local` | `Address: 172.16.3.66` | El DNS |
| 6 | Navegador: `http://www.hospital.local` | La página del Grupo 3 | **Todo junto** |
| 7 | `tracert -d 172.16.3.66` | 172.16.2.1 → 172.16.3.196 → 172.16.3.66 | El camino |

**Pruebas automáticas que guardan evidencia:**
- PC1: doble clic en **`pruebas_windows.bat`** (también hace ping a los 8 gateways).
- PC2: `bash scripts/linux/pruebas.sh | tee evidencia_pc2.txt`.

**Si algo falla:** `diagnostico_windows.bat` o `bash scripts/linux/diagnostico.sh` → lee la **primera** línea roja: ahí está el problema.

📖 Tabla de problemas: [docs/09](docs/09_problemas_y_soluciones.md)

---

## Fase 11 · Prueba de las 8 LAN cambiando IPs

Lo que pidió el profesor: llevar los PCs por las 8 áreas, **moviendo el cable y cambiando la IP**.

- Windows: **`recorrido_windows.bat`** → escribe `1 3 4 5`.
- Ubuntu: `sudo bash scripts/linux/recorrido_lan.sh 2 6 7 8`.

📖 Guía completa, con la forma a mano: [GUIA_PRUEBA_CAMBIANDO_IPS.md](GUIA_PRUEBA_CAMBIANDO_IPS.md)

---

## Fase 12 · Evidencias y cierre

### Evidencias de los equipos Cisco
Para cada uno de los 9 equipos (cable de consola en el equipo):
```bash
cd ~/red-hospitalaria-g3/evidencias
sudo python3 ../scripts/linux/cisco_auto.py Router0 --evidencia
```
O con picocom grabando:
```bash
sudo picocom -b 9600 --flow n --logfile Router0_evidencia.txt /dev/ttyUSB0
```
Luego, en el equipo: `enable`, `terminal length 0`, `show cdp neighbors`, `show ip interface brief`, `show ip route`, `show running-config`.

### Capturas
- Navegador de PC1 con la página.
- `nslookup`, `ping` a PC2 y `tracert` en PC1.
- El resumen del recorrido de las 8 LAN.

### Al terminar
- [ ] Todos los equipos guardados (`copy running-config startup-config`).
- [ ] PCs restaurados: `configurar_pc_windows.bat` → **R** · `sudo bash scripts/linux/configurar_pc_linux.sh restaurar`.
- [ ] Evidencias subidas a GitHub:
  ```bash
  git add -A && git commit -m "Evidencias del laboratorio" && git push
  ```

---

## Anexo · Configuración completa de los 9 equipos para copiar a mano

Copia **una línea a la vez** y espera el prompt antes de la siguiente. En `Destination filename [startup-config]?` presiona **solo Enter**.

Los mismos bloques, con un comentario en cada línea, están en la carpeta [`configs/`](configs/).

### Switch0
```
enable
configure terminal
hostname Switch0
no ip domain-lookup
vlan 210
 name R1_Urgencias
exit
vlan 220
 name R2_Hospitalizacion
exit
interface GigabitEthernet0/1
 description TRUNK_A_ROUTER
 switchport mode trunk
 switchport trunk allowed vlan 210,220
 no shutdown
exit
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 210
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 220
 spanning-tree portfast
 no shutdown
exit
end
copy running-config startup-config
```

### Switch1
```
enable
configure terminal
hostname Switch1
no ip domain-lookup
vlan 230
 name R3_Laboratorio
exit
vlan 240
 name R4_Farmacia
exit
interface GigabitEthernet0/1
 description TRUNK_A_ROUTER
 switchport mode trunk
 switchport trunk allowed vlan 230,240
 no shutdown
exit
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 230
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 240
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/3
 switchport mode access
 switchport access vlan 240
 spanning-tree portfast
 no shutdown
exit
end
copy running-config startup-config
```

### Switch2
```
enable
configure terminal
hostname Switch2
no ip domain-lookup
vlan 250
 name R6_Consulta
exit
vlan 260
 name R7_Imagenes
exit
interface GigabitEthernet0/1
 description TRUNK_A_ROUTER
 switchport mode trunk
 switchport trunk allowed vlan 250,260
 no shutdown
exit
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 250
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 260
 spanning-tree portfast
 no shutdown
exit
end
copy running-config startup-config
```

### Switch3
```
enable
configure terminal
hostname Switch3
no ip domain-lookup
vlan 270
 name R8_Administracion
exit
vlan 280
 name R9_Ing_Biomedica
exit
interface GigabitEthernet0/1
 description TRUNK_A_ROUTER
 switchport mode trunk
 switchport trunk allowed vlan 270,280
 no shutdown
exit
interface FastEthernet0/1
 switchport mode access
 switchport access vlan 270
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 280
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/3
 switchport mode access
 switchport access vlan 270
 spanning-tree portfast
 no shutdown
exit
end
copy running-config startup-config
```

### Switch4
```
enable
configure terminal
hostname Switch4
no ip domain-lookup
interface range FastEthernet0/1 - 4
 description R5_TRANSITO
 switchport mode access
 switchport access vlan 1
 spanning-tree portfast
 no shutdown
exit
end
copy running-config startup-config
```

### Router0
```
enable
configure terminal
hostname Router0
no ip domain-lookup
interface GigabitEthernet0/0
 description TRUNK_AL_SWITCH_DE_ACCESO
no ip address
 no shutdown
exit
interface GigabitEthernet0/0.210
 encapsulation dot1Q 210
 ip address 172.16.2.1 255.255.255.128
exit
interface GigabitEthernet0/0.220
 encapsulation dot1Q 220
 ip address 172.16.0.1 255.255.255.0
exit
interface GigabitEthernet0/1
 description R5_TRANSITO
 ip address 172.16.3.193 255.255.255.248
 no shutdown
exit
ip route 172.16.3.0 255.255.255.192 172.16.3.194
ip route 172.16.3.128 255.255.255.224 172.16.3.194
ip route 172.16.1.0 255.255.255.0 172.16.3.195
ip route 172.16.2.128 255.255.255.128 172.16.3.195
ip route 172.16.3.64 255.255.255.192 172.16.3.196
ip route 172.16.3.160 255.255.255.224 172.16.3.196
config-register 0x2102
end
copy running-config startup-config
```

### Router1
```
enable
configure terminal
hostname Router1
no ip domain-lookup
interface GigabitEthernet0/0
 description TRUNK_AL_SWITCH_DE_ACCESO
no ip address
 no shutdown
exit
interface GigabitEthernet0/0.230
 encapsulation dot1Q 230
 ip address 172.16.3.1 255.255.255.192
exit
interface GigabitEthernet0/0.240
 encapsulation dot1Q 240
 ip address 172.16.3.129 255.255.255.224
exit
interface GigabitEthernet0/1
 description R5_TRANSITO
 ip address 172.16.3.194 255.255.255.248
 no shutdown
exit
ip route 172.16.2.0 255.255.255.128 172.16.3.193
ip route 172.16.0.0 255.255.255.0 172.16.3.193
ip route 172.16.1.0 255.255.255.0 172.16.3.195
ip route 172.16.2.128 255.255.255.128 172.16.3.195
ip route 172.16.3.64 255.255.255.192 172.16.3.196
ip route 172.16.3.160 255.255.255.224 172.16.3.196
config-register 0x2102
end
copy running-config startup-config
```

### Router2
```
enable
configure terminal
hostname Router2
no ip domain-lookup
interface GigabitEthernet0/0
 description TRUNK_AL_SWITCH_DE_ACCESO
no ip address
 no shutdown
exit
interface GigabitEthernet0/0.250
 encapsulation dot1Q 250
 ip address 172.16.1.1 255.255.255.0
exit
interface GigabitEthernet0/0.260
 encapsulation dot1Q 260
 ip address 172.16.2.129 255.255.255.128
exit
interface GigabitEthernet0/1
 description R5_TRANSITO
 ip address 172.16.3.195 255.255.255.248
 no shutdown
exit
ip route 172.16.2.0 255.255.255.128 172.16.3.193
ip route 172.16.0.0 255.255.255.0 172.16.3.193
ip route 172.16.3.0 255.255.255.192 172.16.3.194
ip route 172.16.3.128 255.255.255.224 172.16.3.194
ip route 172.16.3.64 255.255.255.192 172.16.3.196
ip route 172.16.3.160 255.255.255.224 172.16.3.196
config-register 0x2102
end
copy running-config startup-config
```

### Router3
```
enable
configure terminal
hostname Router3
no ip domain-lookup
interface GigabitEthernet0/0
 description TRUNK_AL_SWITCH_DE_ACCESO
no ip address
 no shutdown
exit
interface GigabitEthernet0/0.270
 encapsulation dot1Q 270
 ip address 172.16.3.65 255.255.255.192
exit
interface GigabitEthernet0/0.280
 encapsulation dot1Q 280
 ip address 172.16.3.161 255.255.255.224
exit
interface GigabitEthernet0/1
 description R5_TRANSITO
 ip address 172.16.3.196 255.255.255.248
 no shutdown
exit
ip route 172.16.2.0 255.255.255.128 172.16.3.193
ip route 172.16.0.0 255.255.255.0 172.16.3.193
ip route 172.16.3.0 255.255.255.192 172.16.3.194
ip route 172.16.3.128 255.255.255.224 172.16.3.194
ip route 172.16.1.0 255.255.255.0 172.16.3.195
ip route 172.16.2.128 255.255.255.128 172.16.3.195
config-register 0x2102
end
copy running-config startup-config
```

