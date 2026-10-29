# 🏥 Red Hospitalaria G3 · Laboratorio físico Cisco

**Universidad Libre · Seccional Cali** · Redes de Computadores · Examen práctico G3 · 2026-2
**Grupo 3:** Miguel Gonzalez · Pablo Arango · Daniel Celis · Julio Guachene · Herlyn Jhoan

Red hospitalaria montada en **equipos Cisco reales** (4 routers 2901 y 5 switches 2960) con **VLSM, 8 VLAN, IEEE 802.1Q, Router-on-a-Stick, 24 rutas estáticas, DNS y HTTP**. ✅ Funcionando y verificada el 26-oct-2026.

> 🛠️ **Montar todo desde cero (cables, switches, routers, servidores, PCs):** [GUIA_MONTAJE_COMPLETO.md](GUIA_MONTAJE_COMPLETO.md)
>
> 🔁 **Prueba de las 8 LAN cambiando IPs (la que pidió el profe):** [GUIA_PRUEBA_CAMBIANDO_IPS.md](GUIA_PRUEBA_CAMBIANDO_IPS.md)
>
> 📖 **¿Primera vez aquí?** Empieza por **[docs/00_EMPIEZA_AQUI.md](docs/00_EMPIEZA_AQUI.md)**. Todo está explicado desde cero.

---

## 📂 Qué hay en cada carpeta

| Carpeta | Contenido | Entregable del examen |
|---|---|---|
| [`docs/`](docs/) | Documentación paso a paso para entender y repetir todo | — |
| [`excel/`](excel/) | `VLSM_Hospital_G3.xlsx` con fórmulas | **A** |
| [`configs/`](configs/) | Configuración comentada de los 9 equipos Cisco | **B** |
| [`informe/`](informe/) | Informe PDF: tabla de direccionamiento, diagrama y capturas | **C y D** |
| [`evidencias/`](evidencias/) | Salidas reales de `show running-config`, `show ip route`, CDP… | **B y D** |
| [`scripts/linux/`](scripts/linux/) | Scripts para Ubuntu: equipos Cisco, PCs, servidores, pruebas | — |
| [`scripts/windows/`](scripts/windows/) | Scripts para Windows: PC, diagnóstico, pruebas | — |

## 📚 Documentación (léela en orden)

| # | Tema |
|---|---|
| [00](docs/00_EMPIEZA_AQUI.md) | **Empieza aquí**: mapa y datos para memorizar |
| [01](docs/01_conceptos_para_dummies.md) | Conceptos para dummies: IP, máscara, VLAN, trunk, rutas, DNS |
| [02](docs/02_vlsm_y_excel_paso_a_paso.md) | VLSM a mano y el Excel columna por columna |
| [03](docs/03_cableado_y_consola.md) | Qué cable va dónde y cómo usar la consola |
| [04](docs/04_switches_comando_por_comando.md) | Switches: cada comando explicado |
| [05](docs/05_routers_comando_por_comando.md) | Routers: cada comando explicado |
| [06](docs/06_pcs_windows_y_linux.md) | PCs Windows y Ubuntu |
| [07](docs/07_servidores_dns_y_http.md) | Servidores DNS y HTTP |
| [08](docs/08_pruebas_y_evidencias.md) | Pruebas y evidencias |
| [09](docs/09_problemas_y_soluciones.md) | Problemas reales y guía de diagnóstico |
| [10](docs/10_preguntas_del_profesor.md) | **75 preguntas del profesor con respuesta** |
| [11](docs/11_sustentacion_cambios_en_vivo.md) | Cambios en vivo para la sustentación |
| [12](docs/12_checklist_dia_del_examen.md) | Checklist del día del examen |
| [13](docs/13_chuleta_de_comandos.md) | Chuleta de comandos |

---

## 🗺️ Topología

```
 PC1 ─Fa0/1┐                                                       ┌Fa0/1─ PC2
 PC  ─Fa0/2┤ Switch0 ═Gi0/1══Gi0/0═ Router0     Router2 ═Gi0/0══Gi0/1═ Switch2 ├Fa0/2─ PC
           ┘                         │Gi0/1       Gi0/1│                       ┘
                               Fa0/1 │                  │ Fa0/3
                                     ├──── SWITCH4 ─────┤
                               Fa0/2 │     (R5 /29)     │ Fa0/4
                                     │Gi0/1       Gi0/1│
 PC  ─Fa0/1┐                         │                  │                      ┌Fa0/1─ PC
 PC  ─Fa0/2┤ Switch1 ═Gi0/1══Gi0/0═ Router1     Router3 ═Gi0/0══Gi0/1═ Switch3 ├Fa0/2─ PC
 DNS ─Fa0/3┘                                                                   └Fa0/3─ HTTP
   ═══ trunk 802.1Q (2 VLAN)      ─── access / tránsito
```

