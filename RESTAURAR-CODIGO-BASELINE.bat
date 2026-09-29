@echo off
setlocal
cd /d "%~dp0"
echo Restaurando codigo para baseline fad3ea8 (APK raiz funcional)...
git checkout fad3ea8e1b687ed4c3a4c0b50b0fe52a86bca4da -- .
if errorlevel 1 (
  echo Falhou. Verifique se o Git esta instalado e se o commit existe.
  pause
  exit /b 1
)
echo.
echo Codigo restaurado. Recompile com COMPILAR.APK.bat se precisar de novo APK.
echo Para desfazer: git stash pop  ou  git checkout main -- .
pause
