# 04 · Switches: comando por comando

Hay 4 switches de **acceso** (Switch0 a Switch3), donde se conectan los PCs, y 1 switch **central** (Switch4), que une los routers.

| Switch | VLAN A (Fa0/1) | VLAN B (Fa0/2) | Fa0/3 | Trunk Gi0/1 va a |
|---|---|---|---|---|
| Switch0 | 210 R1_Urgencias | 220 R2_Hospitalizacion | — | Router0 |
| Switch1 | 230 R3_Laboratorio | 240 R4_Farmacia | Servidor DNS (240) | Router1 |
| Switch2 | 250 R6_Consulta | 260 R7_Imagenes | — | Router2 |
| Switch3 | 270 R8_Administracion | 280 R9_Ing_Biomedica | Servidor HTTP (270) | Router3 |

Hay **dos formas** de configurar: **a mano** (lo que sigue, para entender) o **con el script** (al final, para ir rápido).

---

## Paso 0 · Borrar lo que dejaron otros grupos

Los switches del laboratorio suelen traer configuraciones viejas (nombres raros como `SW-LAB` o `S1`, VLAN de otros grupos). Mira el prompt: si no dice el nombre que esperas, bórralo.

```
enable
write erase
delete flash:vlan.dat
reload
```

| Comando | Qué hace | Qué responder |
|---|---|---|
| `enable` | Pasa al modo privilegiado (`#`) | Si pide contraseña, prueba `cisco` o `class` |
| `write erase` | Borra la configuración **guardada** (startup-config) | `[confirm]` → **Enter** |
| `delete flash:vlan.dat` | Borra el archivo donde el switch guarda las VLAN (las VLAN **no** se borran con write erase) | `Delete filename [vlan.dat]?` → **Enter**; `[confirm]` → **Enter** |
| `reload` | Reinicia el switch | `Save?` → **no**; `[confirm]` → **Enter** |

Al prender (2–3 min) pregunta: `Would you like to enter the initial configuration dialog? [yes/no]:` → escribe **`no`** y Enter.

> ⚠️ **Antes de borrar, mira el prompt.** Nosotros borramos Switch0 por error porque el cable seguía ahí. Si te pasa, escribe `copy running-config startup-config` **antes de reiniciar**: la configuración sigue en la RAM.

---

## Paso 1 · Entrar a configurar y ponerle nombre

```
enable
configure terminal
hostname Switch1
no ip domain-lookup
```

| Comando | Qué hace |
|---|---|
| `enable` | Modo privilegiado: el prompt pasa de `>` a `#` |
| `configure terminal` | Modo de configuración: el prompt pasa a `(config)#` |
| `hostname Switch1` | Le pone nombre al equipo; aparece en el prompt |
| `no ip domain-lookup` | Si escribes mal un comando, el switch cree que es un nombre y se queda "Translating…" un rato. Esto lo evita |

## Paso 2 · Crear las VLAN

```
vlan 230
 name R3_Laboratorio
exit
vlan 240
 name R4_Farmacia
exit
```

| Comando | Qué hace |
|---|---|
| `vlan 230` | Crea la VLAN número 230 y entra a configurarla (`(config-vlan)#`) |
| `name R3_Laboratorio` | Le pone un nombre. Es solo una etiqueta: lo que importa es el **número** |
| `exit` | Vuelve a `(config)#` |

## Paso 3 · El puerto trunk hacia el router

```
interface GigabitEthernet0/1
 description TRUNK_A_ROUTER1
 switchport mode trunk
 switchport trunk allowed vlan 230,240
 no shutdown
exit
```

| Comando | Qué hace |
|---|---|
| `interface GigabitEthernet0/1` | Entra al puerto Gigabit 1 (el de la **derecha**) |
| `description TRUNK_A_ROUTER1` | Una nota para humanos; no cambia nada |
| `switchport mode trunk` | El puerto pasa a ser **trunk**: lleva varias VLAN con etiqueta 802.1Q |
| `switchport trunk allowed vlan 230,240` | Solo deja pasar estas 2 VLAN (más ordenado y seguro) |
| `no shutdown` | Enciende el puerto (por si estaba apagado) |

> En el 2960 **no** hace falta `switchport trunk encapsulation dot1q`: solo sabe hacer 802.1Q. En switches más grandes (3560) sí hace falta.

## Paso 4 · Los puertos de los PCs (access)

