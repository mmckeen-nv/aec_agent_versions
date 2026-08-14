[CmdletBinding()]
param(
  [string]$RunId = "quick-$(Get-Date -Format 'yyyyMMdd_HHmmss')",
  [switch]$PassThru
)

$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$master = Join-Path $packageRoot 'demo\cliff-house\cliff_house_GOLDEN_MASTER.3dm'
$expected = 'D7DB42D78B360C66D94E1E034C201EDD98EFF8F63F35B19C7995E7D1B63F4F7C'
$runRoot = Join-Path $packageRoot "work\$RunId"
$working = Join-Path $runRoot 'rhino\cliff_house_quick_working.3dm'

if (-not (Test-Path -LiteralPath $master)) { throw "Missing protected Rhino master: $master" }
if ((Get-FileHash -LiteralPath $master -Algorithm SHA256).Hash -ne $expected) { throw 'Protected Rhino master hash mismatch.' }
if (Test-Path -LiteralPath $runRoot) { throw "Run directory already exists: $runRoot" }

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $working) | Out-Null
Copy-Item -LiteralPath $master -Destination $working
Write-Host "QUICK_WORKING_COPY_PASS source_sha256=$expected path=$working"
if ($PassThru) { Write-Output $working }
