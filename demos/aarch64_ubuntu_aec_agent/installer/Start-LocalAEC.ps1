[CmdletBinding()]
param(
  [string]$Profile = 'local-aec-cloud'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$hermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
if (-not (Test-Path -LiteralPath $hermes -PathType Leaf)) {
  throw "Hermes was not found at $hermes. Run Install-LocalAEC.ps1 first."
}

& $hermes --profile $Profile desktop --cwd $repoRoot
