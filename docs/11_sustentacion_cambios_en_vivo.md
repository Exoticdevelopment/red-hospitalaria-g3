# 11 · Sustentación: cambios en vivo

La guía dice: *"ejecutar al menos una modificación solicitada por el docente (por ejemplo, cambiar una VLAN de puerto o corregir una ruta), restaurando luego el funcionamiento"*.

**La fórmula para cualquier cambio (dila en voz alta):**
1. **Explicar** qué vas a cambiar y qué esperas que pase.
2. **Hacer** el cambio.
3. **Mostrar** el efecto (`show` + `ping`).
4. **Restaurar** o completar.
5. **Comprobar** que volvió a funcionar y **guardar** (`copy running-config startup-config`).

Practiquen cada escenario al menos una vez. Cada uno toma 2–3 minutos.

---

## Escenario 1 · ⭐ Cambiar un PC a otro puerto del switch

*"Muevan PC1 del puerto Fa0/1 al Fa0/5."*

```
Switch0# configure terminal
Switch0(config)# interface FastEthernet0/5
Switch0(config-if)# switchport mode access
Switch0(config-if)# switchport access vlan 210
Switch0(config-if)# spanning-tree portfast
Switch0(config-if)# no shutdown
Switch0(config-if)# end
Switch0# show vlan brief                  ← Fa0/5 ya aparece en la VLAN 210
```
Mueve el cable del PC de Fa0/1 a Fa0/5 y haz `ping 172.16.2.1` desde PC1 → funciona.

**Qué decir:** "La VLAN la decide el puerto del switch. Como Fa0/5 está en la 210, igual que Fa0/1, el PC no necesita cambiar su IP".

Guardar: `copy running-config startup-config`.

## Escenario 2 · ⭐ Cambiar la VLAN de un puerto (y ver que se rompe)

*"Pongan el puerto de PC1 en la VLAN 220."*

```
Switch0(config)# interface FastEthernet0/1
Switch0(config-if)# switchport access vlan 220
Switch0(config-if)# end
Switch0# show vlan brief                  ← Fa0/1 ahora en 220
```
Desde PC1: `ping 172.16.2.1` → **falla**.

**Qué decir:** "PC1 tiene IP de la red 172.16.2.0/25 (VLAN 210), pero ahora está en la VLAN 220, que es otra red (172.16.0.0/24). Su gateway no está en esa VLAN".

**Dos formas de arreglarlo:**
- **A.** Volver a la VLAN 210: `interface fa0/1` → `switchport access vlan 210`.
- **B.** Cambiarle al PC la IP a una de Hospitalización: `configurar_pc_windows.bat` → opción **3** (172.16.0.10/24, gateway 172.16.0.1).

Comprobar con `ping` y guardar.

## Escenario 3 · ⭐ Quitar y corregir una ruta estática

*"Quiten la ruta hacia Administración en Router0."*

```
Router0# configure terminal
Router0(config)# no ip route 172.16.3.64 255.255.255.192 172.16.3.196
Router0(config)# end
Router0# show ip route                    ← ya no está la S hacia 172.16.3.64/26
```
Desde PC1: la página `http://www.hospital.local` **no carga** (pero `nslookup` **sí** funciona, porque el DNS está en otra red).

**Qué decir:** "Router0 ya no sabe llegar a 172.16.3.64/26. El DNS responde porque su ruta (hacia Router1) sigue bien, pero el tráfico hacia el servidor web no tiene camino".

Restaurar:
```
Router0(config)# ip route 172.16.3.64 255.255.255.192 172.16.3.196
Router0# show ip route                    ← vuelve la S
Router0# copy running-config startup-config
```

## Escenario 4 · Corregir una ruta MAL escrita

*El profe cambia una ruta para que apunte al router equivocado:* `ip route 172.16.3.64 255.255.255.192 172.16.3.194`.

**Cómo encontrarlo:**
1. `tracert -d 172.16.3.66` desde PC1 → el salto 2 es 172.16.3.194 (Router1) y no 172.16.3.196 (Router3).
2. En Router0: `show ip route` → `S 172.16.3.64/26 via 172.16.3.194` ← mal.

**Arreglar:**
```
Router0(config)# no ip route 172.16.3.64 255.255.255.192 172.16.3.194
Router0(config)# ip route 172.16.3.64 255.255.255.192 172.16.3.196
```

**Qué decir:** "El siguiente salto debe ser el router dueño de la red. Administración (R8) está en Router3, que en R5 es la .196".

## Escenario 5 · Apagar el trunk

```
Switch0(config)# interface GigabitEthernet0/1
Switch0(config-if)# shutdown
```
PC1 pierde el gateway. En Router0, `show ip interface brief` → Gi0/0 **down down**.

**Qué decir:** "Las dos VLAN usan el mismo cable trunk. Si se cae, las dos áreas de Router0 se quedan sin gateway".

Restaurar: `no shutdown`.

## Escenario 6 · Quitar una VLAN del trunk

```
Switch0(config)# interface GigabitEthernet0/1
Switch0(config-if)# switchport trunk allowed vlan 220
Switch0# show interfaces trunk            ← solo permite la 220
```
PC1 (VLAN 210) pierde el gateway; Hospitalización sigue funcionando.

Restaurar: `switchport trunk allowed vlan 210,220`.

## Escenario 7 · Agregar un PC en otra área

*"Conecten un PC en Imágenes."*
1. Cable al **Switch2 Fa0/2** (ya está en la VLAN 260).
2. PC Windows: `configurar_pc_windows.bat` → opción **6** (172.16.2.138/25, gateway 172.16.2.129). En Ubuntu: `sudo bash configurar_pc_linux.sh 6`.
3. `ping 172.16.2.129` y abrir `http://www.hospital.local`.

No hay que tocar routers: la red 172.16.2.128/25 ya tenía su subinterfaz y sus rutas.

## Escenario 8 · Cambiar el registro DNS

*"Hagan que `intranet.hospital.local` también abra la página."*

En el servidor DNS:
```bash
echo "address=/intranet.hospital.local/172.16.3.66" | sudo tee -a /etc/dnsmasq.d/hospital.conf
sudo systemctl restart dnsmasq
nslookup intranet.hospital.local 172.16.3.130
```

## Escenario 9 · Cambiar el texto de la página

```bash
sudo nano /var/www/html/index.html       # editar, Ctrl+O guardar, Ctrl+X salir
```
Recargar el navegador (Ctrl+F5). No hace falta reiniciar Apache.

## Escenario 10 · Apagar un router o el DNS: ¿qué se cae?

| Si se apaga… | Se cae | Sigue funcionando |
|---|---|---|
| Router1 | Laboratorio, Farmacia y el **DNS** (nadie resuelve nombres) | Ping por IP entre las demás áreas y la página **por IP** |
| Router3 | Administración (el **HTTP**) e Ing. biomédica | DNS y el resto |
| Switch4 | Toda comunicación **entre** routers | Cada área con su propio gateway |
| Servidor DNS | Los **nombres** | Todo por IP: `http://172.16.3.66` |

---

## Consejos para la sustentación
- **Narren lo que hacen** mientras escriben. El profe evalúa que entiendan, no solo que funcione.
- Si algo sale mal, **no se asusten**: diagnostiquen por capas en voz alta (eso suma puntos).
- Tengan abiertas las consolas de un switch y un router antes de empezar, y el navegador en PC1.
- Al terminar cada cambio: **`copy running-config startup-config`**.
