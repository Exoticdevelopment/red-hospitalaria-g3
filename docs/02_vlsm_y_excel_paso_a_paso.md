# 02 · VLSM y Excel paso a paso

**VLSM** (Variable Length Subnet Mask, máscara de longitud variable) quiere decir: **a cada red le damos el tamaño que necesita**, no a todas el mismo. Así no se desperdician direcciones.

---

## Paso 1 · Los datos del examen

| Red | Área | Hosts mínimos | VLAN |
|---|---|---|---|
| R1 | Urgencias | 120 | 210 |
| R2 | Hospitalización | 200 | 220 |
| R3 | Laboratorio clínico | 55 | 230 |
| R4 | Farmacia (aquí va el DNS) | 30 | 240 |
| R5 | Tránsito entre routers | 4 | sin VLAN de usuarios |
| R6 | Consulta externa | 160 | 250 |
| R7 | Imágenes diagnósticas | 70 | 260 |
| R8 | Administración (aquí va el HTTP) | 40 | 270 |
| R9 | Ingeniería biomédica | 25 | 280 |

> Los gateways y los servidores **cuentan** dentro de los hosts. Farmacia pide 30: el gateway, el DNS y 28 PCs.

## Paso 2 · Ordenar de MAYOR a MENOR

**Regla de oro del VLSM:** siempre se empieza por la red más grande. Si empiezas por las pequeñas, las grandes quedan "desalineadas" y no caben.

R2 (200) → R6 (160) → R1 (120) → R7 (70) → R3 (55) → R8 (40) → R4 (30) → R9 (25) → R5 (4)

## Paso 3 · Calcular el tamaño de cada red

Se busca la potencia de 2 más pequeña que alcance para **hosts + 2** (la red y el broadcast).

**Ejemplo con R2 (200 hosts):**
1. Se necesitan 200 + 2 = **202** direcciones.
2. Potencias de 2: 2⁷ = 128 (no alcanza), 2⁸ = **256** (sí alcanza).
3. Bits de host **n = 8**.
4. Prefijo = 32 − 8 = **/24**.
5. Útiles = 256 − 2 = **254** ≥ 200 ✔.

| Red | Hosts | Hosts+2 | n (bits host) | 2ⁿ | 2ⁿ−2 | Prefijo | Máscara |
|---|---|---|---|---|---|---|---|
| R2 | 200 | 202 | 8 | 256 | 254 | /24 | 255.255.255.0 |
| R6 | 160 | 162 | 8 | 256 | 254 | /24 | 255.255.255.0 |
| R1 | 120 | 122 | 7 | 128 | 126 | /25 | 255.255.255.128 |
| R7 | 70 | 72 | 7 | 128 | 126 | /25 | 255.255.255.128 |
| R3 | 55 | 57 | 6 | 64 | 62 | /26 | 255.255.255.192 |
| R8 | 40 | 42 | 6 | 64 | 62 | /26 | 255.255.255.192 |
| R4 | 30 | 32 | 5 | 32 | 30 | /27 | 255.255.255.224 |
| R9 | 25 | 27 | 5 | 32 | 30 | /27 | 255.255.255.224 |
| R5 | 4 | 6 | 3 | 8 | 6 | /29 | 255.255.255.248 |

**¿Cómo sale la máscara del último octeto?** Se ponen en 1 los bits de red del último octeto:

```
/25 → 1000 0000 = 128   → 255.255.255.128
/26 → 1100 0000 = 192   → 255.255.255.192
/27 → 1110 0000 = 224   → 255.255.255.224
/29 → 1111 1000 = 248   → 255.255.255.248
```

Truco: 256 − tamaño de la red = último octeto. Para /27: 256 − 32 = **224**.

## Paso 4 · Elegir el bloque y justificarlo (actividad 1 del examen)

Se suman los tamaños: 256 + 256 + 128 + 128 + 64 + 64 + 32 + 32 + 8 = **968 direcciones**.

| Bloque | Direcciones | ¿Alcanza para 968? |
|---|---|---|
| /23 | 512 | ❌ No |
| **/22** | **1024** | ✔ Sí, y es el **más pequeño** que alcanza |
| /21 | 2048 | Sí, pero desperdicia más de la mitad |

**Bloque elegido: 172.16.0.0/22** (va de 172.16.0.0 a 172.16.3.255).
- Es privado (está dentro de 172.16.0.0/12).
- No es la IP que traen los equipos por defecto (el examen lo prohíbe).
- Sobran 1024 − 968 = **56 direcciones** libres: de 172.16.3.200 a 172.16.3.255.

## Paso 5 · Asignar las direcciones una tras otra

Cada red empieza donde terminó la anterior.

| Red | Dirección de red | Primer host = gateway | Último host | Broadcast | Siguiente red empieza en |
|---|---|---|---|---|---|
| R2 /24 | 172.16.0.0 | 172.16.0.1 | 172.16.0.254 | 172.16.0.255 | 172.16.1.0 |
| R6 /24 | 172.16.1.0 | 172.16.1.1 | 172.16.1.254 | 172.16.1.255 | 172.16.2.0 |
| R1 /25 | 172.16.2.0 | 172.16.2.1 | 172.16.2.126 | 172.16.2.127 | 172.16.2.128 |
| R7 /25 | 172.16.2.128 | 172.16.2.129 | 172.16.2.254 | 172.16.2.255 | 172.16.3.0 |
| R3 /26 | 172.16.3.0 | 172.16.3.1 | 172.16.3.62 | 172.16.3.63 | 172.16.3.64 |
| R8 /26 | 172.16.3.64 | 172.16.3.65 | 172.16.3.126 | 172.16.3.127 | 172.16.3.128 |
| R4 /27 | 172.16.3.128 | 172.16.3.129 | 172.16.3.158 | 172.16.3.159 | 172.16.3.160 |
| R9 /27 | 172.16.3.160 | 172.16.3.161 | 172.16.3.190 | 172.16.3.191 | 172.16.3.192 |
| R5 /29 | 172.16.3.192 | 172.16.3.193 | 172.16.3.198 | 172.16.3.199 | 172.16.3.200 (libre) |

