[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$runtimeVersion = (Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'hermes-aec-runtime.version')).Trim()
$desktop = [Environment]::GetFolderPath('Desktop')
$hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
$bundledHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$hermes = if ($hermesCommand) { $hermesCommand.Source } elseif (Test-Path $bundledHermes) { $bundledHermes } else { $null }

$checks = [ordered]@{
  'Rhino 8' = Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe'
  'Hermes' = [bool]$hermes
  'Hermes Desktop UI' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\apps\desktop\release\win-arm64-unpacked\Hermes.exe')
  'Full-build profile' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\profiles\cliff-house-full-build-windows\config.yaml')
  'Modification profile' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\profiles\cliff-house-modifications-windows\config.yaml')
  'Daystrom DML runtime' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml\.venv-dml\Scripts\python.exe')
  "Hermes AEC runtime $runtimeVersion" = Test-Path (Join-Path $env:LOCALAPPDATA "hermes\integrations\hermes-aec-runtime\$runtimeVersion\.venv\Scripts\hermes-aec-mcp.exe")
  'Full-build memory seed' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml\stores\cliff-house-full-build-windows\.aec-seed.json')
  'Modification memory seed' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml\stores\cliff-house-modifications-windows-bounded-v2\.aec-seed.json')
  'AEC Full Build shortcut' = Test-Path (Join-Path $desktop 'AEC Full Build.lnk')
  'AEC House Modification shortcut' = Test-Path (Join-Path $desktop 'AEC House Modification.lnk')
  'Full-build source model' = Test-Path (Join-Path $PSScriptRoot 'cliff_house_full_build\projects\cliff_house_02\rhino_assets\base_model.3dm')
  'Quick-demo master' = Test-Path (Join-Path $PSScriptRoot 'cliff_house_modifications\demo\cliff-house\cliff_house_HERO_RHINO_MODEL.3dm')
}

foreach ($item in $checks.GetEnumerator()) {
  Write-Host ("{0,-5} {1}" -f $(if ($item.Value) { 'PASS' } else { 'FAIL' }), $item.Key)
  if (-not $item.Value) { $failures.Add($item.Key) }
}

if ($hermes) {
  foreach ($profile in @('cliff-house-full-build-windows')) {
    & $hermes -p $profile mcp test daystrom_dml *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "PASS  Daystrom DML via $profile" }
    else { Write-Host "FAIL  Daystrom DML via $profile"; $failures.Add("Daystrom DML via $profile") }
  }
  foreach ($profile in @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')) {
    & $hermes -p $profile mcp test hermes_aec *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "PASS  Hermes AEC runtime via $profile" }
    else { Write-Host "FAIL  Hermes AEC runtime via $profile"; $failures.Add("Hermes AEC runtime via $profile") }
  }
}

$statePath = Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\deployment.json'
if (Test-Path $statePath) {
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  $listener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.rhino_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  $owner = if ($listener) { Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue } else { $null }
  if ($owner -and $owner.ProcessName -eq 'Rhino') {
    Write-Host "PASS  RhinoMCP direct listener on port $($state.rhino_port), Rhino PID $($owner.Id)"
  } else {
    Write-Host "WARN  RhinoMCP is not owned by Rhino on loopback port $($state.rhino_port). Run AECMCPStart in Rhino before a demo."
  }
} else {
  Write-Host 'FAIL  Deployment state is missing.'
  $failures.Add('Deployment state')
}

if ($failures.Count) { Write-Host "AEC_DEPLOYMENT_FAIL count=$($failures.Count)"; exit 1 }
Write-Host 'AEC_DEPLOYMENT_PASS'