## 🧮 Direccionamiento · 172.16.0.0/22 (VLSM de mayor a menor)

| Red | Área | Hosts | Prefijo | Red | Gateway | Broadcast | VLAN | Router |
|---|---|---|---|---|---|---|---|---|
| R2 | Hospitalización | 200 | /24 | 172.16.0.0 | 172.16.0.1 | 172.16.0.255 | 220 | Router0 |
| R6 | Consulta externa | 160 | /24 | 172.16.1.0 | 172.16.1.1 | 172.16.1.255 | 250 | Router2 |
| R1 | Urgencias | 120 | /25 | 172.16.2.0 | 172.16.2.1 | 172.16.2.127 | 210 | Router0 |
| R7 | Imágenes diagnósticas | 70 | /25 | 172.16.2.128 | 172.16.2.129 | 172.16.2.255 | 260 | Router2 |
| R3 | Laboratorio clínico | 55 | /26 | 172.16.3.0 | 172.16.3.1 | 172.16.3.63 | 230 | Router1 |
| R8 | Administración (HTTP) | 40 | /26 | 172.16.3.64 | 172.16.3.65 | 172.16.3.127 | 270 | Router3 |
| R4 | Farmacia (DNS) | 30 | /27 | 172.16.3.128 | 172.16.3.129 | 172.16.3.159 | 240 | Router1 |
| R9 | Ingeniería biomédica | 25 | /27 | 172.16.3.160 | 172.16.3.161 | 172.16.3.191 | 280 | Router3 |
| R5 | Tránsito | 4 | /29 | 172.16.3.192 | — | 172.16.3.199 | VLAN 1 (Switch4) | los 4 |

**Tránsito R5:** Router0 `.193` · Router1 `.194` · Router2 `.195` · Router3 `.196`
**Por qué /22:** las 9 redes suman 968 direcciones; un /23 (512) no alcanza y un /22 (1024) sí.

| Equipo | Puerto | IP | Gateway | DNS |
|---|---|---|---|---|
| Servidor DNS | Switch1 Fa0/3 | 172.16.3.130/27 | 172.16.3.129 | 172.16.3.130 |
| Servidor HTTP | Switch3 Fa0/3 | 172.16.3.66/26 | 172.16.3.65 | 172.16.3.130 |
| PC1 Windows (Urgencias) | Switch0 Fa0/1 | 172.16.2.10/25 | 172.16.2.1 | 172.16.3.130 |
| PC2 Ubuntu (Consulta) | Switch2 Fa0/1 | 172.16.1.10/24 | 172.16.1.1 | 172.16.3.130 |

Registro DNS: **`www.hospital.local` → A → `172.16.3.66`**

---

## 🚀 Uso rápido

```bash
# 0) Con internet, una vez (instala picocom, dnsmasq, apache2…)
git clone https://github.com/Exoticdevelopment/red-hospitalaria-g3.git && cd red-hospitalaria-g3
sudo bash scripts/linux/preparar_con_internet.sh

# 1) Equipos Cisco (cable de consola conectado)
sudo python3 scripts/linux/cisco_auto.py Switch0 --borrar
sudo python3 scripts/linux/cisco_auto.py Router0          # routers SIN --borrar

# 2) Servidores Ubuntu
sudo bash scripts/linux/servidor_dns.sh
sudo bash scripts/linux/servidor_http.sh

# 3) PCs
sudo bash scripts/linux/configurar_pc_linux.sh 2          # Ubuntu (opciones 1..8)
#    Windows: doble clic en scripts\windows\configurar_pc_windows.bat → opción 1

# 4) Pruebas y diagnóstico
bash scripts/linux/pruebas.sh | tee evidencia.txt
bash scripts/linux/diagnostico.sh                         # Windows: diagnostico_windows.bat
```

Los scripts de PC y servidor están hechos para **PCs que usaron otros grupos**: apagan el Wi-Fi, borran IPs y DNS viejos, quitan proxys, liberan los puertos 53 y 80 y abren el firewall. También guardan una copia para **restaurar** el PC al terminar.

## ✅ Estado (26-oct-2026)
- [x] 5 switches: VLAN, access, trunk 802.1Q
- [x] 4 routers: subinterfaces, tránsito /29, 24 rutas estáticas, config-register 0x2102
- [x] Cableado verificado con `show cdp neighbors`
- [x] Servidores DNS (dnsmasq) y HTTP (Apache)
- [x] PC1 ↔ PC2 (TTL=62), `nslookup` y página por nombre desde PC1, `tracert` por Router3
- [x] Evidencias de los 9 equipos e informe PDF
