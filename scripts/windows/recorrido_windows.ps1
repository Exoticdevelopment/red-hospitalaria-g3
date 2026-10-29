# =====================================================================
#  recorrido_windows.ps1 - La prueba que pidio el profesor:
#  "con los PCs, cambiando las IPs, probar todas las LAN"
#  Abrir con recorrido_windows.bat (pide administrador).
#
#  El PC VISITA las areas una por una. En cada una:
#   1) dice a que puerto mover el cable y espera Enter
#   2) cambia la IP (usa configurar_pc_windows.ps1)
#   3) prueba gateway, routers, DNS y HTTP por nombre
#   4) guarda la evidencia en C:\G3_evidencias\<area>.txt
# =====================================================================
$ErrorActionPreference = "SilentlyContinue"
$DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OUT = "C:\G3_evidencias"
New-Item -ItemType Directory -Force -Path $OUT | Out-Null

$A = @{
  "1" = @("R1_Urgencias",       "Switch0 Fa0/1", "172.16.2.10",  "172.16.2.1")
  "2" = @("R6_Consulta",        "Switch2 Fa0/1", "172.16.1.10",  "172.16.1.1")
  "3" = @("R2_Hospitalizacion", "Switch0 Fa0/2", "172.16.0.10",  "172.16.0.1")
  "4" = @("R3_Laboratorio",     "Switch1 Fa0/1", "172.16.3.10",  "172.16.3.1")
  "5" = @("R4_Farmacia",        "Switch1 Fa0/2", "172.16.3.138", "172.16.3.129")
  "6" = @("R7_Imagenes",        "Switch2 Fa0/2", "172.16.2.138", "172.16.2.129")
  "7" = @("R8_Administracion",  "Switch3 Fa0/1", "172.16.3.74",  "172.16.3.65")
  "8" = @("R9_Ing_Biomedica",   "Switch3 Fa0/2", "172.16.3.170", "172.16.3.161")
}

Write-Host "===== RECORRIDO DE LAS LAN (cambiando IPs) =====" -ForegroundColor Cyan
Write-Host "Escribe las areas a visitar separadas por espacio."
Write-Host "Ejemplo PC1: 1 3 4 5     Ejemplo PC2: 2 6 7 8     Enter = las 8"
$entrada = Read-Host "Areas"
if (-not $entrada) { $lista = "1","3","4","5","2","6","7","8" } else { $lista = $entrada -split "\s+" }

function P($ip) { Test-Connection $ip -Count 2 -Quiet }
$res = @()

foreach ($n in $lista) {
  if (-not $A.ContainsKey($n)) { Write-Host "Opcion $n no existe"; continue }
  $area, $puerto, $ip, $gw = $A[$n]
  Write-Host ""
  Write-Host "################################################################" -ForegroundColor Yellow
  Write-Host "  AREA ${n}: $area" -ForegroundColor Yellow
  Write-Host "  1) Mueve el cable de este PC a:  $puerto" -ForegroundColor Yellow
  Write-Host "  2) Presiona Enter cuando este conectado (o escribe s para saltar)" -ForegroundColor Yellow
  Write-Host "################################################################" -ForegroundColor Yellow
  if ((Read-Host) -eq "s") { $res += [pscustomobject]@{Area=$area; Gateway="saltada"; DNS=""; HTTP=""}; continue }

  & "$DIR\configurar_pc_windows.ps1" -Opcion $n | Out-Null
  Start-Sleep 3

  $g = if (P $gw) { "OK" } else { "FALLA" }
  $rt = foreach ($r in "172.16.3.193","172.16.3.194","172.16.3.195","172.16.3.196") { "Router R5 $r : " + $(if (P $r) {"OK"} else {"FALLA"}) }
  $d = if ((Resolve-DnsName www.hospital.local -Server 172.16.3.130 -Type A -DnsOnly).IPAddress -eq "172.16.3.66") { "OK" } else { "FALLA" }
  $h = "FALLA"
  try { if ((Invoke-WebRequest "http://www.hospital.local" -UseBasicParsing -TimeoutSec 5 -NoProxy).Content -match "hospital") { $h = "OK" } }
  catch { try { if ((Invoke-WebRequest "http://www.hospital.local" -UseBasicParsing -TimeoutSec 5).Content -match "hospital") { $h = "OK" } } catch {} }

  $f = "$OUT\$n-$area.txt"
  @(
    "===== $(Get-Date)  |  $env:COMPUTERNAME  |  $area  |  $puerto ====="
    (ipconfig | Out-String)
    "--- Pruebas desde $area ($ip) ---"
    "Gateway $gw : $g"
    $rt
    "DNS www.hospital.local : $d"
    "HTTP por nombre : $h"
    "--- Camino al servidor web ---"
    (tracert -d -h 5 172.16.3.66 | Out-String)
  ) | Out-File $f -Encoding utf8
  Get-Content $f | Select-Object -Last 14
  $res += [pscustomobject]@{Area=$area; Gateway=$g; DNS=$d; HTTP=$h}
}

Write-Host ""
Write-Host "==================== RESUMEN DEL RECORRIDO ====================" -ForegroundColor Cyan
$res | Format-Table -AutoSize
Write-Host "Evidencias guardadas en: $OUT"
$fin = Read-Host "Numero del area donde dejar el PC al final (Enter = no cambiar)"
if ($fin) { & "$DIR\configurar_pc_windows.ps1" -Opcion $fin | Out-Null; Write-Host "PC dejado en la opcion $fin (mueve el cable a ese puerto)." }
