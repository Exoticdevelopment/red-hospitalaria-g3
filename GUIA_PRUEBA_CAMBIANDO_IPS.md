# Guía: probar las 8 LAN cambiando IPs

**Lo que pidió el profesor:** con los PCs que tenemos, ir cambiando las IPs para demostrar que **las 8 LAN funcionan**.

**La idea:** cada PC va "visitando" las áreas del hospital una por una. Los **2 servidores (DNS y HTTP) NO se mueven**.

> ⚠️ **La regla más importante:** en cada visita se hacen **DOS cosas**:
> 1. **Mover el cable** al puerto de esa área (el puerto decide la VLAN).
> 2. **Cambiar la IP** a una de esa red.
>
> Si haces solo una de las dos, **no funciona**.

---

## 1. La tabla (tenla a mano)

| Opción | Área | Cable en | IP del PC | Máscara | Gateway | DNS |
|---|---|---|---|---|---|---|
| 1 | R1 Urgencias | **Switch0 Fa0/1** | 172.16.2.10 | 255.255.255.128 (/25) | 172.16.2.1 | 172.16.3.130 |
| 3 | R2 Hospitalización | **Switch0 Fa0/2** | 172.16.0.10 | 255.255.255.0 (/24) | 172.16.0.1 | 172.16.3.130 |
| 4 | R3 Laboratorio | **Switch1 Fa0/1** | 172.16.3.10 | 255.255.255.192 (/26) | 172.16.3.1 | 172.16.3.130 |
| 5 | R4 Farmacia | **Switch1 Fa0/2** | 172.16.3.138 | 255.255.255.224 (/27) | 172.16.3.129 | 172.16.3.130 |
| 2 | R6 Consulta externa | **Switch2 Fa0/1** | 172.16.1.10 | 255.255.255.0 (/24) | 172.16.1.1 | 172.16.3.130 |
| 6 | R7 Imágenes | **Switch2 Fa0/2** | 172.16.2.138 | 255.255.255.128 (/25) | 172.16.2.129 | 172.16.3.130 |
| 7 | R8 Administración | **Switch3 Fa0/1** | 172.16.3.74 | 255.255.255.192 (/26) | 172.16.3.65 | 172.16.3.130 |
| 8 | R9 Ing. biomédica | **Switch3 Fa0/2** | 172.16.3.170 | 255.255.255.224 (/27) | 172.16.3.161 | 172.16.3.130 |

- **Fa0/1 y Fa0/2** son los puertos de la **izquierda** del switch, **no** el Gi0/1 de la derecha (ese va al router).
- **No uses Fa0/3** de Switch1 ni de Switch3: ahí están los servidores.

## 2. Quién visita qué (2 PCs, 4 rondas)

| Ronda | PC1 (Windows) | PC2 (Ubuntu) |
|---|---|---|
| 1 | Opción **1** · Switch0 Fa0/1 | Opción **2** · Switch2 Fa0/1 |
| 2 | Opción **3** · Switch0 Fa0/2 | Opción **6** · Switch2 Fa0/2 |
| 3 | Opción **4** · Switch1 Fa0/1 | Opción **7** · Switch3 Fa0/1 |
| 4 | Opción **5** · Switch1 Fa0/2 | Opción **8** · Switch3 Fa0/2 |

Si tienen **3 PCs**, el tercero puede hacer las opciones 4 y 7, y así terminan en 3 rondas.

---

# FORMA A · Con scripts (rápida, recomendada)

### PC con Windows
1. Abre la carpeta `scripts\windows` del repositorio.
2. Doble clic en **`recorrido_windows.bat`** → **Sí** cuando pida permisos de administrador.
3. Escribe las áreas que te tocan, por ejemplo `1 3 4 5`, y Enter.
4. El script te dice: **"Mueve el cable de este PC a: Switch0 Fa0/2"**. Mueve el cable y presiona **Enter**.
5. Solo: cambia la IP, prueba el gateway, los routers, el DNS y la página, y guarda la evidencia.
6. Repite el paso 4 por cada área.
7. Al final sale un **resumen** (todo debe decir OK) y te pregunta dónde dejar el PC: escribe `1`.

