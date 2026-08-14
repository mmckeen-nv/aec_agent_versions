[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Profile = 'cliff-house-full-build-windows',
  [ValidateRange(1024, 65535)][int]$RhinoPort = 10500,
  [string]$Provider = 'custom:nvidia-switchyard',
  [string]$Model = 'switchyard/openai/gpt-5.6-sol',
  [string]$BaseUrl = 'https://inference-api.nvidia.com/v1',
  [string]$KeyEnvironmentVariable = 'NVIDIA_API_KEY',
  [ValidateRange(8192, 1050000)][int]$ContextLength = 1000000,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$profileRoot = Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile"
$configPath = Join-Path $profileRoot 'config.yaml'
$templatePath = Join-Path $packageRoot 'config\hermes\config.template.yaml'
$dmlRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml'
$dmlStore = Join-Path $dmlRoot 'stores\cliff-house-full-build-windows'
$dmlPython = Join-Path $dmlRoot '.venv-dml\Scripts\python.exe'

if ($Provider -notmatch '^custom:([a-zA-Z0-9_-]+)$') {
  throw "Provider must use Hermes' custom:<name> form. Received: $Provider"
}
$providerName = $Matches[1]
if ($KeyEnvironmentVariable -notmatch '^[A-Z][A-Z0-9_]+$') {
  throw 'KeyEnvironmentVariable must be an uppercase environment variable name.'
}

if ((Test-Path -LiteralPath $configPath) -and -not $Force) {
  throw "Profile config already exists: $configPath. Rerun with -Force only after backing it up."
}

$config = Get-Content -Raw -LiteralPath $templatePath
$config = $config.Replace('__RHINO_PORT__', [string]$RhinoPort)
$config = $config.Replace('nvidia-switchyard', $providerName)
$config = $config.Replace('switchyard/openai/gpt-5.6-sol', $Model)
$config = $config.Replace('https://inference-api.nvidia.com/v1', $BaseUrl.TrimEnd('/'))
$config = $config.Replace('NVIDIA_API_KEY', $KeyEnvironmentVariable)
$config = $config.Replace('context_length: 1000000', "context_length: $ContextLength")
$config = $config.Replace('__DML_ROOT__', $dmlRoot.Replace('\', '/'))
$config = $config.Replace('__DML_STORE__', $dmlStore.Replace('\', '/'))

if ($PSCmdlet.ShouldProcess($profileRoot, 'deploy Cliff House Hermes profile')) {
  New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
  if (Test-Path -LiteralPath $configPath) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    Copy-Item -LiteralPath $configPath -Destination "$configPath.$stamp.bak"
  }
  Set-Content -LiteralPath $configPath -Value $config -Encoding utf8NoBOM

  foreach ($name in @('AGENTS.md', 'hermes', 'projects', 'skills', 'system_prompts')) {
    $source = Join-Path $packageRoot $name
    $destination = Join-Path $profileRoot $name
    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
  }
  $pluginSource = Join-Path $dmlRoot 'source\integrations\hermes\plugins\daystrom_dml'
  if (-not (Test-Path $pluginSource) -or -not (Test-Path $dmlPython)) { throw 'Daystrom DML is not installed. Run Deploy-AECDemos.ps1.' }
  $pluginDestination = Join-Path $profileRoot 'plugins\daystrom_dml'
  New-Item -ItemType Directory -Force -Path $pluginDestination | Out-Null
  Copy-Item -Path (Join-Path $pluginSource '*') -Destination $pluginDestination -Recurse -Force
  & $dmlPython (Join-Path (Split-Path $packageRoot -Parent) 'memory\seed_dml.py') `
    --config (Join-Path $dmlRoot 'config\aec-demo.yaml') --storage $dmlStore `
    --knowledge (Join-Path $packageRoot 'memory') --project-id 'project:cliff-house-full-build-windows'
  if ($LASTEXITCODE) { throw 'Could not seed Cliff House full-build memory.' }
  Write-Host "HERMES_PROFILE_DEPLOYED profile=$Profile rhino_port=$RhinoPort"
  Write-Host "Set $KeyEnvironmentVariable through Hermes secrets or the profile environment; no credential was written."
}
