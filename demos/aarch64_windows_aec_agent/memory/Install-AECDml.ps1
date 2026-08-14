[CmdletBinding()]
param([switch]$Force)

$ErrorActionPreference = 'Stop'
$integration = Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml'
$source = Join-Path $integration 'source'
$venv = Join-Path $integration '.venv-dml'
$python = Join-Path $venv 'Scripts\python.exe'
$revision = '98c0d116d706f3f1db4e60076400518d56ab6b9c'

if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw 'Git is required to install Daystrom DML.' }
if (-not (Test-Path (Join-Path $source 'pyproject.toml'))) {
  New-Item -ItemType Directory -Force -Path $integration | Out-Null
  & git.exe clone https://github.com/mmckeen-nv/DML.git $source
  if ($LASTEXITCODE) { throw 'Could not clone Daystrom DML.' }
}
& git.exe -C $source fetch --quiet origin $revision
if ($LASTEXITCODE) { throw 'Could not fetch the pinned Daystrom DML revision.' }
$currentRevision = (& git.exe -C $source rev-parse HEAD).Trim()
if ($currentRevision -ne $revision -and -not $Force) {
  throw "Daystrom DML is at $currentRevision; rerun Deploy-AECDemos.ps1 -Force to select the tested revision."
}
if ($currentRevision -ne $revision) {
  & git.exe -C $source checkout --quiet $revision
  if ($LASTEXITCODE) { throw 'Could not select the pinned Daystrom DML revision.' }
}
if (-not (Test-Path $python)) {
  $hermesPython = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\python.exe'
  $launcherPath = if (Test-Path $hermesPython) { $hermesPython } else {
    $command = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($command) { $command.Source } else {
      $command = Get-Command py.exe -ErrorAction SilentlyContinue
      if ($command) { $command.Source } else { $null }
    }
  }
  if (-not $launcherPath) { throw 'Python 3.10+ is required to install Daystrom DML.' }
  & $launcherPath -m venv $venv
}
$priorCudaBuild = $env:DML_BUILD_CUDA
$env:DML_BUILD_CUDA = '0'
try {
  & $python -m pip install --disable-pip-version-check --quiet --upgrade pip
  & $python -m pip install --disable-pip-version-check --quiet -e "$source[mcp]"
  # DML's FastMCP import uses the MCP 1.x package layout. MCP 2.x removed
  # mcp.server.fastmcp while still satisfying DML's unbounded dependency.
  & $python -m pip install --disable-pip-version-check --quiet 'mcp==1.29.0'
} finally {
  if ($null -eq $priorCudaBuild) { Remove-Item Env:DML_BUILD_CUDA -ErrorAction SilentlyContinue }
  else { $env:DML_BUILD_CUDA = $priorCudaBuild }
}
if ($LASTEXITCODE) { throw 'Daystrom DML Python installation failed.' }
& $python -c 'from mcp.server.fastmcp import FastMCP'
if ($LASTEXITCODE) { throw 'Daystrom DML MCP compatibility check failed.' }

$configDir = Join-Path $integration 'config'
$binDir = Join-Path $integration 'bin'
New-Item -ItemType Directory -Force -Path $configDir, $binDir, (Join-Path $integration 'stores') | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'dml.yaml') -Destination (Join-Path $configDir 'aec-demo.yaml') -Force

$launcherText = @"
@echo off
"$python" "$source\openclaw-wrapper\scripts\dml_memory.py" %*
"@
Set-Content -LiteralPath (Join-Path $binDir 'hermes-dml-memory.cmd') -Value $launcherText -Encoding ascii
Write-Host "DML_INSTALLED revision=$revision root=$integration"
