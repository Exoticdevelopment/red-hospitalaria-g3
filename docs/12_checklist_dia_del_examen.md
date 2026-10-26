# 12 · Checklist del día del examen

Marquen cada casilla en orden. Tiempo total estimado: **60–90 minutos**.

## La noche anterior / antes de entrar
- [ ] Repositorio descargado en el portátil que tiene el cable de consola: `git clone https://github.com/Exoticdevelopment/red-hospitalaria-g3.git`
- [ ] `sudo bash scripts/linux/preparar_con_internet.sh` corrido **con internet** en el portátil y en los PCs Ubuntu que serán servidores
- [ ] Carpeta `scripts/windows` copiada en una USB (para el PC Windows)
- [ ] Excel abierto una vez para revisar que las fórmulas calculen bien
- [ ] Cada integrante repasó las ⭐ de [10](10_preguntas_del_profesor.md)

## 1 · Cableado (10 min)
- [ ] RouterN **Gi0/0** → SwitchN **Gi0/1** (el de la derecha) ×4
- [ ] RouterN **Gi0/1** → Switch4 **Fa0/(N+1)** ×4
- [ ] PC1 → Switch0 Fa0/1 · PC2 → Switch2 Fa0/1 · DNS → Switch1 Fa0/3 · HTTP → Switch3 Fa0/3
- [ ] Todo encendido y luces SYS **verdes fijas**

## 2 · Switches (15 min)
Para cada uno: conectar consola → mirar el prompt → configurar.
- [ ] Switch0 · `sudo python3 scripts/linux/cisco_auto.py Switch0 --borrar`
- [ ] Switch1 · `… Switch1 --borrar`
- [ ] Switch2 · `… Switch2 --borrar`
- [ ] Switch3 · `… Switch3 --borrar`
- [ ] Switch4 · `… Switch4 --borrar`
- [ ] En cada uno: `show vlan brief` correcto

## 3 · Routers (15 min)
- [ ] Router0 · `sudo python3 scripts/linux/cisco_auto.py Router0` (**sin** `--borrar`)
- [ ] Router1 · Router2 · Router3
- [ ] En cada uno: `show cdp neighbors` → cables correctos
- [ ] En cada uno: `show ip route` → 3 C + 6 S, sin rutas raras de otros grupos
- [ ] `show version | include register` → 0x2102
- [ ] Desde un router: `ping 172.16.3.193`, `.194`, `.195`, `.196` → todos `!!!!!`

## 4 · Servidores (10 min)
- [ ] DNS: `sudo bash scripts/linux/servidor_dns.sh` → `Address: 172.16.3.66`
- [ ] HTTP: `sudo bash scripts/linux/servidor_http.sh` → `<h1>Red hospitalaria G3</h1>`

## 5 · PCs (10 min)
- [ ] PC1 Windows: `configurar_pc_windows.bat` → opción 1 → [OK] gateway
- [ ] PC2 Ubuntu: `sudo bash scripts/linux/configurar_pc_linux.sh 2` → ping OK

## 6 · Pruebas y evidencias (15 min)
- [ ] PC1: `ping 172.16.1.10` (PC2) → respuestas
- [ ] PC1: `nslookup www.hospital.local` → 172.16.3.66
- [ ] PC1: navegador `http://www.hospital.local` → **captura**
- [ ] PC1: `tracert -d 172.16.3.66` → **captura**
- [ ] `pruebas_windows.bat` y `pruebas.sh` → archivos de evidencia
- [ ] `cisco_auto.py <Equipo> --evidencia` para los 9 equipos (o picocom con `--logfile`)

## 7 · Antes de llamar al profe
- [ ] Todos los equipos **guardados** (`copy running-config startup-config`)
- [ ] Consola abierta en un switch y en un router
- [ ] Excel abierto en la hoja VLSM
- [ ] Cada uno sabe qué escenario de [11](11_sustentacion_cambios_en_vivo.md) explicaría

## 8 · Al terminar
- [ ] PCs restaurados: `configurar_pc_windows.bat` → R · `sudo bash configurar_pc_linux.sh restaurar`
- [ ] Evidencias copiadas a `evidencias/` y subidas a GitHub (`git add -A && git commit -m "…" && git push`)
