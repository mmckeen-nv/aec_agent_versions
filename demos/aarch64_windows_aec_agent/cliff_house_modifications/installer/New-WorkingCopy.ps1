[CmdletBinding()]
param(
  [string]$RunId = "quick-$(Get-Date -Format 'yyyyMMdd_HHmmss')",
  [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$master = Join-Path $packageRoot 'demo\cliff-house\cliff_house_GOLDEN_MASTER.3dm'
$expected = 'B45D8F7A7262DBEC4F077007A17701A29281C00F0B17394A20745ED981C1BB05'
$runRoot = Join-Path $packageRoot "work\$RunId"
$working = Join-Path $runRoot 'rhino\cliff_house_quick_working.3dm'

if (-not (Test-Path -LiteralPath $master)) { throw "Missing protected Rhino master: $master" }
if ((Get-FileHash -LiteralPath $master -Algorithm SHA256).Hash -ne $expected) { throw 'Protected Rhino master hash mismatch.' }
if (Test-Path -LiteralPath $runRoot) { throw "Run directory already exists: $runRoot" }

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $working) | Out-Null
Copy-Item -LiteralPath $master -Destination $working
Write-Host "QUICK_WORKING_COPY_PASS source_sha256=$expected path=$working"
if ($PassThru) { Write-Output $working }
