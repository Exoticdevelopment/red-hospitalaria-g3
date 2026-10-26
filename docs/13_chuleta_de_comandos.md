# 13 · Chuleta de comandos

## Cisco IOS · general
| Comando | Qué hace |
|---|---|
| `enable` | Modo privilegiado (`#`) |
| `configure terminal` (`conf t`) | Modo configuración |
| `end` / `exit` | Volver a `#` / subir un nivel |
| `hostname X` | Nombre del equipo |
| `no ip domain-lookup` | No traducir comandos mal escritos |
| `copy running-config startup-config` | **Guardar** (Enter en la pregunta) |
| `write erase` | Borrar la configuración guardada |
| `reload` | Reiniciar |
| `terminal length 0` | Mostrar todo sin `--More--` |
| `show running-config` | Ver la configuración actual |
| `show cdp neighbors` | Qué hay al otro lado de cada cable |
| `no <comando>` | Deshacer ese comando |
| `do <show…>` | Correr un show desde `(config)#` |

## Switch
| Comando | Qué hace |
|---|---|
| `vlan 210` → `name X` | Crear una VLAN |
| `interface fa0/1` | Entrar a un puerto |
| `switchport mode access` | Puerto para PC (1 VLAN) |
| `switchport access vlan 210` | En qué VLAN queda el puerto |
| `switchport mode trunk` | Puerto con varias VLAN etiquetadas |
| `switchport trunk allowed vlan 210,220` | Qué VLAN pasan por el trunk |
| `spanning-tree portfast` | Puerto de PC listo al instante |
| `interface range fa0/1 - 4` | Varios puertos a la vez |
| `delete flash:vlan.dat` | Borrar las VLAN |
| `show vlan brief` | Puertos por VLAN |
| `show interfaces trunk` | Estado de los trunks |
| `show interfaces status` | Estado de todos los puertos |

## Router
| Comando | Qué hace |
|---|---|
| `interface gi0/0` → `no ip address` → `no shutdown` | Física del trunk, encendida y sin IP |
| `interface gi0/0.210` | Crear subinterfaz |
| `encapsulation dot1Q 210` | Atender la VLAN 210 |
| `ip address 172.16.2.1 255.255.255.128` | Poner IP |
| `ip route RED MÁSCARA SALTO` | Ruta estática |
| `config-register 0x2102` | Arranque normal |
| `show ip interface brief` | IP y estado de cada interfaz |
| `show ip route` | Tabla de rutas (C, L, S) |
| `show version \| include register` | Ver el config-register |
| `ping IP` | Probar (`!` = sí, `.` = no) |
| `traceroute IP` | Ver el camino |

## Windows (cmd)
| Comando | Qué hace |
|---|---|
| `ipconfig` / `ipconfig /all` | Ver IP, máscara, gateway, DNS |
| `ping 172.16.2.1` | Probar |
| `tracert -d 172.16.3.66` | Camino, sin traducir nombres |
| `nslookup www.hospital.local` | Probar DNS |
| `ipconfig /flushdns` | Borrar caché DNS |
| `ncpa.cpl` (Win+R) | Abrir las conexiones de red |

## Ubuntu
| Comando | Qué hace |
|---|---|
| `ip -4 addr` / `ip route` | Ver IP y gateway |
| `ping -c 4 IP` | Probar 4 veces |
| `traceroute -n IP` / `tracepath -n IP` | Camino |
| `nslookup NOMBRE` / `getent hosts NOMBRE` | DNS / cómo resuelve el sistema |
| `curl http://www.hospital.local` | Pedir la página |
| `nmcli con show` | Perfiles de red |
| `nmcli radio wifi off` | Apagar Wi-Fi |
| `sudo systemctl status dnsmasq` / `apache2` | Estado del servidor |
| `sudo ss -lunp \| grep :53` / `sudo ss -ltnp \| grep :80` | Quién usa el puerto |
| `sudo picocom -b 9600 --flow n /dev/ttyUSB0` | Consola Cisco (salir: Ctrl+A, Ctrl+X) |

## Scripts del repositorio
| Script | Uso |
|---|---|
| `preparar_con_internet.sh` | Instala todo, **con internet**, antes del lab |
| `cisco_auto.py Equipo [--borrar] [--evidencia]` | Configura o saca evidencia de un equipo Cisco |
| `configurar_pc_linux.sh 1..8\|dns\|http\|restaurar` | IP de un PC Ubuntu |
| `servidor_dns.sh` / `servidor_http.sh` | Montar los servidores |
| `mini_dns.py` | DNS de respaldo en Python |
| `diagnostico.sh` | ¿Dónde falla? (Ubuntu) |
| `pruebas.sh` | Pruebas finales + evidencia (Ubuntu) |
| `configurar_pc_windows.bat` | IP de un PC Windows (menú 1..8, R) |
| `diagnostico_windows.bat` | ¿Dónde falla? (Windows) |
| `pruebas_windows.bat` | Pruebas finales + evidencia (Windows) |
