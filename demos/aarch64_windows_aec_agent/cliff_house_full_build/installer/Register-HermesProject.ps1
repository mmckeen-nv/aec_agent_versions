[CmdletBinding()]
param([Parameter(Mandatory)][string]$Profile)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = Split-Path -Parent $PSScriptRoot
$hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
$bundledHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$hermes = if ($hermesCommand) { $hermesCommand.Source } elseif (Test-Path $bundledHermes) { $bundledHermes } else { $null }
if (-not $hermes) { throw 'Hermes is not installed or available on PATH.' }
$profileConfig = Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile\config.yaml"
if (-not (Test-Path -LiteralPath $profileConfig)) { throw "Profile '$Profile' has not completed Hermes OOBE." }

$slug = 'cliff-house-full-build-windows'
& $hermes --profile $Profile project show $slug *> $null
if ($LASTEXITCODE -ne 0) {
  & $hermes --profile $Profile project create 'Cliff House Full Build Windows' $root --slug $slug --primary $root --description 'Phase-driven Rhino to Blender to ComfyUI Cliff House build.' --icon building --color '#76b900'
  if ($LASTEXITCODE -ne 0) { throw 'Hermes project creation failed.' }
}
& $hermes --profile $Profile project show $slug
if ($LASTEXITCODE -ne 0) { throw 'Hermes project validation failed.' }
Write-Host "HERMES_PROJECT_PASS profile=$Profile project=$slug"
