@echo off
:: =====================================================================
::  pruebas_windows.bat - Pruebas finales desde un PC Windows
::  Uso: doble clic. Guarda la evidencia en evidencia_%COMPUTERNAME%.txt
:: =====================================================================
set OUT=evidencia_%COMPUTERNAME%.txt
echo ===== %date% %time%  equipo %COMPUTERNAME% ===== > %OUT%
ipconfig >> %OUT%
for %%I in (172.16.2.1 172.16.0.1 172.16.3.1 172.16.3.129 172.16.1.1 172.16.2.129 172.16.3.65 172.16.3.161 172.16.3.193 172.16.3.194 172.16.3.195 172.16.3.196 172.16.3.130 172.16.3.66 172.16.2.10 172.16.1.10) do (
  echo. >> %OUT%
  echo --- ping %%I --- >> %OUT%
  ping -n 3 %%I >> %OUT%
)
echo. >> %OUT%
echo --- nslookup www.hospital.local --- >> %OUT%
nslookup www.hospital.local 172.16.3.130 >> %OUT% 2>&1
echo. >> %OUT%
echo --- tracert 172.16.3.66 --- >> %OUT%
tracert -d -h 5 172.16.3.66 >> %OUT%
type %OUT%
echo.
echo Abre el navegador en http://www.hospital.local y toma captura.
start http://www.hospital.local
pause
