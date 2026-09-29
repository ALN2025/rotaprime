@echo off
title ROTA PRIME - subir APK do build para GitHub Releases
cd /d "%~dp0"

set "APK_SRC=build\app\outputs\flutter-apk\ROTA_PRIME.apk"
set "CONFIRA_SRC=build\app\outputs\flutter-apk\ROTA_PRIME.CONFIRA.txt"

if not exist "%APK_SRC%" (
  echo [ERRO] APK nao encontrado. Rode COMPILAR.APK.bat primeiro:
  echo   %CD%\%APK_SRC%
  pause
  exit /b 1
)

for /f "usebackq tokens=1,2 delims=:" %%A in (`findstr /r "^version:" pubspec.yaml`) do set "RAW=%%B"
set "RAW=%RAW: =%"
for /f "delims=+" %%V in ("%RAW%") do set "APP_VER=%%V"
set "TAG=v%APP_VER%"

echo.
echo  Origem oficial: %APK_SRC%
echo  Tag GitHub:     %TAG%
echo.

where gh >nul 2>&1
if errorlevel 1 (
  echo [ERRO] GitHub CLI ^(gh^) nao esta no PATH. Instale: https://cli.github.com/
  pause
  exit /b 1
)

if not exist "release" mkdir "release"
copy /Y "%APK_SRC%" "release\ROTA_PRIME.apk" >nul
copy /Y "%APK_SRC%" "ROTA_PRIME.apk" >nul
if exist "%CONFIRA_SRC%" copy /Y "%CONFIRA_SRC%" "release\ROTA_PRIME.CONFIRA.txt" >nul
if exist "%CONFIRA_SRC%" copy /Y "%CONFIRA_SRC%" "ROTA_PRIME.CONFIRA.txt" >nul

for %%A in ("%APK_SRC%") do set "SIZE=%%~zA"
echo Tamanho: %SIZE% bytes
echo.

gh release view "%TAG%" >nul 2>&1
if errorlevel 1 (
  echo Criando release %TAG%...
  gh release create "%TAG%" "%APK_SRC%#ROTA_PRIME.apk" --title "ROTA PRIME %APP_VER%" --notes "APK compilado de build\app\outputs\flutter-apk. Link: https://github.com/ALN2025/rotaprime/releases/download/%TAG%/ROTA_PRIME.apk"
) else (
  echo Atualizando asset na release %TAG%...
  gh release upload "%TAG%" "%APK_SRC%#ROTA_PRIME.apk" --clobber
)

if errorlevel 1 (
  echo [ERRO] Falha ao publicar. Verifique: gh auth status
  pause
  exit /b 1
)

echo.
echo ============================================
echo   Publicado: releases/download/%TAG%/ROTA_PRIME.apk
echo   Latest:    https://github.com/ALN2025/rotaprime/releases/latest
echo ============================================
echo.
pause
exit /b 0
