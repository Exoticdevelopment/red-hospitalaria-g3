# 01 · Conceptos para dummies

Antes de tocar un cable hay que entender **8 ideas**. Cada una tiene una comparación con la vida real.

---

## 1. Dirección IP — "la dirección de la casa"

Cada equipo de la red tiene una **dirección IP**, como cada casa tiene una dirección. Ejemplo: `172.16.2.10`.

- Son **4 números** del 0 al 255 separados por puntos. Cada número se llama **octeto** (8 bits).
- En total son **32 bits**.
- Dos equipos en la misma red **no pueden** tener la misma IP (como dos casas con la misma dirección: el cartero no sabría a cuál ir).

Usamos direcciones **privadas** (RFC 1918): sirven dentro de una organización y no salen a internet. Los tres rangos privados son:

| Rango | Antigua "clase" |
|---|---|
| 10.0.0.0/8 | A |
| **172.16.0.0/12** ← el que usamos | B |
| 192.168.0.0/16 | C |

## 2. Máscara y prefijo — "qué parte es el barrio y qué parte es la casa"

Una IP tiene dos partes: la **red** (el barrio) y el **host** (la casa). La **máscara** dice dónde termina el barrio.

```
IP:       172.16.2.10
Máscara:  255.255.255.128   (= /25)
          └──── red (25 bits) ────┘└host (7 bits)┘
```

- **/25** significa "los primeros 25 bits son de red". Se llama **prefijo**.
- Los bits que sobran (32 − 25 = **7**) son para los equipos.
- Con 7 bits hay 2⁷ = **128** direcciones. Se restan 2 (la de red y la de broadcast) y quedan **126 útiles**.

| Prefijo | Máscara | Direcciones | Útiles (−2) |
|---|---|---|---|
| /22 | 255.255.252.0 | 1024 | 1022 |
| /24 | 255.255.255.0 | 256 | 254 |
| /25 | 255.255.255.128 | 128 | 126 |
| /26 | 255.255.255.192 | 64 | 62 |
| /27 | 255.255.255.224 | 32 | 30 |
| /29 | 255.255.255.248 | 8 | 6 |
| /30 | 255.255.255.252 | 4 | 2 |

**¿Por qué se restan 2?**
- La **primera** dirección es el **nombre de la red** (ej. 172.16.2.0). No se le pone a nadie.
- La **última** es el **broadcast** (ej. 172.16.2.127): un mensaje a esa IP le llega a **todos** los de la red. Tampoco se le pone a nadie.

## 3. Gateway (puerta de enlace) — "la puerta del barrio"

Si un PC quiere hablar con alguien de **su misma red**, le habla directo. Si es de **otra red**, le manda el paquete a la **puerta de enlace**: el router.

- En este examen el gateway de cada red es su **primera IP útil** (ej. 172.16.2.1 para Urgencias).
- Esa IP vive en el **router**, en una **subinterfaz** (ver punto 5).

> Si un PC tiene mal el gateway, puede hablar con sus vecinos pero **con nadie de afuera**.

## 4. VLAN — "dividir un edificio en oficinas cerradas"

Un switch normal deja que todos sus puertos se hablen. Una **VLAN** (red de área local virtual) divide el switch en grupos **aislados**, como poner paredes dentro de un edificio.

- Switch0 tiene la VLAN **210** (Urgencias) en el puerto Fa0/1 y la **220** (Hospitalización) en Fa0/2.
- Un PC en la 210 **no ve** a uno en la 220, aunque estén en el mismo switch.
- Para que dos VLAN se hablen se necesita un **router** (capa 3).

Cada VLAN es un **dominio de broadcast** distinto: el "grito" (broadcast) de un PC solo lo oye su VLAN.

## 5. Trunk, 802.1Q y Router-on-a-Stick — "un solo tubo con mensajes etiquetados"

**Puerto access:** lleva **una sola** VLAN. Es donde se conecta un PC. El PC no sabe nada de VLAN.

**Puerto trunk:** lleva **varias** VLAN por el mismo cable. Para saber de qué VLAN es cada mensaje (trama), el switch le pega una **etiqueta** de 4 bytes con el número de la VLAN. Ese estándar de etiquetas se llama **IEEE 802.1Q** (o "dot1Q").

**Router-on-a-Stick ("router en un palo"):** en vez de usar un cable por VLAN, el router usa **un solo cable** trunk (Gi0/0) y lo divide en **subinterfaces** virtuales:

```
Router0 Gi0/0 (sin IP, solo transporta)
   ├── Gi0/0.210 → etiqueta 210 → IP 172.16.2.1  (gateway de Urgencias)
   └── Gi0/0.220 → etiqueta 220 → IP 172.16.0.1  (gateway de Hospitalización)
```

Así, el router recibe la trama de la VLAN 210, le quita la etiqueta, la **enruta** y la manda por donde corresponda.

## 6. Rutas estáticas — "el mapa que le damos al router a mano"