```
interface FastEthernet0/1
 description PC_R3_Laboratorio
 switchport mode access
 switchport access vlan 230
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/2
 switchport mode access
 switchport access vlan 240
 spanning-tree portfast
 no shutdown
exit
interface FastEthernet0/3
 description SERVIDOR_DNS
 switchport mode access
 switchport access vlan 240
 spanning-tree portfast
 no shutdown
exit
```

| Comando | Qué hace |
|---|---|
| `switchport mode access` | El puerto lleva **una sola** VLAN, sin etiquetas. El PC no sabe de VLAN |
| `switchport access vlan 230` | En **cuál** VLAN queda el puerto. **Esto decide a qué red pertenece el PC**, no la IP |
| `spanning-tree portfast` | El puerto funciona al instante (sin esperar 30 s de STP). **Solo** en puertos de PCs, nunca hacia otro switch |

> Fa0/3 solo existe en **Switch1** (DNS, VLAN 240) y **Switch3** (HTTP, VLAN 270).

## Paso 5 · Guardar

```
end
copy running-config startup-config
```

| Comando | Qué hace | Qué responder |
|---|---|---|
| `end` | Vuelve a `#` | — |
| `copy running-config startup-config` | Copia la configuración de la RAM (se borra al apagar) a la NVRAM (permanente) | `Destination filename [startup-config]?` → **solo Enter** |

Debe decir `[OK]`. En el 2960 es normal que diga "0 bytes copied" si solo cambiaste VLAN: esas se guardan aparte, en `vlan.dat`.

> ⚠️ En la pregunta `Destination filename` presiona **solo Enter**. Si escribes otra cosa (nos pasó: pegamos `terminal length 0`), sale `%Error` y **no se guarda**.

## Paso 6 · Verificar

```
show vlan brief
show interfaces trunk
show interfaces status
show running-config
```

| Comando | Qué debe mostrar |
|---|---|
| `show vlan brief` | Cada VLAN con su nombre y sus puertos. Ej.: `230 R3_Laboratorio active Fa0/1` |
| `show interfaces trunk` | `Gi0/1 on 802.1q trunking 1` y las VLAN permitidas `230,240` |
| `show interfaces status` | Cada puerto `connected` o `notconnect`, y su VLAN (`trunk` en Gi0/1) |
| `show running-config` | Toda la configuración (antes escribe `terminal length 0` para que no se pause) |

> El puerto **trunk no aparece** en `show vlan brief`. Es normal: está en todas sus VLAN a la vez.

---

## Switch4 (central): mucho más simple

Solo une los 4 routers en una misma red (R5). **No necesita VLAN nuevas ni trunks.**

```
enable
configure terminal
hostname Switch4
no ip domain-lookup
interface range FastEthernet0/1 - 4
 description R5_TRANSITO
 switchport mode access
 switchport access vlan 1
 spanning-tree portfast
 no shutdown
exit
end
copy running-config startup-config
```

| Comando | Qué hace |
|---|---|
| `interface range FastEthernet0/1 - 4` | Configura los puertos 1, 2, 3 y 4 **a la vez** |
| `switchport access vlan 1` | La VLAN 1 es la que viene de fábrica. Aquí solo es "el cable compartido" entre routers, **no** es una VLAN de usuarios |

¿Por qué no lleva VLAN? Porque los paquetes que llegan a Switch4 ya salieron del router **sin etiqueta**: el router ya los enrutó.

---

## Con el script (forma rápida)

Con el cable de consola conectado al switch:

```bash
sudo python3 scripts/linux/cisco_auto.py Switch1 --borrar     # borra, reinicia y configura
sudo python3 scripts/linux/cisco_auto.py Switch1              # solo configura (sin borrar)
sudo python3 scripts/linux/cisco_auto.py Switch1 --evidencia  # solo guarda los "show" en Switch1_evidencia.txt
```

El script:
1. Abre el cable de consola a 9600.
2. Escribe **letra por letra** (despacio), para que el switch no pierda caracteres.
3. Espera el prompt correcto antes del siguiente comando.
4. Responde solo a las preguntas (`[confirm]`, `initial configuration dialog`, contraseñas `cisco`/`class`).
5. Te muestra el nombre del equipo conectado y **pregunta antes de seguir** (para no configurar el equipo equivocado).
6. Guarda y muestra la verificación. Todo queda en `log_Switch1.txt`.

El archivo `configs/SwitchN.ios` tiene la misma configuración, con comentarios, para copiar a mano **una línea a la vez**.
