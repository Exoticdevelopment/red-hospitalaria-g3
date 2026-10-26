# =====================================================================
#  diagnostico_windows.ps1 - "Donde se rompe?" capa por capa
#  Abrir con diagnostico_windows.bat
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
$DNS = "172.16.3.130"; $HTTP = "172.16.3.66"
function Ok($t)  { Write-Host "  [OK]    $t" -ForegroundColor Green }
function Mal($t, $p) { Write-Host "  [FALLA] $t" -ForegroundColor Red; Write-Host "          -> $p" -ForegroundColor Yellow }
function P($ip) { Test-Connection $ip -Count 2 -Quiet }

Write-Host "=========== DIAGNOSTICO RED HOSPITAL G3 ===========" -ForegroundColor Cyan
$a = Get-NetAdapter -Physical | Where-Object { $_.NdisPhysicalMedium -eq 14 } | Sort-Object Status -Descending | Select-Object -First 1
Write-Host "Tarjeta: $($a.Name)"
if ($a.Status -eq "Up") { Ok "Capa 1: el cable tiene link" } else { Mal "Capa 1: sin cable ($($a.Status))" "cable suelto o puerto del switch apagado"; pause; exit }

$c = Get-NetIPConfiguration -InterfaceAlias $a.Name
$ip = $c.IPv4Address.IPAddress; $gw = $c.IPv4DefaultGateway.NextHop
if ($ip -like "169.254.*" -or -not $ip) { Mal "Sin IP valida ($ip)" "corre configurar_pc_windows.bat"; pause; exit } else { Ok "IP: $ip" }
if ($gw) { Ok "Gateway: $gw" } else { Mal "Sin gateway" "corre configurar_pc_windows.bat"; pause; exit }

$otras = Get-NetIPConfiguration | Where-Object { $_.InterfaceAlias -ne $a.Name -and $_.IPv4DefaultGateway }
if ($otras) { Mal "Otra tarjeta tiene gateway: $($otras.InterfaceAlias -join ', ')" "apagala (Wi-Fi/VPN) o corre configurar_pc_windows.bat" }

if (P $gw) { Ok "Ping al gateway (VLAN + trunk + subinterfaz)" } else { Mal "No responde el gateway $gw" "show vlan brief / show interfaces trunk / show ip interface brief"; pause; exit }
foreach ($r in "172.16.3.193","172.16.3.194","172.16.3.195","172.16.3.196") {
  if (P $r) { Ok "Router en R5: $r" } else { Mal "No responde $r" "cable del router al Switch4 o falta ruta de regreso (show ip route)" }
}
if (P $DNS)  { Ok "Ping al DNS $DNS" }   else { Mal "No llega al DNS"  "rutas hacia 172.16.3.128/27 o servidor apagado" }
if (P $HTTP) { Ok "Ping al HTTP $HTTP" } else { Mal "No llega al HTTP" "rutas hacia 172.16.3.64/26 o servidor apagado" }

if ((Get-DnsClientServerAddress -InterfaceAlias $a.Name -AddressFamily IPv4).ServerAddresses -contains $DNS) { Ok "El PC usa el DNS $DNS" } else { Mal "El PC no usa el DNS del hospital" "corre configurar_pc_windows.bat" }
$r = Resolve-DnsName www.hospital.local -Server $DNS -Type A -DnsOnly
if ($r.IPAddress -eq $HTTP) { Ok "DNS: www.hospital.local -> $HTTP" } else { Mal "El DNS no resuelve el nombre" "en el servidor: sudo systemctl status dnsmasq" }

if ((Test-NetConnection $HTTP -Port 80 -WarningAction SilentlyContinue).TcpTestSucceeded) { Ok "Puerto 80 abierto en el servidor web" } else { Mal "Puerto 80 cerrado" "en el servidor: sudo systemctl status apache2" }
if ((Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings").ProxyEnable -eq 1) { Mal "El navegador tiene proxy activado" "configurar_pc_windows.bat lo quita" } else { Ok "Sin proxy en el navegador" }
Write-Host "==================================================="
pause
