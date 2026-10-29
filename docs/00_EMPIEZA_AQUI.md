# 00 · Empieza aquí

Esta carpeta explica **todo** el examen G3, desde cero. No necesitas saber nada de redes para empezar.

## ¿Qué construimos? (en una frase)

Una red de hospital con **9 áreas** (Urgencias, Farmacia, etc.). Cada área tiene su propia red y su propia VLAN. **4 routers** las unen, y hay un **servidor DNS** y un **servidor web**: desde cualquier PC se abre `http://www.hospital.local`.

## Orden de lectura recomendado

| # | Archivo | Qué aprendes | Tiempo |
|---|---|---|---|
| 1 | [01_conceptos_para_dummies.md](01_conceptos_para_dummies.md) | Qué es una IP, una máscara, una VLAN, un router, un DNS… con ejemplos de la vida real | 30 min |
| 2 | [02_vlsm_y_excel_paso_a_paso.md](02_vlsm_y_excel_paso_a_paso.md) | Cómo se calcularon las 9 redes y qué hace cada columna del Excel | 30 min |
| 3 | [03_cableado_y_consola.md](03_cableado_y_consola.md) | Qué cable va en qué puerto y cómo "hablar" con un equipo Cisco | 15 min |
| 4 | [04_switches_comando_por_comando.md](04_switches_comando_por_comando.md) | Configurar los 5 switches, explicando cada comando | 30 min |
| 5 | [05_routers_comando_por_comando.md](05_routers_comando_por_comando.md) | Configurar los 4 routers, explicando cada comando | 30 min |
| 6 | [06_pcs_windows_y_linux.md](06_pcs_windows_y_linux.md) | Poner la IP en los PCs (a mano y con script) | 20 min |
| 7 | [07_servidores_dns_y_http.md](07_servidores_dns_y_http.md) | Montar el DNS y el servidor web | 20 min |
| 8 | [08_pruebas_y_evidencias.md](08_pruebas_y_evidencias.md) | Cómo comprobar que todo funciona y qué capturas tomar | 15 min |
| 9 | [09_problemas_y_soluciones.md](09_problemas_y_soluciones.md) | Lo que salió mal en el lab real y cómo se arregló | 15 min |
| 10 | [10_preguntas_del_profesor.md](10_preguntas_del_profesor.md) | Más de 70 preguntas con respuesta para la sustentación | 1 h |
| 11 | [11_sustentacion_cambios_en_vivo.md](11_sustentacion_cambios_en_vivo.md) | Los cambios que el profe puede pedir en vivo, paso a paso | 30 min |
| 12 | [12_checklist_dia_del_examen.md](12_checklist_dia_del_examen.md) | Lista de lo que hay que hacer el día del examen, en orden | 5 min |
| 13 | [13_chuleta_de_comandos.md](13_chuleta_de_comandos.md) | Todos los comandos en una sola página | — |

## Montaje completo paso a paso
Todo en un solo archivo, a mano o con scripts: [../GUIA_MONTAJE_COMPLETO.md](../GUIA_MONTAJE_COMPLETO.md)

## Prueba de las 8 LAN cambiando IPs
Paso a paso, a mano o con scripts: [../GUIA_PRUEBA_CAMBIANDO_IPS.md](../GUIA_PRUEBA_CAMBIANDO_IPS.md)

## Si solo tienes 1 hora antes del examen

1. Lee el **resumen** de [01](01_conceptos_para_dummies.md) (la tabla del final).
2. Lee [12 · checklist](12_checklist_dia_del_examen.md).
3. Practica en voz alta las preguntas marcadas con ⭐ en [10](10_preguntas_del_profesor.md).
4. Ensaya **un** cambio en vivo de [11](11_sustentacion_cambios_en_vivo.md).

## Los datos que TODOS deben saberse de memoria

| Dato | Valor |
|---|---|
| Bloque usado | 172.16.0.0/22 (1024 direcciones) |
| Red de tránsito (R5) | 172.16.3.192/29 → routers .193 .194 .195 .196 |
| Servidor DNS | 172.16.3.130 (Farmacia, VLAN 240, Switch1 Fa0/3) |
| Servidor HTTP | 172.16.3.66 (Administración, VLAN 270, Switch3 Fa0/3) |
| Nombre de la página | www.hospital.local |
| Rutas estáticas | 6 por router, 24 en total |
| VLAN | 210, 220, 230, 240, 250, 260, 270, 280 |

## Cómo está organizado el repositorio

```
red-hospitalaria-g3/
├── README.md          ← portada
├── docs/              ← ESTA documentación (lee en orden 00 → 13)
├── excel/             ← Excel VLSM con fórmulas (entregable A)
├── configs/           ← configuración de los 9 equipos Cisco, comentada (entregable B)
├── scripts/
│   ├── linux/         ← scripts para Ubuntu (PCs, servidores, equipos Cisco)
│   └── windows/       ← scripts para Windows (PCs)
├── evidencias/        ← lo que mostraron los equipos reales (entregable D)
└── informe/           ← informe PDF con capturas (entregables C y D)
```