📁 Las evidencias quedan en `C:\G3_evidencias\`, un archivo por área.

### PC con Ubuntu
```bash
cd ~/red-hospitalaria-g3            # o donde esté el repositorio
sudo bash scripts/linux/recorrido_lan.sh 2 6 7 8
```
1. El script te dice a qué puerto mover el cable → lo mueves → **Enter**.
2. Cambia la IP, prueba y guarda la evidencia solo.
3. Al final: resumen y "¿dónde dejar el PC?" → escribe `2`.

📁 Las evidencias quedan en `evidencias/recorrido_<nombre-del-pc>/`.

### Cambiar a UNA sola área (sin recorrido)
- Windows: `configurar_pc_windows.bat` → escribe el número.
- Ubuntu: `sudo bash scripts/linux/configurar_pc_linux.sh <número>`.

---

# FORMA B · A mano (para entender o si fallan los scripts)

Ejemplo: llevar el PC a **Hospitalización (opción 3)**.

### Paso 1 · Mover el cable
Saca el cable del puerto actual y ponlo en **Switch0 Fa0/2**. Espera a que la luz del puerto se ponga **verde**.

### Paso 2 · Cambiar la IP

**En Windows (con ventanas):**
1. `Windows + R` → escribe `ncpa.cpl` → Enter.
2. Clic derecho en **Ethernet** → **Propiedades**.
3. Doble clic en **Protocolo de Internet versión 4 (TCP/IPv4)**.
4. Marca **"Usar la siguiente dirección IP"** y escribe:
   - Dirección IP: `172.16.0.10`
   - Máscara de subred: `255.255.255.0`
   - Puerta de enlace predeterminada: `172.16.0.1`
   - Servidor DNS preferido: `172.16.3.130`
5. **Aceptar** → **Aceptar**.

**En Windows (con comandos):** abre **cmd como administrador** y escribe:
```
netsh interface ip set address name="Ethernet" static 172.16.0.10 255.255.255.0 172.16.0.1
netsh interface ip set dns name="Ethernet" static 172.16.3.130
ipconfig /flushdns
```
| Comando | Qué hace |
|---|---|
| `netsh interface ip set address … static IP MÁSCARA GATEWAY` | Pone la IP fija |
| `netsh interface ip set dns … static 172.16.3.130` | Pone el DNS del hospital |
| `ipconfig /flushdns` | Borra los nombres guardados de antes |

> Si la tarjeta no se llama "Ethernet", mira el nombre con `ipconfig` (por ejemplo, "Ethernet 2").

**En Ubuntu (con comandos):**
```bash
nmcli con show                       # mira el nombre de tu conexión de cable (ej. "G3-2")
sudo nmcli con mod "G3-2" ipv4.addresses 172.16.0.10/24 ipv4.gateway 172.16.0.1 ipv4.dns 172.16.3.130
sudo nmcli con up "G3-2"
```
| Comando | Qué hace |
|---|---|
| `nmcli con show` | Lista las conexiones de red |
| `nmcli con mod … ipv4.addresses IP/prefijo ipv4.gateway GW` | Cambia la IP y el gateway |
| `nmcli con up` | Aplica el cambio |

### Paso 3 · Comprobar (en este orden)
```
ipconfig                         (Windows)  /  ip -4 addr   (Ubuntu)
ping 172.16.0.1                  ← el gateway del área: lo MÁS importante
ping 172.16.3.130                ← el servidor DNS
nslookup www.hospital.local      ← debe responder 172.16.3.66
```
Y abre **http://www.hospital.local** en el navegador.

| Resultado | Significa |
|---|---|
| Responde el gateway | Puerto, VLAN, trunk y subinterfaz de esa área ✔ |
| Responde el DNS | Las rutas estáticas hasta Router1 ✔ |
| nslookup da 172.16.3.66 | El DNS ✔ |
| La página carga | Las rutas hasta Router3 y el HTTP ✔ |

### Paso 4 · Evidencia
Toma una **captura** de la consola con los pings y del navegador con la página. Nómbrala con el área, por ejemplo `R2_Hospitalizacion.png`.

### Paso 5 · Siguiente área
Vuelve al **Paso 1** con la siguiente opción de tu ronda.

---

## Si algo falla

| Problema | Qué revisar |
|---|---|
| **No responde el gateway** | 1) ¿El cable está en el puerto correcto (izquierda, Fa0/1 o Fa0/2)? 2) ¿La luz del puerto está verde? 3) ¿Escribiste bien la IP y la máscara? 4) ¿Apagaste el Wi-Fi? |
| Responde el gateway pero no el DNS | En los routers: `show ip route` (deben salir 6 rutas S) |
| Responde el DNS pero nslookup falla | En el servidor DNS: `sudo systemctl status dnsmasq` |
| nslookup bien pero la página no carga | Quita el proxy del navegador; escribe `http://` completo |
| Windows tarda | Espera 5–10 segundos después de cambiar la IP |

También pueden correr `diagnostico_windows.bat` o `bash scripts/linux/diagnostico.sh`: dicen en qué paso está el problema.

## Qué decirle al profesor mientras lo hacen
> "Cada área es una red distinta con su propio gateway. Movemos el cable al puerto de la VLAN de esa área, porque el puerto es el que decide la VLAN, y le ponemos al PC una IP de esa red. Si responde el gateway, funcionan el puerto, la VLAN, el trunk 802.1Q y la subinterfaz. Si carga la página por nombre, funcionan también las rutas estáticas, el DNS y el HTTP."

## Al terminar
Dejen **PC1 en la opción 1** (Switch0 Fa0/1) y **PC2 en la opción 2** (Switch2 Fa0/1), como está en el informe.
