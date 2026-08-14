[CmdletBinding()]
param(
  [string]$Profile = 'cliff-house-full-build-windows',
  [ValidateRange(1024, 65535)][int]$RhinoPort = 10500,
  [switch]$SkipApplications
)
$ErrorActionPreference = 'Stop'
$hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
$bundledHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$hermes = if ($hermesCommand) { $hermesCommand.Source } elseif (Test-Path $bundledHermes) { $bundledHermes } else { $null }
$sourceModel = Join-Path (Split-Path -Parent $PSScriptRoot) 'projects\cliff_house_02\rhino_assets\base_model.3dm'
$checks = [ordered]@{
  'Hermes binary' = [bool]$hermes
  'Hermes profile' = (Test-Path (Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile\config.yaml"))
  'Source-curve model' = (Test-Path $sourceModel)
  'Rhino MCP listener' = [bool](Get-NetTCPConnection -LocalPort $RhinoPort -State Listen -ErrorAction SilentlyContinue)
}
if (-not $SkipApplications) {
  $checks['Rhino 8'] = Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe'
  $checks['Blender'] = [bool](Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)
}
$checks.GetEnumerator() | ForEach-Object { Write-Host ("{0} {1}" -f ($(if($_.Value){'PASS'}else{'FAIL'}), $_.Key)) }
if ($checks.Values -contains $false) { exit 1 }
& $hermes -p $Profile mcp test rhino
if ($LASTEXITCODE -ne 0) { throw 'Hermes could not discover Rhino MCP tools.' }
Write-Host "WINDOWS_AEC_SMOKE_PASS profile=$Profile rhino_port=$RhinoPort"
