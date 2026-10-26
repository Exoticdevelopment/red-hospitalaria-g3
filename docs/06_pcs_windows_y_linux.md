# 06 · PCs: Windows y Linux

Cada PC necesita **4 datos**: IP, máscara, gateway y DNS. Salen del Excel (hoja "Reservas").

| Opción del script | Equipo | IP / prefijo | Máscara | Gateway | Puerto del switch |
|---|---|---|---|---|---|
| 1 | **PC1 Urgencias** (el que usamos, Windows) | 172.16.2.10/25 | 255.255.255.128 | 172.16.2.1 | Switch0 Fa0/1 |
| 2 | **PC2 Consulta** (el que usamos, Ubuntu) | 172.16.1.10/24 | 255.255.255.0 | 172.16.1.1 | Switch2 Fa0/1 |
| 3 | PC Hospitalización | 172.16.0.10/24 | 255.255.255.0 | 172.16.0.1 | Switch0 Fa0/2 |
| 4 | PC Laboratorio | 172.16.3.10/26 | 255.255.255.192 | 172.16.3.1 | Switch1 Fa0/1 |
| 5 | PC Farmacia | 172.16.3.138/27 | 255.255.255.224 | 172.16.3.129 | Switch1 Fa0/2 |
| 6 | PC Imágenes | 172.16.2.138/25 | 255.255.255.128 | 172.16.2.129 | Switch2 Fa0/2 |
| 7 | PC Administración | 172.16.3.74/26 | 255.255.255.192 | 172.16.3.65 | Switch3 Fa0/1 |
| 8 | PC Ing. biomédica | 172.16.3.170/27 | 255.255.255.224 | 172.16.3.161 | Switch3 Fa0/2 |

**DNS para todos: 172.16.3.130**

> **Lo más importante:** el **puerto del switch** decide la VLAN. Si conectas el PC de Urgencias en el puerto de Hospitalización, no funciona aunque la IP esté bien.

---

## ¿Por qué los scripts hacen tantas cosas? (PCs que usaron otros)

En el laboratorio los PCs los usan muchos grupos. Problemas que pueden aparecer y que los scripts arreglan solos:

| Problema que deja otro grupo | Qué pasa | Qué hace el script |
|---|---|---|
| Wi-Fi prendido | El PC tiene dos caminos y puede salir por el Wi-Fi | Lo apaga |
| Otra tarjeta con gateway (VPN, VirtualBox) | Igual: otro camino | La apaga (Windows) |
| IP vieja de otra práctica | El PC queda con 2 IP | Borra las IPs viejas |
| DNS viejo o sufijo DNS | `www.hospital.local` no resuelve | Pone solo 172.16.3.130 |
| Proxy en el navegador | La página no carga aunque el ping funcione | Quita el proxy |
| Línea de `hospital.local` en el archivo hosts | Resuelve a una IP equivocada | La borra |
| Firewall bloquea el ping | Los otros no te pueden hacer ping | Permite ICMP |
| Perfil de red viejo que se reactiva (Ubuntu) | Te cambia la IP sola | Desactiva su conexión automática |
| Ubuntu manda `.local` a mDNS | `nslookup` funciona pero el navegador no | Arregla `/etc/nsswitch.conf` |
| No hay cable o está en otro puerto | Nada funciona | **Avisa** antes de seguir |

Todos los scripts guardan una copia de cómo estaba el PC y tienen la opción **restaurar** para dejarlo como lo encontraron.

---

## Windows

### Con el script (recomendado)
1. Copia la carpeta `scripts\windows` al PC (USB o descargando el repositorio).
2. Doble clic en **`configurar_pc_windows.bat`** → "Sí" cuando pida permisos de administrador.
3. Escribe la opción (por ejemplo `1` para PC1) y Enter.
4. Mira las pruebas del final: **[OK] Gateway** es lo más importante.
5. Si algo falla: doble clic en **`diagnostico_windows.bat`** y lee la primera línea roja.
6. Al terminar el examen: `configurar_pc_windows.bat` → opción **R** (restaurar).

