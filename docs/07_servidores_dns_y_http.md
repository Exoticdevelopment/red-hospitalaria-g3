# 07 · Servidores DNS y HTTP

| Servidor | IP | Red / VLAN | Puerto del switch | Programa | Puerto de red |
|---|---|---|---|---|---|
| DNS | 172.16.3.130/27 | R4 Farmacia / 240 | Switch1 Fa0/3 | dnsmasq | UDP 53 |
| HTTP | 172.16.3.66/26 | R8 Administración / 270 | Switch3 Fa0/3 | Apache | TCP 80 |

Los dos son PCs con **Ubuntu**.

## Antes del examen (con internet)

Una vez conectados a la red del lab **ya no hay internet**, así que hay que instalar antes:
```bash
git clone https://github.com/Exoticdevelopment/red-hospitalaria-g3.git
cd red-hospitalaria-g3
sudo bash scripts/linux/preparar_con_internet.sh
```
Si no se pudo instalar, **no pasa nada**: los scripts tienen un **plan B en Python** (que viene con Ubuntu).

---

## Servidor DNS

### Con el script
```bash
sudo bash scripts/linux/servidor_dns.sh
```

### Qué hace el script, paso a paso
1. **Pone la IP** 172.16.3.130/27, gateway 172.16.3.129 (usa `configurar_pc_linux.sh dns`).
2. **Libera el puerto 53.** Solo un programa puede usarlo. Ubuntu trae `systemd-resolved` ocupándolo, y otro grupo pudo dejar `bind9`. El script los apaga.
3. **Abre el firewall** (si `ufw` está activo) para el puerto 53.
4. **Aparta las configuraciones de otros grupos** de `/etc/dnsmasq.d/` (las mueve a `/root/g3_backup`, no las borra).
5. **Escribe la configuración** en `/etc/dnsmasq.d/hospital.conf`:
   ```
   listen-address=172.16.3.130          ← responde solo en esta IP
   bind-interfaces                      ← se amarra a esa IP, no choca con otros
   no-resolv                            ← no pregunta a internet (no hay)
   address=/www.hospital.local/172.16.3.66   ← EL REGISTRO A
   log-queries                          ← anota cada pregunta (evidencia)
   ```
6. `dnsmasq --test` revisa que no haya errores y **arranca** el servicio.
7. **Prueba:** `nslookup www.hospital.local 172.16.3.130` → debe responder `172.16.3.66`.

**Plan B:** si dnsmasq no está instalado y no hay internet, el script abre `mini_dns.py`, un DNS pequeño escrito en Python que responde el mismo registro A. Hay que dejar esa terminal **abierta**.

### Comandos útiles en el servidor DNS
| Comando | Para qué |
|---|---|
| `sudo systemctl status dnsmasq` | ¿Está corriendo? (debe decir `active (running)`) |
| `sudo ss -lunp \| grep :53` | ¿Quién escucha en el puerto 53? |
| `sudo journalctl -u dnsmasq -f` | Ver en vivo quién pregunta qué (muy bueno para mostrarle al profe) |
| `nslookup www.hospital.local 172.16.3.130` | Probar |

> En la prueba sale un `REFUSED` o `can't find` para la consulta **AAAA** (IPv6). Es **normal**: la red es solo IPv4 y no existe registro AAAA. Lo que importa es la línea `Address: 172.16.3.66`.

---

## Servidor HTTP

### Con el script
```bash
sudo bash scripts/linux/servidor_http.sh
# o con otro grupo/integrantes (todos los nombres dentro de UNAS SOLAS comillas):
sudo bash scripts/linux/servidor_http.sh "Grupo 3" "Nombre1, Nombre2, Nombre3"
```

### Qué hace el script, paso a paso
1. **Pone la IP** 172.16.3.66/26, gateway 172.16.3.65.
2. **Libera el puerto 80** (apaga nginx, lighttpd u otro servidor web que haya dejado alguien).
3. **Abre el firewall** para el puerto 80.
4. **Crea la página** que pide el examen: identifica al **grupo** y a la **red** (IP, VLAN, gateway, DNS).
5. Guarda una copia de la página que había (`/root/g3_backup/index.html.antes`).
6. La publica en `/var/www/html/index.html` y **reinicia Apache**.
7. **Prueba:** `curl http://172.16.3.66` debe mostrar `<h1>Red hospitalaria G3</h1>`.

**Plan B:** si Apache no está y no hay internet, usa `python3 -m http.server 80`, el servidor web que viene con Python. Hay que dejar la terminal **abierta**.

### Comandos útiles en el servidor HTTP
| Comando | Para qué |
|---|---|
| `sudo systemctl status apache2` | ¿Está corriendo? |
| `sudo ss -ltnp \| grep :80` | ¿Quién escucha en el puerto 80? |
| `sudo tail -f /var/log/apache2/access.log` | Ver en vivo quién pide la página (evidencia) |
| `curl http://172.16.3.66` | Probar por IP |

---

## Por qué DNS y HTTP están en redes distintas

El examen lo pide así (DNS en R4, HTTP en R8) para comprobar que **todo** funciona junto: cuando PC1 abre la página, el tráfico pasa por **3 routers distintos** (Router0 → Router1 para el DNS, Router0 → Router3 para el HTTP). Si una sola ruta está mal, falla.
