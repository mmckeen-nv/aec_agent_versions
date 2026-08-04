[CmdletBinding()]
param([switch]$SkipApplications)

$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'Windows is required.' }
$arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
Write-Host "WINDOWS_PLATFORM_PASS architecture=$arch"

if (-not $SkipApplications) {
  if (-not (Test-Path -LiteralPath 'C:\Program Files\Rhino 8\System\Rhino.exe')) {
    throw 'Install and license Rhino 8, then rerun this check.'
  }
  $blender = Get-ChildItem -LiteralPath 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $blender) { throw 'Install the native Windows Blender build, then rerun this check.' }
}

$hermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
if (-not (Test-Path -LiteralPath $hermes)) {
  Write-Host 'Hermes is not installed. Install Hermes Desktop normally and complete OOBE.'
} else {
  Write-Host "HERMES_BINARY_PASS path=$hermes"
}

Write-Host 'OOBE_REQUIRED no provider, model, endpoint, key, profile, project, or MCP was configured.'
