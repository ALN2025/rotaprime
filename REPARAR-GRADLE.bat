@echo off

chcp 65001 >nul

title ROTA PRIME - Reparar Gradle e gerar APK

cd /d "%~dp0"



echo ============================================

echo   Reparo: cache Gradle corrompido

echo   (erro device_info_plus / relinker / verifyReleaseResources)

echo ============================================

echo.



if exist "D:\Android Studio\jbr\bin\java.exe" (

  set "JAVA_HOME=D:\Android Studio\jbr"

) else if exist "C:\Program Files\Android\Android Studio\jbr\bin\java.exe" (

  set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"

) else (

  echo [AVISO] Android Studio JBR nao encontrado. Usando Java do PATH.

  goto :skip_java

)

set "PATH=%JAVA_HOME%\bin;%PATH%"

echo Java: %JAVA_HOME%

"%JAVA_HOME%\bin\java.exe" -version

:skip_java



echo.

echo [1/7] Gradle HOME curto (evita erro JNI com pasta "ROTA PRIME")...

if not exist "C:\gradle-rota-prime" mkdir "C:\gradle-rota-prime"

set "GRADLE_USER_HOME=C:\gradle-rota-prime"



echo [2/7] Parando daemons Gradle...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\stop_gradle_daemons.ps1"

if exist "android\gradlew.bat" (

  pushd android

  call gradlew.bat --stop 2>nul

  popd

)

timeout /t 2 /nobreak >nul



echo [3/7] Apagando cache nativo JNI (Could not extract native JNI library)...

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\fix_gradle_jni.ps1"



echo [4/7] Apagando cache transforms (relinker)...

if exist "%USERPROFILE%\.gradle\caches\9.1.0\transforms" (

  rmdir /s /q "%USERPROFILE%\.gradle\caches\9.1.0\transforms"

)

if exist "%USERPROFILE%\.gradle\caches\8.9\transforms" (

  rmdir /s /q "%USERPROFILE%\.gradle\caches\8.9\transforms"

)



echo [5/7] Limpando projeto...

if exist "android\.gradle" rmdir /s /q "android\.gradle"

if exist "build" rmdir /s /q "build"

call flutter clean



echo [6/7] Dependencias...

call flutter pub get

if errorlevel 1 goto :falha



echo Isar (build_runner)...

call dart run build_runner build --delete-conflicting-outputs

if errorlevel 1 goto :falha



echo [7/7] Compilando APK (pode demorar 5-15 min na primeira vez)...

call flutter build apk --release

if errorlevel 1 goto :falha



set "OUT=build\app\outputs\flutter-apk"

if not exist "%OUT%\app-release.apk" goto :falha

if exist "%OUT%\ROTA_PRIME.apk" del /F /Q "%OUT%\ROTA_PRIME.apk"
move /Y "%OUT%\app-release.apk" "%OUT%\ROTA_PRIME.apk" >nul

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\verify_apk.ps1" -ApkPath "%CD%\%OUT%\ROTA_PRIME.apk"



echo.

echo PRONTO. APK oficial: %CD%\%OUT%\ROTA_PRIME.apk

explorer /select,"%CD%\%OUT%\ROTA_PRIME.apk"

pause

exit /b 0



:falha

echo.

echo [ERRO] Ainda falhou. Copie TODA a mensagem vermelha "FAILURE: Build failed"

echo        e envie para suporte. Procure linhas com FAILURE e "What went wrong".

pause

exit /b 1

