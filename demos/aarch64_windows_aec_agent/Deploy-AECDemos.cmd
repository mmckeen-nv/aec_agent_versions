@echo off
setlocal

rem This is the user-facing launcher. ExecutionPolicy Bypass applies only to this child process.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Deploy-AECDemos.ps1" -NoPauseOnError %*
set "AEC_EXIT_CODE=%ERRORLEVEL%"

if not "%AEC_EXIT_CODE%"=="0" (
  echo.
  echo AEC demo deployment failed with exit code %AEC_EXIT_CODE%.
  echo Review the error above, then run Deploy-AECDemos.cmd again.
  pause
)

exit /b %AEC_EXIT_CODE%
