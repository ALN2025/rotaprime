@echo off

setlocal EnableDelayedExpansion

chcp 65001 >nul

title ROTA PRIME - Gerar licenca PRO

cd /d "%~dp0"



echo.

echo ============================================

echo   ROTA PRIME - Gerar licenca PRO

echo ============================================

echo.

echo Cliente: Configuracoes ^> ID do aparelho ^> Copiar
echo Saida: chave UNICA com tracos (sem QR)

echo.



where dart >nul 2>&1

if errorlevel 1 (

  echo [ERRO] Dart nao encontrado no PATH.

  pause

  exit /b 1

)



if not exist "license_keys\private.key" (

  echo [ERRO] Rode primeiro: GERAR-CHAVE-PRIMEIRA-VEZ.bat

  pause

  exit /b 1

)



set /p "BUYER=Nome do comprador: "

set /p "DEVICE=ID do aparelho: "



if "!DEVICE!"=="" (

  echo [ERRO] ID do aparelho vazio.

  pause

  exit /b 1

)



set "ROTA_BUYER=!BUYER!"

set "ROTA_DEVICE=!DEVICE!"



echo.

echo Gerando licenca...

echo.



set "OUT=%TEMP%\rota_prime_licenca_out.txt"

call dart run tool/generate_license.dart > "%OUT%" 2>&1

type "%OUT%"

set "ERR=!ERRORLEVEL!"



set "LICENSE_FILE="

for /f "tokens=1,* delims=@" %%A in ('findstr "@@LICENSE_FILE@@" "%OUT%"') do (

  set "LICENSE_FILE=%%B"

)



echo.

if not "!ERR!"=="0" (

  echo [ERRO] Falha ao gerar licenca.

  goto :fim

)



if defined LICENSE_FILE (

  echo Arquivo do cliente: %CD%\!LICENSE_FILE!

  start "" notepad "!LICENSE_FILE!"

) else if exist "license_keys\ultima_licenca.txt" (

  start "" notepad "license_keys\ultima_licenca.txt"

)

start "" explorer "%CD%\license_keys"



:fim

echo.

pause

exit /b 0

