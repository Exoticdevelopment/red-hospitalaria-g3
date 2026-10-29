@echo off
:: recorrido_windows.bat - Prueba de las 8 LAN cambiando IPs (doble clic)
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Pidiendo permisos de administrador...
  powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0recorrido_windows.ps1"
echo.
pause
