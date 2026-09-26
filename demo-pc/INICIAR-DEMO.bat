@echo off
chcp 65001 >nul
title ROTA PRIME - Aviso demo
cd /d "%~dp0"

echo.
echo  ===================================================
echo   Para video FIEL ao APK use:
echo.
echo   INICIAR-DEMO-FIEL.bat
echo   ^(ou DEMO-VIDEO-FIEL.bat na pasta ROTA PRIME^)
echo.
echo   Isso abre o APK REAL no emulador Android.
echo  ===================================================
echo.
choice /C FN /M "Continuar com preview HTML (nao e o app real)? [F]iel / [N]preview"
if errorlevel 2 goto preview
if errorlevel 1 call "%~dp0INICIAR-DEMO-FIEL.bat"
exit /b 0

:preview
node server.js
pause
