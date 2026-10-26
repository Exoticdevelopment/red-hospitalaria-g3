# 10 · Preguntas que puede hacer el profesor (con respuesta)

**Cómo estudiar:** tapa la respuesta, contesta en voz alta y luego compara. Cada integrante debe poder contestar **todas**. Las marcadas con ⭐ son las más probables.

Están ordenadas según los puntos del examen: Excel/subnetting 25 · VLAN 10 · 802.1Q 20 · rutas/R5 20 · DNS/HTTP 10 · IOS 10 · pruebas 5.

---

## A. Bloque, subnetting y Excel (25 puntos)

**1. ⭐ ¿Por qué escogieron 172.16.0.0/22?**
Porque es privado (está dentro de 172.16.0.0/12, RFC 1918) y no es la IP que traen los equipos. Las 9 redes suman 968 direcciones: un /23 da 512 y no alcanza, un /22 da 1024 y sí. Es el bloque más pequeño que sirve.

**2. ⭐ ¿Qué es VLSM?**
Máscara de longitud variable: a cada red se le da el tamaño que necesita (/24, /25, /27…) en vez de que todas tengan la misma. Así no se desperdician direcciones.

**3. ⭐ ¿Por qué se ordena de mayor a menor?**
Para que cada red quede alineada (empiece en un múltiplo de su tamaño). Si se pone primero una pequeña, la grande que sigue queda "torcida" y se solapa o se desperdicia espacio.

**4. ⭐ ¿Cómo calcularon cuántos bits de host necesita una red?**
Hosts + 2 (red y broadcast), y se busca la potencia de 2 que alcance. Hospitalización: 200 + 2 = 202 → 2⁸ = 256 → 8 bits → /24. En el Excel: `=ROUNDUP(LOG(C2+2,2),0)`.

**5. ¿Por qué se suman 2 a los hosts?**
Porque la primera dirección es la de red y la última es el broadcast, y no se le pueden asignar a ningún equipo.

**6. ⭐ ¿Por qué R5 es /29 y no /30?**
R5 necesita 4 IP (una por router). Un /30 da 2 útiles; un /29 da 6. El examen además pide "al menos /29".

**7. ¿Por qué Farmacia es /27 si pide exactamente 30?**
Un /27 da 32 direcciones − 2 = 30 útiles, justo lo pedido. El enunciado dice que el gateway y el DNS cuentan dentro de esos 30 (quedan 28 para PCs).

**8. ⭐ Calcula red, broadcast y rango de 172.16.3.128/27.**
Tamaño 32. Red .128, broadcast .128 + 31 = .159, hosts de .129 a .158. Gateway .129, DNS .130.

**9. Calcula lo mismo para 172.16.2.128/25.**
Tamaño 128. Red .2.128, broadcast .2.255, hosts .2.129 a .2.254. Es Imágenes, gateway .2.129.

**10. ¿Cuál es la máscara de un /26 en binario y decimal?**
11111111.11111111.11111111.11000000 = 255.255.255.192. El último octeto: 128 + 64 = 192.

**11. ¿Cuántas direcciones sobran y cuáles son?**
1024 − 968 = 56. De 172.16.3.200 a 172.16.3.255.

**12. ⭐ ¿Qué hace la columna "Red entera" del Excel?**
Convierte la IP en un solo número (172.16.0.0 = 2 886 729 728) para poder sumarle el tamaño de cada red. Luego se vuelve a convertir a formato a.b.c.d dividiendo entre 256³, 256² y 256.

**13. ¿Qué revisa la columna "Alineación"?**
`MOD(red, tamaño) = 0`: que cada red empiece en un múltiplo de su tamaño. Si no, la red está mal calculada.

**14. Si Ingeniería biomédica pidiera 40 hosts en vez de 25, ¿qué cambia?**
Pasaría de /27 a /26 (64 direcciones). Habría que reordenar: iría junto a Administración, antes de Farmacia, y todas las direcciones siguientes se moverían. Igual caben en el /22 (sumaría 1000).

**15. ¿Qué es una dirección privada?**
Una que solo funciona dentro de una organización y no sale a internet directamente: 10/8, 172.16/12 y 192.168/16.

## B. VLAN y asignación de puertos (10 puntos)

**16. ⭐ ¿Qué es una VLAN y para qué sirve?**
Una red virtual que divide un switch en grupos aislados. Cada VLAN es un dominio de broadcast distinto. Sirve para separar áreas (Urgencias de Farmacia) sin comprar un switch por área.

