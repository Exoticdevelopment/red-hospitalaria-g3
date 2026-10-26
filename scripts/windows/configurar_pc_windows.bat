@echo off
:: ============================================================
::  Hospital G3 - Configurar IP de un PC Windows (cliente)
::  Clic derecho -> "Ejecutar como administrador"
:: ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo.
  echo  [!] Ejecuta este archivo con clic derecho - "Ejecutar como administrador"
  echo.
  pause
  exit /b
)

echo.
echo  ===== Hospital G3 - Configuracion de PC =====
echo.
echo   1) PC1  Urgencias          (Switch0 Fa0/1)  172.16.2.10/25
echo   2) PC2  Consulta externa   (Switch2 Fa0/1)  172.16.1.10/24
echo   3) PC   Hospitalizacion    (Switch0 Fa0/2)  172.16.0.10/24
echo   4) PC   Laboratorio        (Switch1 Fa0/1)  172.16.3.10/26
echo   5) PC   Farmacia           (Switch1 Fa0/2)  172.16.3.138/27
echo   6) PC   Imagenes           (Switch2 Fa0/2)  172.16.2.138/25
echo   7) PC   Administracion     (Switch3 Fa0/1)  172.16.3.74/26
echo   8) PC   Ing. Biomedica     (Switch3 Fa0/2)  172.16.3.170/27
echo.
set /p OP=Elige el numero del PC:

if "%OP%"=="1" set IP=172.16.2.10&  set MASK=255.255.255.128& set GW=172.16.2.1
if "%OP%"=="2" set IP=172.16.1.10&  set MASK=255.255.255.0&   set GW=172.16.1.1
if "%OP%"=="3" set IP=172.16.0.10&  set MASK=255.255.255.0&   set GW=172.16.0.1
if "%OP%"=="4" set IP=172.16.3.10&  set MASK=255.255.255.192& set GW=172.16.3.1
if "%OP%"=="5" set IP=172.16.3.138& set MASK=255.255.255.224& set GW=172.16.3.129
if "%OP%"=="6" set IP=172.16.2.138& set MASK=255.255.255.128& set GW=172.16.2.129
if "%OP%"=="7" set IP=172.16.3.74&  set MASK=255.255.255.192& set GW=172.16.3.65
if "%OP%"=="8" set IP=172.16.3.170& set MASK=255.255.255.224& set GW=172.16.3.161
if not defined IP (echo Opcion no valida & pause & exit /b)
set DNS=172.16.3.130

:: Buscar el adaptador de cable (Ethernet) automaticamente
set ADAP=
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-NetAdapter -Physical | Where-Object {$_.MediaType -eq '802.3'} | Sort-Object Status | Select-Object -First 1).Name"`) do set ADAP=%%A
if not defined ADAP set ADAP=Ethernet
echo.
echo  Adaptador de cable detectado: "%ADAP%"
set /p CAMBIO=Enter para usarlo, o escribe otro nombre:
if defined CAMBIO set ADAP=%CAMBIO%

echo.
echo  Aplicando IP %IP%  mascara %MASK%  gateway %GW%  DNS %DNS% ...
netsh interface ip set address name="%ADAP%" static %IP% %MASK% %GW%
netsh interface ip set dns name="%ADAP%" static %DNS% validate=no

:: Permitir que otros PCs le hagan ping
netsh advfirewall firewall delete rule name="G3-ICMP" >nul 2>&1
netsh advfirewall firewall add rule name="G3-ICMP" protocol=icmpv4:8,any dir=in action=allow >nul

:: Apagar Wi-Fi para que no salga por otra red
powershell -NoProfile -Command "Get-NetAdapter -Physical | Where-Object {$_.MediaType -like '*802.11*'} | Disable-NetAdapter -Confirm:$false" >nul 2>&1

echo  Esperando 5 segundos...
timeout /t 5 >nul

echo.
echo  ===== Configuracion =====
ipconfig | findstr /i "IPv4 Subnet Mascara Gateway Puerta"
echo.
echo  ===== Prueba 1: ping al gateway %GW% =====
ping -n 4 %GW%
echo.
echo  ===== Prueba 2: ping al DNS 172.16.3.130 =====
ping -n 4 172.16.3.130
echo.
echo  ===== Prueba 3: ping al HTTP 172.16.3.66 =====
ping -n 4 172.16.3.66
echo.
echo  ===== Prueba 4: nslookup www.hospital.local =====
nslookup www.hospital.local 172.16.3.130
echo.
echo  Listo. Abre el navegador en:  http://www.hospital.local
echo.
pause
