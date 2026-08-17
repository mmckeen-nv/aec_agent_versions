@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-InferenceEndpoint.ps1" %*
set "AEC_EXIT_CODE=%ERRORLEVEL%"
if not "%AEC_EXIT_CODE%"=="0" pause
exit /b %AEC_EXIT_CODE%
