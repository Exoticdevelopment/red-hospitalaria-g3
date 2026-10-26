# 05 · Routers: comando por comando

Cada router (Cisco 2901) hace tres cosas:
1. Es el **gateway** de las 2 VLAN de su switch (Router-on-a-Stick con subinterfaces).
2. Se conecta a los otros routers por la red **R5** (172.16.3.192/29) a través de Switch4.
3. Sabe llegar a las otras 6 LAN con **rutas estáticas**.

| Router | Subinterfaz A | Subinterfaz B | Gi0/1 (R5) |
|---|---|---|---|
| Router0 | Gi0/0.210 → 172.16.2.1 /25 | Gi0/0.220 → 172.16.0.1 /24 | 172.16.3.193 |
| Router1 | Gi0/0.230 → 172.16.3.1 /26 | Gi0/0.240 → 172.16.3.129 /27 | 172.16.3.194 |
| Router2 | Gi0/0.250 → 172.16.1.1 /24 | Gi0/0.260 → 172.16.2.129 /25 | 172.16.3.195 |
| Router3 | Gi0/0.270 → 172.16.3.65 /26 | Gi0/0.280 → 172.16.3.161 /27 | 172.16.3.196 |

El ejemplo usa **Router0**. Para los otros, cambia los valores con esta tabla o usa `configs/RouterN.ios`.

---

## Paso 0 · Cuidado al borrar routers

En los routers **NO** recomendamos `write erase` + `reload` con la consola conectada: dos routers se quedaron en un bucle `ROMMON initialized`. Si el router trae configuración vieja, mejor **sobrescribir** encima y borrar lo que sobre (por ejemplo, rutas viejas con `no ip route …`).

Si de verdad hay que borrar:
1. `write erase` → Enter, `reload` → `no` a Save → Enter.
2. **Desconecta el cable de consola** mientras arranca.
3. Espera la luz SYS **verde fija** (3 min) y vuelve a conectar.
4. A la pregunta `initial configuration dialog` responde **`no`**.

## Paso 1 · Nombre y arranque normal

```
enable
configure terminal
hostname Router0
no ip domain-lookup
config-register 0x2102
```

| Comando | Qué hace |
|---|---|
| `hostname Router0` | Nombre del equipo |
| `no ip domain-lookup` | No intenta traducir comandos mal escritos como nombres |
| `config-register 0x2102` | Arranque **normal**: al prender carga la configuración guardada. Si estuviera en `0x2142` (modo para recuperar contraseñas), **ignoraría** lo guardado (nos pasó en Router2) |

## Paso 2 · La interfaz física del trunk (sin IP)

```
interface GigabitEthernet0/0
 description TRUNK_A_SWITCH0
 no ip address
 no shutdown
exit
```

| Comando | Qué hace |
|---|---|
| `interface GigabitEthernet0/0` | El puerto que va al switch de acceso |
| `no ip address` | La física **no** lleva IP: solo transporta. Las IP van en las subinterfaces |
| `no shutdown` | **Enciende** el puerto. En los routers vienen **apagados** de fábrica. Si la física está apagada, las subinterfaces también |

## Paso 3 · Las subinterfaces (los gateways)

```
interface GigabitEthernet0/0.210
 encapsulation dot1Q 210
 ip address 172.16.2.1 255.255.255.128
exit
interface GigabitEthernet0/0.220
 encapsulation dot1Q 220
 ip address 172.16.0.1 255.255.255.0
exit
```

| Comando | Qué hace |
|---|---|
| `interface GigabitEthernet0/0.210` | Crea una interfaz **virtual** dentro de Gi0/0. El `.210` es solo un nombre (por costumbre igual a la VLAN) |
| `encapsulation dot1Q 210` | **Lo importante:** esta subinterfaz atiende las tramas con etiqueta **VLAN 210**. Si el número no coincide con la VLAN del switch, no funciona |
| `ip address 172.16.2.1 255.255.255.128` | La IP del **gateway** de Urgencias (primer host de 172.16.2.0/25) |

> El `encapsulation` va **antes** que la IP: sin él, el router no deja poner la IP en la subinterfaz.

## Paso 4 · La interfaz de tránsito (R5)

```
interface GigabitEthernet0/1
 description R5_TRANSITO
 ip address 172.16.3.193 255.255.255.248
 no shutdown
exit
```

| Comando | Qué hace |
|---|---|
| `ip address 172.16.3.193 255.255.255.248` | La IP de Router0 en la red de tránsito (/29 = máscara .248) |
| `no shutdown` | Encender |

## Paso 5 · Las 6 rutas estáticas

