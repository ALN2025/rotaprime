@echo off

chcp 65001 >nul

title ROTA PRIME — parar Gradle / JDK da compilacao

cd /d "%~dp0"

echo Encerrando daemons Gradle (nao fecha o Android Studio)...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\stop_gradle_daemons.ps1"

if exist "android\gradlew.bat" (

  pushd android

  call gradlew.bat --stop 2>nul

  popd

)

echo Pronto.
if /i not "%~1"=="silent" timeout /t 2 >nul