**17. ⭐ ¿Qué decide en qué VLAN está un PC: su IP o el puerto?**
El **puerto del switch** (`switchport access vlan`). La IP tiene que coincidir con esa VLAN, pero quien decide es el puerto.

**18. ⭐ Diferencia entre puerto access y trunk.**
Access: una sola VLAN, sin etiqueta, para PCs. Trunk: varias VLAN con etiqueta 802.1Q, para unir switch con router (o switch con switch).

**19. ¿Por qué hay 8 VLAN y no 9?**
Porque R5 (tránsito) no es una red de usuarios: solo une routers y va en la VLAN 1 de Switch4.

**20. ⭐ ¿Por qué Switch4 no tiene VLAN 210–280 ni trunks?**
Porque por él solo pasan paquetes entre routers, que ya salen sin etiqueta. Es un único dominio de capa 2 para R5. La guía lo dice: "no requiere ocho VLAN".

**21. ¿Qué hace `spanning-tree portfast`?**
Hace que el puerto empiece a funcionar de inmediato, sin esperar unos 30 s de STP. Solo se pone en puertos de PCs y servidores, nunca hacia otro switch (podría causar bucles).

**22. ¿Dónde se guardan las VLAN en el switch?**
En el archivo `flash:vlan.dat`, aparte de la startup-config. Por eso para borrar todo hay que hacer `write erase` **y** `delete flash:vlan.dat`.

**23. ¿Usaron VLAN de administración? ¿Por qué?**
No. El examen dice que solo si se justifica. Configuramos todo por consola, así que no hacía falta darle IP a los switches.

**24. ¿Qué es la VLAN 1?**
La VLAN por defecto: todos los puertos empiezan en ella. También es la VLAN nativa del trunk (la que viaja sin etiqueta). No la usamos para usuarios.

**25. ¿Qué comando muestra qué puerto está en qué VLAN?**
`show vlan brief`. Los puertos trunk no aparecen ahí; se ven con `show interfaces trunk`.

## C. IEEE 802.1Q y subinterfaces (20 puntos)

**26. ⭐ ¿Qué es 802.1Q?**
El estándar que agrega una etiqueta de 4 bytes a la trama Ethernet con el número de VLAN (12 bits: VLAN 1 a 4094). Así un solo cable lleva varias VLAN sin mezclarlas.

**27. ⭐ ¿Qué es Router-on-a-Stick?**
Un router que enruta entre varias VLAN usando **un solo puerto físico** en trunk, dividido en subinterfaces (una por VLAN), cada una con su IP de gateway.

**28. ⭐ ¿Qué hace `encapsulation dot1Q 210`?**
Le dice a la subinterfaz que atienda las tramas con etiqueta VLAN 210. Es lo que une la subinterfaz con la VLAN.

**29. ¿El número después del punto (Gi0/0.210) tiene que ser igual a la VLAN?**
No, es solo un nombre; podría ser Gi0/0.5. Lo que manda es `encapsulation dot1Q 210`. Se pone igual por orden.

**30. ⭐ ¿Por qué Gi0/0 no tiene IP?**
Porque solo es el transporte físico del trunk. Las IP van en las subinterfaces, una por VLAN.

**31. ¿Qué pasa si Gi0/0 está en shutdown?**
Se caen las dos subinterfaces y las dos VLAN pierden su gateway.

**32. ⭐ ¿Por qué el gateway no está en el switch (SVI)?**
El examen lo prohíbe ("no asignar gateways de usuario a SVI de los 2960"). Además el 2960 es un switch de capa 2: el enrutamiento lo hace el router.

**33. ¿Qué pasa si en el router pongo `dot1Q 210` pero en el switch la VLAN es 211?**
No se entienden: las tramas llegan con etiqueta 211 y ninguna subinterfaz las atiende. El PC no llega a su gateway.

**34. ¿Qué pasa si el trunk del switch no permite la VLAN 220?**
Las tramas de la VLAN 220 no pasan al router. Hospitalización pierde el gateway; Urgencias sigue funcionando.

**35. ¿Cómo se ve en el router que las subinterfaces funcionan?**
`show ip interface brief`: Gi0/0.210 y Gi0/0.220 en up up con su IP. Y `show ip route`: las dos redes aparecen como C.

## D. Rutas estáticas y red R5 (20 puntos)

**36. ⭐ ¿Cuántas rutas estáticas hay y por qué?**
6 por router, 24 en total. Hay 8 LAN; cada router tiene 2 propias (conectadas), así que le faltan 6. R5 también es conectada.

