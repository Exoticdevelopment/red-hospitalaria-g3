# =====================================================================
#  configurar_pc_windows.ps1 - IP estatica para un PC Windows (Hospital G3)
#  NO se abre directo: usar configurar_pc_windows.bat (lo pide como admin).
#
#  Pensado para PCs del laboratorio que usaron otros grupos:
#   - escoge solo la tarjeta de CABLE y avisa si no tiene cable conectado
#   - borra IPs, gateways y DNS viejos de esa tarjeta
#   - apaga Wi-Fi y cualquier otra tarjeta que tenga gateway (VPN, VirtualBox...)
#   - quita el proxy del navegador y entradas viejas del archivo hosts
#   - apaga IPv6 en la tarjeta (la red del examen es solo IPv4)
#   - permite el ping (ICMP) en el firewall
#   - guarda TODO en C:\G3_backup para poder restaurar (opcion R)
#  (Sin tildes a proposito: PowerShell 5 lee mal los acentos.)
# =====================================================================
param([string]$Opcion = "")
$ErrorActionPreference = "SilentlyContinue"
$DNS = "172.16.3.130"
$BK  = "C:\G3_backup"
New-Item -ItemType Directory -Force -Path $BK | Out-Null

$tabla = @{
  "1" = @("172.16.2.10",  25, "172.16.2.1",   "PC1 Urgencias       Switch0 Fa0/1 VLAN 210")
  "2" = @("172.16.1.10",  24, "172.16.1.1",   "PC2 Consulta        Switch2 Fa0/1 VLAN 250")
  "3" = @("172.16.0.10",  24, "172.16.0.1",   "PC Hospitalizacion  Switch0 Fa0/2 VLAN 220")
  "4" = @("172.16.3.10",  26, "172.16.3.1",   "PC Laboratorio      Switch1 Fa0/1 VLAN 230")
  "5" = @("172.16.3.138", 27, "172.16.3.129", "PC Farmacia         Switch1 Fa0/2 VLAN 240")
  "6" = @("172.16.2.138", 25, "172.16.2.129", "PC Imagenes         Switch2 Fa0/2 VLAN 260")
  "7" = @("172.16.3.74",  26, "172.16.3.65",  "PC Administracion   Switch3 Fa0/1 VLAN 270")
  "8" = @("172.16.3.170", 27, "172.16.3.161", "PC Ing. biomedica   Switch3 Fa0/2 VLAN 280")
}

function Titulo($t) { Write-Host ""; Write-Host "===== $t =====" -ForegroundColor Cyan }

# ---------- Menu ----------
if (-not $Opcion) {
  Titulo "Red hospitalaria G3 - Configurar PC Windows"
  foreach ($k in "1","2","3","4","5","6","7","8") {
    $d = $tabla[$k]; Write-Host ("  {0}) {1}  ->  {2}/{3}" -f $k, $d[3], $d[0], $d[1])
  }
  Write-Host "  R) RESTAURAR el PC como estaba (DHCP, Wi-Fi, proxy)"
  $Opcion = Read-Host "Escribe el numero"
}

# ---------- Tarjeta de cable ----------
# NdisPhysicalMedium 14 = Ethernet (cable). Asi se descarta Wi-Fi y Bluetooth.
$cables = Get-NetAdapter -Physical | Where-Object { $_.NdisPhysicalMedium -eq 14 }
$adap = $cables | Where-Object Status -eq "Up" | Select-Object -First 1
if (-not $adap) { $adap = $cables | Select-Object -First 1 }
if (-not $adap) { Write-Host "[!] No encontre tarjeta de red de cable." -ForegroundColor Red; exit 1 }
$nombre = $adap.Name

# =====================================================================
#  RESTAURAR
# =====================================================================
if ($Opcion -match "^[Rr]") {
  Titulo "Restaurando $nombre"
  Set-NetIPInterface -InterfaceAlias $nombre -Dhcp Enabled
  Remove-NetRoute -InterfaceAlias $nombre -DestinationPrefix "0.0.0.0/0" -Confirm:$false
  Set-DnsClientServerAddress -InterfaceAlias $nombre -ResetServerAddresses
  Enable-NetAdapterBinding -Name $nombre -ComponentID ms_tcpip6
  if (Test-Path "$BK\apagadas.txt") {
    Get-Content "$BK\apagadas.txt" | ForEach-Object { Enable-NetAdapter -Name $_ -Confirm:$false; Write-Host "  encendida: $_" }
    Remove-Item "$BK\apagadas.txt"
  }
  if (Test-Path "$BK\proxy.txt") {
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" ProxyEnable ([int](Get-Content "$BK\proxy.txt"))
  }
  netsh advfirewall firewall delete rule name="G3-ICMP" | Out-Null
  ipconfig /renew $nombre | Out-Null
  Write-Host "Listo: el PC vuelve a DHCP." -ForegroundColor Green
  exit 0
}

