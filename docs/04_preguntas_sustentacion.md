# 04 · Preguntas de sustentación (con respuesta)

> Tapa la respuesta y responde en voz alta. Cada integrante debe poder contestar **todas**.

## Direccionamiento
**1. ¿Por qué 172.16.0.0/22?**
Es privado (RFC 1918). Las 9 redes suman 968 direcciones; /23 da 512 (no alcanza), /22 da 1024.

**2. ¿Por qué R5 es /29 y no /30?**
Hay 4 routers → 4 IP útiles. /30 da 2; /29 da 6.

**3. ¿Por qué Farmacia es /27 si pide 30?**
/27 da exactamente 30 útiles. El enunciado dice que gateway y DNS cuentan dentro de esos 30.

**4. ¿Qué es VLSM?**
Usar máscaras distintas según el tamaño de cada red, para no desperdiciar direcciones.

**5. Calcula la red, el broadcast y el rango de 172.16.3.128/27.**
Tamaño 32 → red .128, broadcast .159, hosts .129–.158.

**6. ¿Cuántas direcciones quedan libres?**
56 (172.16.3.200–.255).

## VLAN y 802.1Q
**7. ¿Qué hace una VLAN?**
Separa dominios de broadcast en capa 2. Para comunicarse entre VLAN hace falta un router.

**8. Diferencia entre access y trunk.**
Access: una VLAN, sin etiqueta, para PCs. Trunk: varias VLAN etiquetadas 802.1Q, entre switch y router.

**9. ¿Qué es la VLAN nativa y cuál es?**
La que viaja sin etiqueta en el trunk; aquí la VLAN 1 (por defecto). No transporta usuarios.

**10. ¿Por qué Switch4 no tiene trunks ni VLAN 210–280?**
Solo une las interfaces de tránsito de los routers en un dominio L2 (VLAN 1). Por él no pasan tramas de usuarios etiquetadas; los routers ya desencapsularon.

**11. ¿Para qué `spanning-tree portfast`?**
Para que el puerto del PC reenvíe de inmediato sin esperar ~30 s de STP. Solo en puertos de equipos finales.

## Router‑on‑a‑Stick
**12. ¿Por qué subinterfaces?**
Un solo puerto físico atiende 2 VLAN, cada una con su gateway y su etiqueta.

**13. ¿Qué hace `encapsulation dot1Q 210`?**
Asocia la subinterfaz a las tramas con etiqueta VLAN 210. El número tras el punto es solo convención.

**14. ¿Dónde está el gateway de los PCs?**
En la subinterfaz del router (ej. Gi0/0.210 = 172.16.2.1), no en una SVI del switch.

**15. ¿Por qué Gi0/0 no tiene IP?**
Solo es el transporte físico del trunk; las IP están en las subinterfaces.

## Rutas estáticas
**16. ¿Cuántas rutas estáticas hay y por qué?**
6 por router (8 LAN − 2 propias), 24 en total. Las propias y R5 son conectadas.

**17. ¿Qué es el siguiente salto?**
La IP del router vecino que sabe llegar a esa red. Debe estar en una red conectada (aquí R5).

**18. ¿Puede fallar un ping si la ruta de ida está bien?**
Sí: si falta la ruta de retorno, la respuesta no vuelve.

**19. ¿Qué significan C, L y S en `show ip route`?**
C = conectada, L = IP local /32 del router, S = estática.

**20. ¿Por qué no RIP, OSPF ni EIGRP?**
Lo prohíbe el examen; además, con 4 routers y redes fijas las estáticas son simples y predecibles.

## DNS y HTTP
**21. ¿Qué prueba `nslookup`?**
Que el DNS resuelve el nombre. No prueba que HTTP funcione.

**22. ¿Qué es un registro A?**
Asocia un nombre con una dirección IPv4 (`www.hospital.local → 172.16.3.66`).

**23. ¿Qué puertos usan DNS y HTTP?**
DNS: UDP 53 (TCP 53 en respuestas grandes). HTTP: TCP 80.

**24. Si funciona por IP pero no por nombre, ¿qué revisas?**
DNS configurado en el cliente, ping al DNS, servicio activo y registro A correcto. En Ubuntu, el `nsswitch.conf` por el `.local`.

## Operación de IOS
**25. ¿Qué hace `copy running-config startup-config`?**
Copia la configuración activa (RAM) a NVRAM para que sobreviva un reinicio.

**26. ¿Qué es el config‑register 0x2102 vs 0x2142?**
0x2102: arranque normal. 0x2142: ignora la startup‑config (recuperación de contraseña).

**27. ¿Qué hace `no ip domain-lookup`?**
Evita que un comando mal escrito se intente resolver como nombre de host ("Translating…").

**28. ¿Para qué sirve `show cdp neighbors`?**
Muestra qué equipo y qué puerto hay al otro lado de cada cable. Lo usamos para encontrar cables mal conectados.

## Cambios en vivo (ensayar)
**A. Cambiar Fa0/1 de Switch0 a VLAN 220 y restaurar.**
```
configure terminal
interface fa0/1
switchport access vlan 220
end
show vlan brief        ← PC1 ya no llega a 172.16.2.1 (está en la VLAN equivocada)
configure terminal
interface fa0/1
switchport access vlan 210
end
copy running-config startup-config
```
*Explicación:* la IP del PC no define su VLAN; la define el puerto del switch.

**B. Quitar y restaurar una ruta en Router0.**
```
configure terminal
no ip route 172.16.3.64 255.255.255.192 172.16.3.196
end
show ip route          ← desaparece la S hacia R8; PC1 ya no llega al HTTP
configure terminal
ip route 172.16.3.64 255.255.255.192 172.16.3.196
end
copy running-config startup-config
```

**C. Apagar el trunk y diagnosticar.**
`interface gi0/1` → `shutdown` en Switch0 → PCs de R1/R2 pierden el gateway → `no shutdown`.