**37. ⭐ Explica una ruta: `ip route 172.16.3.64 255.255.255.192 172.16.3.196`.**
"Para llegar a la red 172.16.3.64/26 (Administración, donde está el HTTP), entrégale el paquete a 172.16.3.196 (Router3)".

**38. ⭐ ¿Qué es el siguiente salto y qué condición debe cumplir?**
La IP del router vecino que sabe llegar a la red destino. Tiene que estar en una red **conectada** (aquí R5); si no, el router no sabe cómo alcanzarlo.

**39. ⭐ ¿Por qué hacen falta rutas de regreso?**
Porque la respuesta tiene que volver. Si Router0 sabe ir a R8 pero Router3 no sabe volver a R1, el ping sale pero la respuesta se pierde.

**40. ¿Qué significan C, L y S en `show ip route`?**
C = red conectada directamente. L = la IP propia del router (/32). S = ruta estática.

**41. ¿Qué es `[1/0]`?**
1 = distancia administrativa (qué tan confiable es; las estáticas valen 1). 0 = métrica (costo).

**42. ⭐ ¿Por qué no RIP, OSPF ni EIGRP?**
Lo prohíbe el examen. Además, con 4 routers y redes que no cambian, las estáticas son simples, predecibles y no gastan recursos.

**43. ¿Qué pasa si se cae Router1?**
Se pierden Laboratorio y Farmacia (incluido el DNS): nadie podría resolver nombres. Las demás áreas siguen hablándose por IP. Con estáticas no hay ruta alterna automática.

**44. ¿Se podría resumir las rutas?**
En esta red no. Para resumir, las 2 LAN de un router tendrían que quedar pegadas. Pero el orden VLSM (de mayor a menor) las intercala: Router1 tiene 172.16.3.0/26 y 172.16.3.128/27, y en medio está 172.16.3.64/26, que es de Router3. Un resumen mandaría tráfico al router equivocado. Por eso se usan las 6 rutas específicas.

**45. ¿Qué es una ruta por defecto y la usaron?**
`ip route 0.0.0.0 0.0.0.0 <salto>`: "todo lo que no conozcas, mándalo allá". No la usamos porque no hay salida a internet y el examen pide rutas a las 6 LAN.

**46. ¿Por qué R5 usa un switch y no cables directos entre routers?**
Cada 2901 tiene solo 2 puertos Gigabit y uno ya está en el trunk. Con un switch, los 4 routers quedan en una sola red con un solo cable cada uno.

## E. DNS y HTTP (10 puntos)

**47. ⭐ ¿Qué hace un DNS?**
Traduce nombres a IP, como una guía telefónica: `www.hospital.local` → `172.16.3.66`.

**48. ⭐ ¿Qué es un registro A?**
El registro que asocia un nombre con una dirección **IPv4**. (AAAA es para IPv6.)

**49. ⭐ ¿Qué puertos usan DNS y HTTP?**
DNS: UDP 53 (TCP 53 para respuestas grandes). HTTP: TCP 80. HTTPS: TCP 443.

**50. ¿Qué software usaron?**
DNS: dnsmasq en Ubuntu (línea `address=/www.hospital.local/172.16.3.66`). HTTP: Apache 2 en Ubuntu.

**51. ⭐ ¿Qué prueba `nslookup` y qué no?**
Prueba que el DNS responde el nombre. **No** prueba que la página funcione (para eso, el navegador o curl).

**52. ¿Por qué en nslookup sale "UnKnown" como servidor?**
Porque Windows intenta saber el **nombre** del servidor DNS (búsqueda inversa) y no tenemos zona inversa. No es un error: la respuesta de la IP es correcta.

**53. ¿Por qué sale un REFUSED o "can't find" en la prueba?**
Es la consulta AAAA (IPv6). No hay registro IPv6 porque la red es solo IPv4. Lo importante es `Address: 172.16.3.66`.

**54. ⭐ Si funciona por IP pero no por nombre, ¿qué revisas?**
Que el PC tenga DNS 172.16.3.130, que llegue por ping al DNS, que dnsmasq esté corriendo, que el registro A esté bien, el archivo hosts y la caché DNS. En Ubuntu, el `.local` en `nsswitch.conf`.

**55. ¿Por qué el DNS y el HTTP están en redes distintas?**
Porque así lo pide el examen. Además comprueba todo junto: abrir la página desde PC1 obliga a usar las rutas hacia Router1 (DNS) y hacia Router3 (HTTP).

**56. ¿Qué tiene la página web?**
Identifica al grupo (Grupo 3 y sus integrantes) y la red: IP 172.16.3.66/26, VLAN 270, gateway 172.16.3.65 y DNS 172.16.3.130. Lo pide la guía.