### A mano (para entender)
1. `Win + R` → `ncpa.cpl` → Enter (abre las conexiones de red).
2. Clic derecho en **Ethernet** → Propiedades.
3. **Protocolo de Internet versión 4 (TCP/IPv4)** → Propiedades.
4. "Usar la siguiente dirección IP":
   - Dirección IP: `172.16.2.10`
   - Máscara de subred: `255.255.255.128`
   - Puerta de enlace predeterminada: `172.16.2.1`
   - Servidor DNS preferido: `172.16.3.130`
5. Aceptar → Aceptar.
6. Apaga el Wi-Fi.

### A mano con comandos (cmd como administrador)
```
netsh interface ip set address name="Ethernet" static 172.16.2.10 255.255.255.128 172.16.2.1
netsh interface ip set dns name="Ethernet" static 172.16.3.130
netsh advfirewall firewall add rule name="G3-ICMP" protocol=icmpv4:8,any dir=in action=allow
ipconfig /flushdns
```
| Comando | Qué hace |
|---|---|
| `netsh interface ip set address … static IP MÁSCARA GATEWAY` | Pone IP fija en la tarjeta llamada "Ethernet" |
| `netsh interface ip set dns … static 172.16.3.130` | Pone el DNS |
| `netsh advfirewall firewall add rule … icmpv4:8` | Deja que otros le hagan ping a este PC (Windows lo bloquea por defecto) |
| `ipconfig /flushdns` | Borra los nombres que Windows tenía guardados |

### Comprobar en Windows
```
ipconfig                         ← ver IP, máscara y gateway
ping 172.16.2.1                  ← el gateway
ping 172.16.1.10                 ← PC2 (otra área, otro router)
nslookup www.hospital.local      ← el DNS
tracert -d 172.16.3.66           ← por qué routers pasa
```

---

## Ubuntu (Linux)

### Con el script (recomendado)
```bash
# UNA VEZ, con internet (antes de conectarse a la red del lab):
sudo bash scripts/linux/preparar_con_internet.sh

# En el lab, con el cable en el switch:
sudo bash scripts/linux/configurar_pc_linux.sh 2      # 2 = PC2 Consulta
bash scripts/linux/diagnostico.sh                     # si algo falla
sudo bash scripts/linux/configurar_pc_linux.sh restaurar   # al terminar
```

### A mano con comandos (para entender)
```bash
ip link                                   # ver el nombre de la tarjeta de cable (ej. eno1, enp3s0)
nmcli radio wifi off                      # apagar Wi-Fi
sudo nmcli con add type ethernet ifname eno1 con-name G3 \
     ipv4.method manual ipv4.addresses 172.16.1.10/24 \
     ipv4.gateway 172.16.1.1 ipv4.dns 172.16.3.130 ipv6.method disabled
sudo nmcli con up G3
```

| Parte | Qué hace |
|---|---|
| `ip link` | Lista las tarjetas. La de cable suele empezar por `en` o `eth`; la de Wi-Fi, por `wl` |
| `nmcli` | La herramienta de terminal de NetworkManager (el gestor de red de Ubuntu) |
| `con add type ethernet ifname eno1` | Crea un perfil de red para la tarjeta `eno1` |
| `ipv4.method manual` | IP fija (no DHCP) |
| `ipv4.addresses 172.16.1.10/24` | IP y prefijo juntos |
| `ipv4.gateway` / `ipv4.dns` | Gateway y DNS |
| `ipv6.method disabled` | Sin IPv6 |
| `con up G3` | Activa el perfil |

**El arreglo del `.local`:** Ubuntu le pregunta los nombres `.local` a un sistema llamado mDNS (Avahi) y no al DNS. Por eso `nslookup` funcionaba pero el navegador no. Se arregla así:
```bash
sudo sed -i 's/^hosts:.*/hosts: files dns/' /etc/nsswitch.conf
echo "nameserver 172.16.3.130" | sudo tee /etc/resolv.conf
```

### Comprobar en Ubuntu
```bash
ip -4 addr            # ver la IP
ip route              # ver el gateway ("default via 172.16.1.1")
ping -c 4 172.16.1.1
nslookup www.hospital.local
getent hosts www.hospital.local    # cómo lo resuelve el sistema (navegador)
curl http://www.hospital.local
bash scripts/linux/pruebas.sh | tee evidencia_pc2.txt
```
