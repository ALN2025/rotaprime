@echo off



chcp 65001 >nul



title ROTA PRIME — parar tudo



cd /d "%~dp0"



echo.



call "%~dp0PARAR-GRADLE.bat" silent



echo.



echo  Concluido. Gradle daemon encerrado.



pause



