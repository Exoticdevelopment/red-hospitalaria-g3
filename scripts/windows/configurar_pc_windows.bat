@echo off
:: =====================================================================
::  configurar_pc_windows.bat - Lanzador (doble clic)
::  Pide permisos de administrador y abre configurar_pc_windows.ps1
::  Uso: doble clic  -> aparece el menu 1..8 o R (restaurar)
:: =====================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Pidiendo permisos de administrador...
  powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configurar_pc_windows.ps1" %*
echo.
pause
