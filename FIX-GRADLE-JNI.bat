@echo off
chcp 65001 >nul
title ROTA PRIME - corrigir Gradle JNI
cd /d "%~dp0"

if exist "D:\Android Studio\jbr\bin\java.exe" (
  set "JAVA_HOME=D:\Android Studio\jbr"
) else if exist "C:\Program Files\Android\Android Studio\jbr\bin\java.exe" (
  set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
)
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"

set "GRADLE_USER_HOME=C:\gradle-rota-prime"

echo.
echo  Corrige: Could not extract native JNI library
echo  Feche o Android Studio se estiver aberto.
echo.
pause

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\fix_gradle_jni.ps1"

if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --version
  set "RC=%ERRORLEVEL%"
  popd
  if not "%RC%"=="0" (
    echo.
    echo Gradle ainda falhou. Reinicie o PC e rode este script de novo.
    pause
    exit /b 1
  )
)

echo.
echo Pronto. Agora rode COMPILAR.APK.bat
echo.
pause
exit /b 0
