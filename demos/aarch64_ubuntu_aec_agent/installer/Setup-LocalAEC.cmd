@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-LocalAEC.ps1" %*
exit /b %ERRORLEVEL%
