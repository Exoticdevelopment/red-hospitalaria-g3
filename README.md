# 🏥 Red Hospitalaria G3 — Laboratorio físico Cisco

**Universidad Libre · Seccional Cali** · Redes de Computadores · Examen práctico G3 · 2026-2

Implementación real (equipos Cisco físicos) de una red hospitalaria con **VLSM, 8 VLAN, IEEE 802.1Q, Router‑on‑a‑Stick, rutas estáticas, DNS y HTTP**.

> ✍️ Completar: **Grupo** `__` · **Integrantes** `______________________`

---

## 📂 Contenido del repositorio

```
.
├── README.md                     ← este archivo (visión general)
├── configs/                      ← configuración IOS COMENTADA de los 9 equipos
│   ├── Switch0.ios … Switch3.ios     switches de acceso
│   ├── Switch4_Central.ios           switch de tránsito (R5)
│   └── Router0.ios … Router3.ios     routers 2901
├── scripts/
│   ├── linux/
│   │   ├── cisco_auto.py             configura un equipo Cisco solo por consola
│   │   ├── configurar_pc_linux.sh    IP estática en un PC Ubuntu
│   │   ├── servidor_dns.sh           servidor DNS (dnsmasq)
│   │   ├── servidor_http.sh          servidor HTTP (apache2 / python)
│   │   └── pruebas.sh                pruebas finales + evidencia
│   └── windows/
│       ├── configurar_pc_windows.bat IP estática en un PC Windows (menú)
│       └── pruebas_windows.bat       pruebas finales + evidencia
├── docs/
│   ├── 01_teoria_vlsm_y_conceptos.md
│   ├── 02_guia_laboratorio_fisico.md   paso a paso en equipos reales
│   ├── 03_problemas_reales_y_soluciones.md
│   ├── 04_preguntas_sustentacion.md
│   └── 05_pruebas_y_evidencias.md
└── excel/VLSM_Hospital_G3.xlsx   cálculo VLSM con fórmulas
```

---

## 🗺️ Topología

```
 PC1 ─Fa0/1┐                                              ┌Fa0/1─ PC2
 PC  ─Fa0/2┤ Switch0 ═Gi0/1══Gi0/0═ Router0   Router2 ═Gi0/0══Gi0/1═ Switch2 ├Fa0/2─ PC
           ┘                         │Gi0/1   Gi0/1│                       ┘
                                     │              │
                               Fa0/1 │   SWITCH4    │ Fa0/3
                                     ├── (R5 /29) ──┤
                               Fa0/2 │              │ Fa0/4
                                     │Gi0/1   Gi0/1│
 PC  ─Fa0/1┐                         │              │                      ┌Fa0/1─ PC
 PC  ─Fa0/2┤ Switch1 ═Gi0/1══Gi0/0═ Router1   Router3 ═Gi0/0══Gi0/1═ Switch3 ├Fa0/2─ PC
 DNS ─Fa0/3┘                                                               └Fa0/3─ HTTP
   ═══ trunk 802.1Q (2 VLAN)      ─── access / tránsito
```

---

## 🧮 Direccionamiento (172.16.0.0/22, VLSM de mayor a menor)

| Red | Área | Hosts req. | Prefijo | Subred | Gateway | Broadcast | VLAN | Router |
|---|---|---|---|---|---|---|---|---|
| R2 | Hospitalización | 200 | /24 | 172.16.0.0 | 172.16.0.1 | 172.16.0.255 | 220 | Router0 |
| R6 | Consulta externa | 160 | /24 | 172.16.1.0 | 172.16.1.1 | 172.16.1.255 | 250 | Router2 |
| R1 | Urgencias | 120 | /25 | 172.16.2.0 | 172.16.2.1 | 172.16.2.127 | 210 | Router0 |
| R7 | Imágenes diagnósticas | 70 | /25 | 172.16.2.128 | 172.16.2.129 | 172.16.2.255 | 260 | Router2 |
| R3 | Laboratorio clínico | 55 | /26 | 172.16.3.0 | 172.16.3.1 | 172.16.3.63 | 230 | Router1 |
| R8 | Administración | 40 | /26 | 172.16.3.64 | 172.16.3.65 | 172.16.3.127 | 270 | Router3 |
| R4 | Farmacia | 30 | /27 | 172.16.3.128 | 172.16.3.129 | 172.16.3.159 | 240 | Router1 |
| R9 | Ingeniería biomédica | 25 | /27 | 172.16.3.160 | 172.16.3.161 | 172.16.3.191 | 280 | Router3 |
| R5 | Tránsito | 4 | /29 | 172.16.3.192 | — | 172.16.3.199 | (VLAN 1 L2) | todos |

**Tránsito R5:** Router0 `.193` · Router1 `.194` · Router2 `.195` · Router3 `.196`

### Equipos finales
| Equipo | Conectado en | IP | Gateway | DNS |
|---|---|---|---|---|
| Servidor DNS | Switch1 Fa0/3 | 172.16.3.130/27 | 172.16.3.129 | 172.16.3.130 |
| Servidor HTTP | Switch3 Fa0/3 | 172.16.3.66/26 | 172.16.3.65 | 172.16.3.130 |
| PC1 Urgencias | Switch0 Fa0/1 | 172.16.2.10/25 | 172.16.2.1 | 172.16.3.130 |
| PC2 Consulta | Switch2 Fa0/1 | 172.16.1.10/24 | 172.16.1.1 | 172.16.3.130 |

Registro DNS: **`www.hospital.local` → A → `172.16.3.66`**

---

## 🚀 Uso rápido

### 1. Equipos Cisco (desde Ubuntu con cable de consola USB)
```bash
sudo apt install -y python3-serial picocom
sudo python3 scripts/linux/cisco_auto.py Switch0          # switches: se puede agregar --borrar
sudo python3 scripts/linux/cisco_auto.py Router0          # routers: SIN --borrar (ver docs/03)
```
O pegar a mano, **una línea a la vez**, los archivos de `configs/`.

### 2. Servidores (Ubuntu)
```bash
sudo apt install -y dnsmasq dnsutils apache2   # ANTES, con internet
sudo bash scripts/linux/servidor_dns.sh
sudo bash scripts/linux/servidor_http.sh "Grupo 3" "Nombre1, Nombre2"
```

### 3. PCs cliente
- Ubuntu: `sudo bash scripts/linux/configurar_pc_linux.sh 1`
- Windows: clic derecho en `configurar_pc_windows.bat` → *Ejecutar como administrador* → opción `1`

### 4. Pruebas
- Ubuntu: `bash scripts/linux/pruebas.sh | tee evidencia.txt`
- Windows: doble clic en `pruebas_windows.bat`

---

## ✅ Estado del laboratorio (26-oct-2026)
- [x] 5 switches: VLAN, access, trunk 802.1Q — verificado con `show interfaces trunk`
- [x] 4 routers: subinterfaces, tránsito /29, 24 rutas estáticas — verificado con `show ip route`
- [x] Cableado verificado con `show cdp neighbors`
- [x] Ping entre los 4 routers y hacia gateways remotos
- [x] `config-register 0x2102` en los 4 routers
- [ ] Servidores DNS y HTTP
- [ ] PCs cliente y pruebas finales (ping, nslookup, navegador)
- [ ] Capturas de evidencia

## 📚 Para estudiar
Empezar por **`docs/01`** (teoría) → **`docs/04`** (preguntas) → **`docs/03`** (lo que salió mal en el lab real y cómo se arregló: el docente suele preguntar por fallas).
