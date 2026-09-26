@echo off
chcp 65001 >nul
title ROTA PRIME - compilar APK celular

cd /d "%~dp0"

set "OUT_DIR=build\app\outputs\flutter-apk"
set "APK_FLUTTER=%OUT_DIR%\app-release.apk"
set "APK_OUT=%OUT_DIR%\ROTA_PRIME.apk"

if exist "D:\Android Studio\jbr\bin\java.exe" (
  set "JAVA_HOME=D:\Android Studio\jbr"
) else if exist "C:\Program Files\Android\Android Studio\jbr\bin\java.exe" (
  set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
)
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"

if not exist "C:\gradle-rota-prime" mkdir "C:\gradle-rota-prime"
set "GRADLE_USER_HOME=C:\gradle-rota-prime"
rem NAO apague .gradle\native antes de compilar — causa "Could not extract native JNI library".
rem Se der esse erro, rode REPARAR-GRADLE.bat uma vez.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\stop_gradle_daemons.ps1" 2>nul
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop 2>nul
  popd
)

echo.
echo  ROTA PRIME - APK celular (ARM 32 + 64, ~26 MB)
echo    %APK_OUT%
echo.

where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Flutter nao encontrado.
  pause
  exit /b 1
)

echo [1/4] flutter pub get...
call flutter pub get
if errorlevel 1 goto :falha_gradle

echo [2/4] Isar...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 goto :falha_gradle

echo [3/4] Compilando release...
set "ROTA_LEGACY_PACKAGING=1"
call flutter build apk --release --target-platform android-arm,android-arm64
if errorlevel 1 goto :falha_gradle

if not exist "%APK_FLUTTER%" goto :falha_gradle

if exist "%APK_OUT%" del /F /Q "%APK_OUT%"
move /Y "%APK_FLUTTER%" "%APK_OUT%" >nul
if not exist "%APK_OUT%" goto :falha_gradle

for %%A in ("%APK_OUT%") do set SIZE_MOBILE=%%~zA
if %SIZE_MOBILE% LSS 15000000 (
  echo [ERRO] APK incompleto (%SIZE_MOBILE% bytes^).
  goto :falha_gradle
)

echo [4/4] Conferindo APK...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\verify_apk.ps1" -ApkPath "%CD%\%APK_OUT%" -Target Mobile 2>nul
if errorlevel 1 goto :falha_gradle

echo.
echo ============================================
echo   %CD%\%APK_OUT%
echo   %SIZE_MOBILE% bytes
echo ============================================
echo.

explorer /select,"%CD%\%APK_OUT%"
pause
exit /b 0

:falha_gradle
echo.
echo Compilacao falhou ou APK invalido.
echo.
echo Se apareceu "Could not extract native JNI library":
echo   1) Feche Android Studio
echo   2) Rode FIX-GRADLE-JNI.bat ou REPARAR-GRADLE.bat (uma vez)
echo   3) Rode COMPILAR.APK.bat de novo
echo.
pause
exit /b 1
