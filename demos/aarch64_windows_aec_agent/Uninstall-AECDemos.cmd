@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall-AECDemos.ps1" %*
set "AEC_EXIT_CODE=%ERRORLEVEL%"
if not "%AEC_EXIT_CODE%"=="0" (
  echo.
  echo AEC demo uninstall failed with exit code %AEC_EXIT_CODE%.
  pause
)
exit /b %AEC_EXIT_CODE%
