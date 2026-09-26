@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title ROTA PRIME - Demo FIEL (APK no emulador)
cd /d "%~dp0"

set "AVD=O_ATIVADOR"
set "APK=..\build\app\outputs\flutter-apk\ROTA_PRIME.apk"
if exist "emulator.config" (
  for /f "usebackq eol=; tokens=1,* delims==" %%A in ("emulator.config") do (
    if /i not "%%A"=="REM" if not "%%A"=="" (
      if /i "%%A"=="AVD" set "AVD=%%B"
      if /i "%%A"=="APK" set "APK=%%B"
    )
  )
)

for %%I in ("%APK%") do set "APK_FULL=%%~fI"
if not exist "%APK_FULL%" set "APK_FULL=%~dp0..\release\ROTA_PRIME.apk"
if not exist "%APK_FULL%" (
  echo.
  echo [ERRO] APK nao encontrado.
  echo Rode primeiro na raiz do projeto: COMPILAR.APK.bat
  echo.
  pause
  exit /b 1
)

if exist "C:\Android\sdk\platform-tools\adb.exe" (
  set "ADB=C:\Android\sdk\platform-tools\adb.exe"
) else if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
  set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
) else (
  set "ADB=adb"
)

echo.
echo ============================================
echo   ROTA PRIME - APK REAL no emulador
echo   ^(identico ao celular — ideal para video^)
echo ============================================
echo   APK: %APK_FULL%
echo   Emulador: %AVD%
echo.

"%ADB%" devices 2>nul | findstr /r "device$" | findstr /v "List" >nul
if errorlevel 1 (
  echo Iniciando emulador %AVD% ^(aguarde 1-3 min na 1a vez^)...
  start "" flutter emulators --launch %AVD%
  echo Aguardando Android ligar...
  "%ADB%" wait-for-device
  set /a _t=0
  :wait_boot
  "%ADB%" shell getprop sys.boot_completed 2>nul | findstr "1" >nul
  if errorlevel 1 (
    set /a _t+=1
    if !_t! GTR 90 (
      echo Timeout aguardando boot. Abra o emulador manualmente e rode de novo.
      pause
      exit /b 1
    )
    timeout /t 2 /nobreak >nul
    goto wait_boot
  )
) else (
  echo Dispositivo/emulador ja conectado.
)

echo.
echo Instalando APK...
"%ADB%" install -r "%APK_FULL%"
if errorlevel 1 (
  echo Falha na instalacao. Veja a mensagem acima.
  pause
  exit /b 1
)

echo Abrindo ROTA PRIME...
"%ADB%" shell am start -n com.rotaprime.rota_prime/com.rotaprime.rota_prime.MainActivity

where scrcpy >nul 2>&1
if errorlevel 1 (
  echo.
  echo APK instalado. Grave a JANELA DO EMULADOR no OBS.
  echo.
  echo Opcional — espelho limpo: instale scrcpy
  echo   winget install Genymobile.scrcpy
  echo Depois rode este .bat de novo.
  echo.
  echo LICENCA PRO no emulador:
  echo   Configuracoes ^> ID do aparelho ^> copiar
  echo   No PC: GERAR-LICENCA.bat com esse ID
  echo.
  pause
  exit /b 0
)

echo.
echo Abrindo scrcpy ^(janela do celular para gravar^)...
echo Feche o scrcpy para encerrar.
echo.
scrcpy --window-title "ROTA PRIME APK" --max-size 1080 --stay-awake
pause