**57. ¿Qué gateway y DNS tienen los servidores?**
DNS: gateway 172.16.3.129, DNS él mismo (172.16.3.130). HTTP: gateway 172.16.3.65, DNS 172.16.3.130.

## F. Configuración IOS (10 puntos)

**58. ⭐ ¿Diferencia entre running-config y startup-config?**
Running: la que está funcionando, en RAM (se pierde al apagar). Startup: la guardada en NVRAM (se carga al prender). Se pasa de una a otra con `copy running-config startup-config`.

**59. ⭐ ¿Qué es el config-register 0x2102? ¿Y 0x2142?**
0x2102: arranque normal (carga la startup-config). 0x2142: ignora la startup-config (sirve para recuperar contraseñas). Nos pasó en Router2.

**60. ¿Qué hace `no ip domain-lookup`?**
Evita que un comando mal escrito se tome como nombre de equipo y el router se quede "Translating…".

**61. ⭐ ¿Para qué sirve `show cdp neighbors`?**
Muestra qué equipo y qué puerto hay al otro lado de cada cable. Así encontramos dos cables mal conectados.

**62. ¿Qué hace `terminal length 0`?**
Que el equipo muestre todo seguido, sin detenerse en `--More--`. Sirve para copiar la configuración completa.

**63. ¿Cómo se borra una línea de la configuración?**
Escribiendo `no` delante del mismo comando. Ej.: `no ip route 192.168.50.0 255.255.255.0 192.168.60.1`.

**64. ¿Cómo dejarían un equipo de fábrica?**
`write erase`, en switches también `delete flash:vlan.dat`, y `reload` respondiendo `no` a guardar.

**65. ¿Qué modos tiene el IOS?**
Usuario (`>`), privilegiado (`#`, con `enable`), configuración global (`(config)#`, con `configure terminal`) y de interfaz (`(config-if)#`).

**66. ¿Qué hace el script `cisco_auto.py`?**
Habla con el equipo por el cable de consola: escribe los comandos letra por letra, espera el prompt correcto, responde las preguntas (`confirm`, contraseñas), configura, guarda y verifica. Las configuraciones las genera con funciones para no tener errores al escribir.

## G. Pruebas y diagnóstico (5 puntos + sustentación)

**67. ⭐ ¿Qué significa TTL=62 en el ping de PC1 a PC2?**
PC2 es Linux, que empieza con TTL 64. Cada router resta 1. 64 − 62 = **2 routers** (Router2 y Router0).

**68. ⭐ Explica el tracert de PC1 al servidor web.**
Salto 1: 172.16.2.1 (gateway de Urgencias, Router0). Salto 2: 172.16.3.196 (Router3 por R5). Salto 3: 172.16.3.66 (el servidor). Router0 usó la ruta estática hacia 172.16.3.64/26.

**69. ⭐ El ping al gateway falla. ¿Qué revisas y en qué orden?**
Cable y luz del puerto → que el cable esté en el puerto correcto → `show vlan brief` (VLAN del puerto) → `show interfaces trunk` → `show ip interface brief` en el router (subinterfaz up y con IP) → IP y máscara del PC.

**70. ¿Por qué Windows no responde el ping aunque esté bien configurado?**
Porque el firewall de Windows bloquea el ping entrante por defecto. Nuestro script agrega la regla G3-ICMP para permitirlo.

**71. ¿Un "up/up" garantiza que el cable está bien?**
No. Nos pasó: Router0 Gi0/1 estaba up/up pero conectado a Switch2 en vez de Switch4. Solo CDP lo mostró.

**72. ⭐ ¿Cuántos PCs usaron y por qué no 200?**
4 equipos: 2 servidores obligatorios y 2 PCs de prueba en áreas de routers distintos. La guía dice que los hosts son "capacidad de direccionamiento, no cantidad de PCs físicos".

**73. ¿Qué evidencia entregan?**
Excel con fórmulas, configuración de los 9 equipos (`show running-config`, `show ip route`, CDP), capturas de nslookup, ping, tracert y la página, y el informe PDF.

**74. ¿Qué pasa con la página si apagan el servidor DNS?**
Por nombre ya no carga, pero por IP (`http://172.16.3.66`) sí. Así se demuestra que el DNS solo traduce nombres.

**75. ¿Cómo aislarían Farmacia de las demás áreas?**
Con una ACL en Router1 (por ejemplo `access-list` + `ip access-group` en la subinterfaz .240). La guía lo menciona como objetivo adicional si el profesor lo pide.