**Formato:** `ip route <red destino> <máscara> <siguiente salto>`

**Cómo se deducen:** de las 8 LAN, quita las 2 propias. Para cada una de las otras 6, el siguiente salto es la IP en R5 del router **dueño** de esa LAN.

| LAN | Red | Dueño | Siguiente salto |
|---|---|---|---|
| R1 Urgencias | 172.16.2.0/25 | Router0 | 172.16.3.193 |
| R2 Hospitalización | 172.16.0.0/24 | Router0 | 172.16.3.193 |
| R3 Laboratorio | 172.16.3.0/26 | Router1 | 172.16.3.194 |
| R4 Farmacia | 172.16.3.128/27 | Router1 | 172.16.3.194 |
| R6 Consulta | 172.16.1.0/24 | Router2 | 172.16.3.195 |
| R7 Imágenes | 172.16.2.128/25 | Router2 | 172.16.3.195 |
| R8 Administración | 172.16.3.64/26 | Router3 | 172.16.3.196 |
| R9 Ing. biomédica | 172.16.3.160/27 | Router3 | 172.16.3.196 |

Router0 es dueño de R1 y R2, así que necesita rutas hacia las otras 6:

```
ip route 172.16.3.0   255.255.255.192 172.16.3.194
ip route 172.16.3.128 255.255.255.224 172.16.3.194
ip route 172.16.1.0   255.255.255.0   172.16.3.195
ip route 172.16.2.128 255.255.255.128 172.16.3.195
ip route 172.16.3.64  255.255.255.192 172.16.3.196
ip route 172.16.3.160 255.255.255.224 172.16.3.196
```

Lectura de la primera: *"Para llegar a 172.16.3.0/26 (Laboratorio), entrégaselo a 172.16.3.194 (Router1)"*.

> **Ojo:** en la ruta va la **dirección de red** (172.16.3.0), no una IP de host (172.16.3.10). Si pones una IP que no es de red, el router la corrige o la rechaza.

## Paso 6 · Guardar

```
end
copy running-config startup-config
```
En `Destination filename [startup-config]?` → **solo Enter**. Debe salir `[OK]`.

## Paso 7 · Verificar

```
show ip interface brief
show ip route
show cdp neighbors
show version | include register
ping 172.16.3.194
```

| Comando | Qué debe mostrar |
|---|---|
| `show ip interface brief` | Gi0/0, Gi0/0.210, Gi0/0.220 y Gi0/1 en **up up**, cada una con su IP |
| `show ip route` | **3 C** (las 2 LAN y R5), **3 L** (las IP propias /32) y **6 S** (estáticas) |
| `show cdp neighbors` | Gi0/0 → Switch0 Gig 0/1 y Gi0/1 → Switch4 Fas 0/1. **Así se confirma que los cables están bien** |
| `show version \| include register` | `Configuration register is 0x2102` |
| `ping 172.16.3.194` | `!!!!!` = 5 respuestas. `.....` = no responde |

**Cómo leer `show ip route`:**
```
C   172.16.2.0/25 is directly connected, GigabitEthernet0/0.210   ← red propia
L   172.16.2.1/32 is directly connected, GigabitEthernet0/0.210   ← la IP del router
S   172.16.3.64/26 [1/0] via 172.16.3.196                         ← ruta estática
```
`[1/0]` = distancia administrativa 1 (las estáticas valen 1) / métrica 0.

**Estados de `show ip interface brief`:**
| Status / Protocol | Significa |
|---|---|
| up / up | Todo bien |
| administratively down / down | Falta `no shutdown` |
| down / down | No hay cable, o el otro lado está apagado |
| up / down | Problema de capa 2 (raro en Ethernet) |

## Quitar cosas que dejaron otros

```
show running-config | include ip route        ← ver todas las rutas
configure terminal
no ip route 192.168.50.0 255.255.255.0 192.168.60.1   ← "no" + la línea exacta = borrarla
end
copy running-config startup-config
```
En general, **`no` + el mismo comando** deshace cualquier cosa.

Contraseñas que dejaron otros (si el profe no las quiere):
```
configure terminal
no enable secret
no enable password
line console 0
 no password
 no login
end
copy running-config startup-config
```

## Con el script

```bash
sudo python3 scripts/linux/cisco_auto.py Router0              # sin --borrar en routers
sudo python3 scripts/linux/cisco_auto.py Router0 --evidencia  # guarda los show en Router0_evidencia.txt
```
El script **genera las 6 rutas solo**: toma la lista de las 8 LAN y quita las que tienen como siguiente salto al propio router. Así no hay errores de digitación.
