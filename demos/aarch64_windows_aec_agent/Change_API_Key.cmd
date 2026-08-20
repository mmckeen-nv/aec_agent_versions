@echo off
setlocal

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Change_API_Key.ps1"
set "AEC_EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%AEC_EXIT_CODE%"=="0" echo API key update failed. Review the error above.
pause
exit /b %AEC_EXIT_CODE%
