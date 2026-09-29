@echo off
title ROTA PRIME - compilar APK celular

cd /d "%~dp0"

set "OUT_DIR=build\app\outputs\flutter-apk"
set "APK_FLUTTER=%OUT_DIR%\app-release.apk"
set "APK_OUT=%OUT_DIR%\ROTA_PRIME.apk"

rem Limpa JAVA_HOME invalido (ex.: Studio em C: mas so existe em D:)
if defined JAVA_HOME if not exist "%JAVA_HOME%\bin\java.exe" set "JAVA_HOME="

if exist "D:\Android Studio\jbr\bin\java.exe" (
  set "JAVA_HOME=D:\Android Studio\jbr"
) else if exist "C:\Program Files\Android\Android Studio\jbr\bin\java.exe" (
  set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
)
if defined JAVA_HOME set "PATH=%JAVA_HOME%\bin;%PATH%"

if not exist "C:\gradle-rota-prime" mkdir "C:\gradle-rota-prime"
set "GRADLE_USER_HOME=C:\gradle-rota-prime"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\stop_gradle_daemons.ps1" 2>nul
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop 2>nul
  popd
)

echo.
echo  ROTA PRIME - APK celular (ARM 32 + 64)
echo    %APK_OUT%
echo.

where flutter >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Flutter nao encontrado no PATH.
  pause
  exit /b 1
)

echo [1/4] flutter pub get...
call flutter pub get
if errorlevel 1 goto falha_gradle

echo [2/4] Isar...
call dart run build_runner build
if errorlevel 1 goto falha_gradle

echo [3/4] Compilando release...
rem Packaging JNI padrao (legacy) — nao definir ROTA_LEGACY_PACKAGING=0 aqui (quebra packageRelease no AGP 8).
call flutter build apk --release --target-platform android-arm,android-arm64
if errorlevel 1 goto falha_gradle

if not exist "%APK_FLUTTER%" goto falha_gradle

if exist "%APK_OUT%" del /F /Q "%APK_OUT%"
if exist "%APK_FLUTTER%" (
  move /Y "%APK_FLUTTER%" "%APK_OUT%" >nul
)
if not exist "%APK_OUT%" (
  if exist "%APK_FLUTTER%" copy /Y "%APK_FLUTTER%" "%APK_OUT%" >nul
)
if not exist "%APK_OUT%" goto falha_gradle

copy /Y "%APK_OUT%" "ROTA_PRIME.apk" >nul
if not exist "release" mkdir "release"
copy /Y "%APK_OUT%" "release\ROTA_PRIME.apk" >nul

for %%A in ("%APK_OUT%") do set "SIZE_MOBILE=%%~zA"
if %SIZE_MOBILE% LSS 15000000 (
  echo [ERRO] APK incompleto (%SIZE_MOBILE% bytes^).
  goto falha_gradle
)

echo [4/4] Conferindo APK...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\verify_apk.ps1" -ApkPath "%CD%\%APK_OUT%" -Target Mobile 2>nul
if errorlevel 1 goto falha_gradle

echo.
echo ============================================
echo   %CD%\%APK_OUT%
echo   %CD%\ROTA_PRIME.apk
echo   %CD%\release\ROTA_PRIME.apk
echo   %SIZE_MOBILE% bytes
echo.
echo   GitHub: SUBIR-GITHUB-RELEASE.bat
echo ============================================
echo.

explorer /select,"%CD%\%APK_OUT%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\stop_gradle_daemons.ps1" 2>nul
if exist "android\gradlew.bat" (
  pushd android
  call gradlew.bat --stop 2>nul
  popd
)

pause
exit /b 0

:falha_gradle
echo.
echo Compilacao falhou ou APK invalido.
echo Se JNI/Gradle: feche o Studio, rode REPARAR-GRADLE.bat, tente de novo.
echo.
pause
exit /b 1
