[CmdletBinding()]
param(
  [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot),
  [int]$TimeoutSeconds = 150
)

$ErrorActionPreference = 'Stop'
$rhino = 'C:\Program Files\Rhino 8\System\Rhino.exe'
$source = Join-Path $RepositoryRoot 'demo\cliff-house\cliff_house_GOLDEN_MASTER.3dm'
$target = Join-Path $RepositoryRoot 'demo\cliff-house\cliff_house_FREECAD_SOURCE.step'
$script = Join-Path $RepositoryRoot 'scripts\export_rhino_to_step.py'
$receipt = Join-Path ([IO.Path]::GetTempPath()) 'local-aec-rhino-step.receipt'

if (Test-Path -LiteralPath $target) { throw "Target already exists: $target" }
if (Test-Path -LiteralPath $receipt) { Remove-Item -LiteralPath $receipt -Force }

$env:LOCAL_AEC_STEP_TARGET = $target
$env:LOCAL_AEC_STEP_RECEIPT = $receipt
$app = New-Object -ComObject Rhino.Application
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
  if ($app.IsInitialized() -ne 0) { break }
  Start-Sleep -Milliseconds 500
}
if ($app.IsInitialized() -eq 0) { throw 'Rhino COM instance did not initialize.' }
$app.Visible = $false
$rhinoScript = $app.GetScriptObject()
if ($null -eq $rhinoScript) { throw 'RhinoScript automation object is unavailable.' }
if (-not $app.RunScript(('_-Open "{0}" _Enter' -f $source), 0)) {
  throw "Rhino could not open $source"
}

$macro = '_-ScriptEditor _Run "{0}"' -f $script
$app.RunScript($macro, 0) | Out-Null
while ((Get-Date) -lt $deadline) {
  if (Test-Path -LiteralPath $receipt) { break }
  Start-Sleep -Seconds 2
}

if (-not (Test-Path -LiteralPath $receipt)) {
  $app.RunScript('_-Exit _No', 0) | Out-Null
  throw 'Code-driven STEP export failed or timed out.'
}

Get-Content -LiteralPath $receipt
$item = Get-Item -LiteralPath $target
if ($item.Length -lt 10000) { throw "STEP output is undersized: $($item.Length)" }
Get-FileHash -LiteralPath $target -Algorithm SHA256
