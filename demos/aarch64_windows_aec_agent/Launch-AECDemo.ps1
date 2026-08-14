[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('FullBuild', 'Modification')][string]$Demo)

$ErrorActionPreference = 'Stop'
$state = Get-Content -Raw -LiteralPath (Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\deployment.json') | ConvertFrom-Json
$desktopHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\apps\desktop\release\win-arm64-unpacked\Hermes.exe'
if (-not (Test-Path $desktopHermes)) { throw 'Hermes Desktop is not installed.' }

$rhino = 'C:\Program Files\Rhino 8\System\Rhino.exe'
if (-not (Test-Path $rhino)) { throw 'Rhino 8 is not installed.' }

function Test-RhinoMCPReady {
  $listener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.rhino_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $listener) { return $false }
  $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
  return [bool]($owner -and $owner.ProcessName -eq 'Rhino')
}

if ($Demo -eq 'FullBuild') {
  $profile = 'cliff-house-full-build-windows'
  $workspace = Join-Path $PSScriptRoot 'cliff_house_full_build'
  if (-not (Get-Process Rhino -ErrorAction SilentlyContinue)) { Start-Process -FilePath $rhino }
} else {
  $profile = 'cliff-house-modifications-windows'
  $workspace = Join-Path $PSScriptRoot 'cliff_house_modifications'
  $working = & (Join-Path $workspace 'installer\New-WorkingCopy.ps1') -PassThru
  Start-Process -FilePath $rhino -ArgumentList "`"$working`""

  # Opening a document can restart Rhino MCP. Do not expose Hermes to an
  # empty/stale document or a listener that is still cycling.
  $deadline = (Get-Date).AddSeconds(90)
  $stableChecks = 0
  do {
    Start-Sleep -Seconds 1
    $listening = Test-RhinoMCPReady
    if ($listening) { $stableChecks++ } else { $stableChecks = 0 }
  } while ($stableChecks -lt 3 -and (Get-Date) -lt $deadline)
  if ($stableChecks -lt 3) {
    throw "Rhino opened the working copy, but MCP did not become stable on port $($state.rhino_port) within 90 seconds."
  }
}

if (-not (Test-RhinoMCPReady)) {
  $deadline = (Get-Date).AddSeconds(90)
  do { Start-Sleep -Seconds 1 } while (-not (Test-RhinoMCPReady) -and (Get-Date) -lt $deadline)
  if (-not (Test-RhinoMCPReady)) {
    throw "AEC RhinoMCP is not ready on loopback port $($state.rhino_port). In Rhino run AECMCPStart, then click the shortcut again."
  }
}

Start-Process -FilePath $desktopHermes -ArgumentList @('--profile', $profile) -WorkingDirectory $workspace
