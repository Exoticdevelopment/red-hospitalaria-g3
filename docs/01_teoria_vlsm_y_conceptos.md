# 01 · Teoría: VLSM y conceptos clave

## 1. Elección del bloque
- Espacio privado **RFC 1918**: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
- Elegimos **172.16.0.0/12** (históricamente clase B) y dentro reservamos **172.16.0.0/22**.

## 2. Fórmulas
Una IPv4 tiene 32 bits. Con prefijo **/p** quedan **n = 32 − p** bits de host.

| Concepto | Fórmula |
|---|---|
| Tamaño del bloque | 2ⁿ |
| Hosts utilizables | 2ⁿ − 2 (se restan red y broadcast) |
| Dirección de red | todos los bits de host en 0 |
| Broadcast | todos los bits de host en 1 = red + 2ⁿ − 1 |
| Primer host | red + 1 (lo usamos como **gateway**) |
| Último host | broadcast − 1 |

Se elige el **menor n** tal que 2ⁿ − 2 ≥ hosts requeridos.

### Ejemplos
```
200 hosts: 2^7-2 = 126 ✗   2^8-2 = 254 ✓  → n=8 → /24
 30 hosts: 2^5-2 =  30 ✓                    → n=5 → /27   (justo: incluye gateway y DNS)
  4 hosts: 2^2-2 =   2 ✗   2^3-2 =   6 ✓   → n=3 → /29   (/30 no alcanza para 4 routers)
```

## 3. ¿Por qué /22 y no /23?
Sumamos los tamaños: 256+256+128+128+64+64+32+32+8 = **968** direcciones.
- /23 = 512 → **no alcanza**
- /22 = 1024 → **alcanza** (sobran 56: 172.16.3.200 – .255)

## 4. ¿Por qué ordenar de mayor a menor?
Si asignamos primero las redes grandes desde una base alineada, cada subred empieza en un múltiplo de su tamaño → **no hay solapamiento ni huecos raros**. Prueba en el Excel: columna *Alineación* = `MOD(red, tamaño) = 0`.

## 5. Máscaras del último octeto
| Prefijo | Máscara | Binario último octeto | Útiles |
|---|---|---|---|
| /24 | 255.255.255.0 | 00000000 | 254 |
| /25 | 255.255.255.128 | 10000000 | 126 |
| /26 | 255.255.255.192 | 11000000 | 62 |
| /27 | 255.255.255.224 | 11100000 | 30 |
| /29 | 255.255.255.248 | 11111000 | 6 |

Atajo: último octeto de la máscara = 256 − tamaño del bloque.

## 6. Conceptos de capa 2
- **VLAN**: divide un switch en varios **dominios de broadcast** separados. Un PC de la VLAN 210 no ve los broadcasts (ej. ARP) de la VLAN 220.
- **Puerto access**: pertenece a una sola VLAN. El PC envía tramas normales, sin etiqueta.
- **Puerto trunk**: transporta varias VLAN por un cable. Cada trama lleva una **etiqueta 802.1Q** (4 bytes con el ID de VLAN, 12 bits → 1‑4094).
- **VLAN nativa**: la VLAN que viaja **sin etiqueta** en el trunk (por defecto 1). No la usamos para usuarios.
- **STP / PortFast**: STP evita bucles; PortFast hace que los puertos de PCs reenvíen de inmediato.

## 7. Conceptos de capa 3
- **Router‑on‑a‑Stick**: un solo puerto físico del router (Gi0/0) con **subinterfaces** (Gi0/0.210, Gi0/0.220), cada una con `encapsulation dot1Q <vlan>` y su IP = gateway de esa VLAN. El router enruta **entre VLAN**.
- **Red de tránsito R5**: los 4 routers comparten una /29 a través de Switch4 → cada uno es "vecino directo" de los otros 3.
- **Ruta estática**: `ip route <red> <máscara> <siguiente salto>`. Cada router necesita **6** (las 8 LAN menos sus 2 propias). Total **24**.
- **Tabla de rutas**: `C` = conectada, `L` = IP local /32, `S` = estática.
- **Ruta de retorno**: el ping necesita ida **y** vuelta. Si Router3 no sabe volver a R1, el ping falla aunque la ida esté bien.

## 8. Capa 7
- **DNS** (UDP/TCP 53): traduce `www.hospital.local` → `172.16.3.66` (registro **A**). No transporta la página.
- **HTTP** (TCP 80): el navegador pide la página al servidor.
- Orden real al abrir el navegador: **ARP → consulta DNS → TCP 3‑way handshake → GET HTTP**.

## 9. Recorrido completo de un paquete (PC1 → www.hospital.local)
```
PC1 (172.16.2.10, VLAN 210)
 └─ Fa0/1 Switch0 (access 210) → trunk Gi0/1 con etiqueta 210
    └─ Router0 Gi0/0.210 (gateway 172.16.2.1)
       └─ busca 172.16.3.64/26 → ruta S via 172.16.3.196
          └─ Gi0/1 → Switch4 → Router3 Gi0/1 (.196)
             └─ red conectada Gi0/0.270 → etiqueta 270 → Switch3 trunk
                └─ Fa0/3 (access 270) → Servidor HTTP 172.16.3.66
Respuesta: Router3 usa su ruta S 172.16.2.0/25 via 172.16.3.193 (retorno)
```
