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
  Write-Host 'BLENDER_MANAGED_BY_DEPLOYMENT version=5.2.0 scope=user'
}

$hermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
if (-not (Test-Path -LiteralPath $hermes)) {
  Write-Host 'Hermes is not installed. Install Hermes Desktop normally and complete OOBE.'
} else {
  Write-Host "HERMES_BINARY_PASS path=$hermes"
}

Write-Host 'OOBE_REQUIRED no provider, model, endpoint, key, profile, project, or MCP was configured.'