**Cómo calcular a mano (ejemplo R4):**
- Empieza en 172.16.3.128. Tamaño 32.
- Broadcast = 128 + 32 − 1 = **159** → 172.16.3.159.
- Primer host = 128 + 1 = **129**. Último host = 159 − 1 = **158**.

**Comprobar la alineación:** la dirección de red debe ser **múltiplo** del tamaño. 128 ÷ 32 = 4 exacto ✔. Si da decimales, la red está mal puesta.

## Paso 6 · IPs fijas de los equipos

| Equipo | IP | Por qué esa |
|---|---|---|
| Gateways | primera IP de cada red | Convención del examen |
| Routers en R5 | .193 Router0, .194 Router1, .195 Router2, .196 Router3 | En orden |
| Servidor DNS | 172.16.3.130 | Segunda IP de R4 (la primera es el gateway) |
| Servidor HTTP | 172.16.3.66 | Segunda IP de R8 |
| PC1 Urgencias | 172.16.2.10 | Una IP cualquiera dentro de R1 |
| PC2 Consulta | 172.16.1.10 | Una IP cualquiera dentro de R6 |

---

## El Excel (`excel/VLSM_Hospital_G3.xlsx`), columna por columna

El examen exige un Excel **con fórmulas** (no una tabla pegada). Si cambias los hosts de una red, todo se recalcula.

### Hoja "VLSM"

| Col | Nombre | Fórmula (fila 2) | Qué hace, en palabras |
|---|---|---|---|
| A | Red | (escrito) | R1…R9 |
| B | Área | (escrito) | Nombre del área |
| C | Hosts mínimos | (escrito, en azul) | Lo que pide el examen |
| D | Bits host | `=ROUNDUP(LOG(C2+2,2),0)` | ¿Cuántos bits necesito para hosts+2? LOG en base 2 y redondeo hacia arriba |
| E | Prefijo | `=32-D2` | Bits de red = 32 − bits de host |
| F | 2^n | `=2^D2` | Tamaño total de la red |
| G | 2^n − 2 | `=F2-2` | Direcciones útiles |
| H | Máscara binaria (4.º octeto) | `=DEC2BIN(256-2^(32-E2),8)` | El último octeto en 0 y 1. Para /24 o menos dice "No aplica" |
| I | Máscara decimal | (fórmula larga) | Arma la máscara completa octeto por octeto |
| J | Red entera | `=Parametros!B4` y luego `=J2+F2` | La dirección como **un solo número**. Cada red empieza donde acabó la anterior |
| K | Dirección red | `=INT(J2/16777216)&"."&MOD(INT(J2/65536),256)&…` | Convierte el número entero en formato a.b.c.d |
| L | Primer host | igual que K pero con `J2+1` | Red + 1 |
| M | Último host | con `J2+F2-2` | Broadcast − 1 |
| N | Broadcast | con `J2+F2-1` | Red + tamaño − 1 |
| O | Gateway | `=L2` | El gateway es el primer host |
| P | VLAN | (escrito) | 210…280 |
| Q | Asignación física | (escrito) | En qué router y switch está |
| R | Reservas | (escrito) | Cuántas IP fijas hay (gateway, servidor) |
| S | Libres para terminales | `=G2-R2` | Útiles − reservas |
| T | Alineación | `=IF(MOD(J2,F2)=0,"OK","REVISAR")` | ¿La red empieza en un múltiplo de su tamaño? |
| U | Capacidad | `=IF(G2>=C2,"OK","INSUFICIENTE")` | ¿Caben los hosts pedidos? |

**¿Por qué "Red entera"?** Excel no sabe sumar IPs, pero sí números. 172.16.0.0 es el número 2 886 729 728 (172×16 777 216 + 16×65 536). Se suma el tamaño y luego se convierte de vuelta a a.b.c.d:
- 16 777 216 = 256³ → primer octeto
- 65 536 = 256² → segundo octeto
- 256 → tercer octeto
- el resto → cuarto octeto

### Hoja "Parametros"
El bloque elegido (172.16.0.0/22), su número entero y el total de direcciones (`=2^(32-22)` = 1024).

### Hoja "Reservas"
La tabla de direccionamiento final: cada equipo con IP, máscara, gateway, DNS y puerto del switch. Los marcados **"usado en el lab"** son los 4 que se conectaron. Los demás son IPs reservadas por si el profesor pide un PC en otra VLAN.

### Hoja "Como estudiar"
Notas para practicar.

> **Excel en español:** las fórmulas están en inglés por dentro, y Excel las traduce solo al abrir (ROUNDUP → REDONDEAR.MAS, IF → SI, MOD → RESIDUO, LOG → LOG, DEC2BIN → DEC.A.BIN). En Excel en español el separador es `;` en vez de `,`.

## Para practicar
1. Cambia los hosts de R9 de 25 a 40 en el Excel. ¿Qué pasa con la columna "Alineación"? (Spoiler: R9 pasa a /26 y queda mal ordenada. Hay que reordenar de mayor a menor.)
2. Calcula a mano red, broadcast y rango de 172.16.3.64/26. Respuesta: red .64, broadcast .127, hosts .65 a .126.
