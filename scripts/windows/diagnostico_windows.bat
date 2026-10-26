@echo off
:: diagnostico_windows.bat - revisa la red capa por capa y dice donde falla
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0diagnostico_windows.ps1"