Un router **solo conoce** las redes que tiene conectadas (las marca con **C**). Para llegar a las demás necesita una **ruta**.

- **Ruta estática** = la escribimos a mano: "para llegar a la red X, mándalo al router Y".
- El examen **prohíbe** RIP, OSPF y EIGRP (rutas automáticas). Por eso todas son estáticas.

```
ip route 172.16.3.64 255.255.255.192 172.16.3.196
         └─ red destino ─┘ └─ máscara ─┘ └ siguiente salto ┘
"Para llegar a Administración (172.16.3.64/26), mándaselo a Router3 (172.16.3.196)"
```

- Cada router tiene 2 LAN propias + R5 = 3 redes conectadas.
- Hay 8 LAN en total, así que le faltan **6** → **6 rutas estáticas por router**, **24 en total**.
- El **siguiente salto** tiene que ser una IP que el router **ya alcance**: por eso siempre es la IP de otro router en **R5**.
- La ruta de **regreso** también hace falta: si A sabe llegar a B pero B no sabe volver a A, el ping falla.

## 7. Red de tránsito R5 y el switch central — "la autopista entre barrios"

Los 4 routers se conectan entre sí por un **switch central** (Switch4). Esa red se llama **R5** y solo tiene **routers**, no PCs.

- Necesita **4 IP** (una por router): 172.16.3.193, .194, .195, .196.
- Un **/30** solo da 2 IP útiles → no alcanza.
- Un **/29** da 6 útiles → **sí alcanza**. Por eso R5 es 172.16.3.192/29.
- Switch4 **no necesita VLAN ni trunks**: todo va en la VLAN 1. Los paquetes que pasan por ahí ya los "desetiquetó" el router.

## 8. DNS y HTTP — "la guía telefónica y la página web"

**DNS (Domain Name System):** traduce **nombres** a **IP**, como una guía telefónica.
- Le preguntas "¿cuál es la IP de `www.hospital.local`?" y responde `172.16.3.66`.
- Esa línea de la guía se llama **registro A** (A = Address, dirección IPv4).
- Usa el puerto **UDP 53**.
- Nuestro DNS está en **172.16.3.130** (Farmacia).

**HTTP:** el protocolo de las páginas web. El servidor (Apache) entrega la página cuando el navegador la pide.
- Usa el puerto **TCP 80**.
- Nuestro servidor web está en **172.16.3.66** (Administración).

**El viaje completo** cuando PC1 escribe `http://www.hospital.local`:
1. PC1 pregunta al DNS (172.16.3.130): "¿IP de www.hospital.local?". El paquete va de Router0 a Router1.
2. El DNS responde: "172.16.3.66".
3. PC1 le pide la página a 172.16.3.66. El paquete va de Router0 a Router3.
4. Apache le devuelve la página.

---

## Otros términos que salen en el examen

| Término | Qué es, en una línea |
|---|---|
| **TTL** | Contador que baja 1 en cada router. Windows arranca en 128: si llega con 126, pasó por 2 routers. Linux arranca en 64: 62 = 2 routers. |
| **CDP** | Protocolo de Cisco que dice qué equipo y qué puerto hay al otro lado de cada cable. |
| **Running-config** | La configuración que está **funcionando ahora** (en RAM). Se borra al apagar. |
| **Startup-config** | La configuración **guardada** (en NVRAM). Se carga al prender. |
| **Config-register** | Número que le dice al router cómo arrancar. 0x2102 = normal; 0x2142 = ignora la configuración guardada. |
| **Portfast** | Hace que un puerto de PC funcione al instante, sin esperar 30 s del protocolo STP. |
| **STP** | Spanning Tree: evita bucles entre switches. |
| **Capa 1/2/3/7** | Modelo OSI: 1 = cable, 2 = switch/VLAN, 3 = IP/router, 7 = aplicación (DNS, HTTP). |
| **ICMP / ping** | Mensajes de prueba: "¿estás ahí?" (echo request) → "sí" (echo reply). |
| **Auto-MDIX** | Los equipos modernos detectan el tipo de cable solos: ya no hacen falta cables cruzados. |

## Resumen en una tabla

| Pieza | Capa | Dónde está | Qué hace |
|---|---|---|---|
| Cable | 1 | Entre equipos | Lleva la señal |
| VLAN | 2 | Switches 0–3 | Separa las áreas |
| Trunk 802.1Q | 2 | Switch Gi0/1 ↔ Router Gi0/0 | Lleva 2 VLAN etiquetadas por un cable |
| Subinterfaz | 3 | Router Gi0/0.XXX | Es el gateway de cada VLAN |
| R5 /29 | 3 | Routers Gi0/1 + Switch4 | Une los 4 routers |
| Rutas estáticas | 3 | Routers | Les dicen cómo llegar a las otras LAN |
| DNS | 7 | 172.16.3.130 | Nombre → IP |
| HTTP | 7 | 172.16.3.66 | Entrega la página web |
