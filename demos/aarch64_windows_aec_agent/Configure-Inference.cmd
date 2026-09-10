@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Configure-Inference.ps1" %*
set "AEC_EXIT_CODE=%ERRORLEVEL%"
pause
exit /b %AEC_EXIT_CODE%
