@echo off
chcp 65001 >nul
title ROTA PRIME - Demo Electron (opcional)
cd /d "%~dp0"

where npm >nul 2>&1
if errorlevel 1 (
  echo Instale Node.js primeiro. Use INICIAR-DEMO.bat ^(navegador^).
  pause
  exit /b 1
)

if not exist "node_modules\electron\dist\electron.exe" (
  echo Baixando Electron ^(pode demorar 1-2 min^)...
  call npm install
  node node_modules\electron\install.js
)

if not exist "node_modules\electron\dist\electron.exe" (
  echo.
  echo Electron nao instalou. Use INICIAR-DEMO.bat ^(funciona no navegador^).
  pause
  exit /b 1
)

call npm start
pause
