@echo off

chcp 65001 >nul

title ROTA PRIME - Instalar por USB (adb)



cd /d "%~dp0"



set "APK=%CD%\build\app\outputs\flutter-apk\ROTA_PRIME.apk"

if not exist "%APK%" set "APK=%CD%\release\ROTA_PRIME.apk"



if not exist "%APK%" (

  echo Rode COMPILAR.APK.bat primeiro.

  pause

  exit /b 1

)



for %%A in ("%APK%") do set SIZE=%%~zA

echo APK: %APK%

echo Tamanho: %SIZE% bytes



if %SIZE% LSS 60000000 (

  echo ERRO: APK incompleto. Compile de novo com COMPILAR.APK.bat

  pause

  exit /b 1

)



if exist "C:\Android\sdk\platform-tools\adb.exe" (

  set "ADB=C:\Android\sdk\platform-tools\adb.exe"

) else (

  set "ADB=adb"

)



echo.

echo 1. Celular: Depuracao USB LIGADA

echo 2. Aceite "Permitir depuracao" no celular

echo.



"%ADB%" devices

echo.



"%ADB%" uninstall com.rotaprime.rota_prime 2>nul

echo Instalando...

"%ADB%" install -r "%APK%"

echo.



if errorlevel 1 (

  echo Se falhou, copie a linha INSTALL_FAILED acima e envie.

) else (

  echo Instalado. Abra ROTA PRIME no celular.

)



pause