if (-not $tabla.ContainsKey($Opcion)) { Write-Host "Opcion no valida"; exit 1 }
$IP, $PREF, $GW, $DESC = $tabla[$Opcion]

Titulo "Configurando $DESC"
Write-Host "Tarjeta: $nombre ($($adap.InterfaceDescription))"
Write-Host "IP $IP/$PREF   gateway $GW   DNS $DNS"

# ---------- 1. Revisar el cable (capa 1) ----------
if ($adap.Status -ne "Up") {
  Write-Host "[!] OJO: la tarjeta NO detecta cable (estado: $($adap.Status))." -ForegroundColor Yellow
  Write-Host "    Revisa el cable y el puerto del switch. Continuo igual." -ForegroundColor Yellow
}

# ---------- 2. Copia de seguridad (solo la primera vez) ----------
if (-not (Test-Path "$BK\ipconfig_antes.txt")) { ipconfig /all > "$BK\ipconfig_antes.txt" }
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
if (-not (Test-Path "$BK\proxy.txt")) { (Get-ItemProperty $reg).ProxyEnable | Out-File "$BK\proxy.txt" }

# ---------- 3. Apagar otras tarjetas que puedan "robar" el trafico ----------
# El Wi-Fi y las tarjetas con gateway (VPN, VirtualBox, etc.) dan otro camino.
$otras = Get-NetAdapter | Where-Object { $_.Name -ne $nombre -and $_.Status -eq "Up" } | Where-Object {
  $_.NdisPhysicalMedium -eq 9 -or (Get-NetIPConfiguration -InterfaceAlias $_.Name).IPv4DefaultGateway
}
foreach ($o in $otras) {
  Disable-NetAdapter -Name $o.Name -Confirm:$false
  Add-Content "$BK\apagadas.txt" $o.Name
  Write-Host "  apagada: $($o.Name)"
}

# ---------- 4. Limpiar la tarjeta y poner la IP ----------
Set-NetIPInterface -InterfaceAlias $nombre -Dhcp Disabled                  # sin DHCP
Get-NetIPAddress -InterfaceAlias $nombre -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false
Get-NetRoute -InterfaceAlias $nombre -DestinationPrefix "0.0.0.0/0" | Remove-NetRoute -Confirm:$false
New-NetIPAddress -InterfaceAlias $nombre -IPAddress $IP -PrefixLength $PREF -DefaultGateway $GW | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $nombre -ServerAddresses $DNS
Set-DnsClient -InterfaceAlias $nombre -ConnectionSpecificSuffix ""           # sin sufijo DNS viejo
Disable-NetAdapterBinding -Name $nombre -ComponentID ms_tcpip6               # sin IPv6

# ---------- 5. Proxy, hosts y cache DNS ----------
Set-ItemProperty $reg ProxyEnable 0          # proxy del navegador apagado
netsh winhttp reset proxy | Out-Null
$hosts = "$env:windir\System32\drivers\etc\hosts"
$lineas = Get-Content $hosts
if ($lineas -match "hospital\.local") {
  Copy-Item $hosts "$BK\hosts.antes" -Force
  $lineas | Where-Object { $_ -notmatch "hospital\.local" } | Set-Content $hosts
  Write-Host "  quitada una entrada vieja de hospital.local en el archivo hosts"
}
ipconfig /flushdns | Out-Null

# ---------- 6. Firewall: dejar que nos hagan ping ----------
netsh advfirewall firewall delete rule name="G3-ICMP" | Out-Null
netsh advfirewall firewall add rule name="G3-ICMP" protocol=icmpv4:8,any dir=in action=allow | Out-Null

Write-Host "Esperando 5 segundos..."; Start-Sleep 5

# ---------- 7. Pruebas ----------
Titulo "Configuracion"
Get-NetIPConfiguration -InterfaceAlias $nombre | Format-List InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer

function Prueba($ip, $que) {
  if (Test-Connection $ip -Count 2 -Quiet) { Write-Host "  [OK]    $que ($ip)" -ForegroundColor Green; return $true }
  Write-Host "  [FALLA] $que ($ip)" -ForegroundColor Red; return $false
}
Titulo "Pruebas"
if (-not (Prueba $GW "Gateway (VLAN + trunk + subinterfaz)")) {
  Write-Host "  -> Revisa: cable en el puerto correcto, 'show vlan brief' y 'show interfaces trunk' en el switch." -ForegroundColor Yellow
}
Prueba $DNS "Servidor DNS" | Out-Null
Prueba "172.16.3.66" "Servidor HTTP" | Out-Null
Titulo "nslookup www.hospital.local"
nslookup www.hospital.local $DNS
Write-Host ""
Write-Host "Listo. Abre el navegador en  http://www.hospital.local" -ForegroundColor Green
Write-Host "Si algo falla corre diagnostico_windows.bat. Para deshacer todo: este script, opcion R."
