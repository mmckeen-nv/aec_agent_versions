[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Profile = 'cliff-house-modifications-windows',
  [ValidateRange(1024, 65535)][int]$RhinoPort = 1999,
  [string]$Provider = 'custom:nvidia-switchyard',
  [string]$Model = 'switchyard/openai/gpt-5.6-sol',
  [string]$BaseUrl = 'https://inference-api.nvidia.com/v1',
  [string]$KeyEnvironmentVariable = 'NVIDIA_API_KEY',
  [ValidateRange(8192, 1050000)][int]$ContextLength = 1000000,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
function Write-Utf8NoBom {
  param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][AllowEmptyString()][string]$Value)
  [IO.File]::WriteAllText($LiteralPath, $Value, (New-Object Text.UTF8Encoding($false)))
}
$packageRoot = Split-Path -Parent $PSScriptRoot
$profileRoot = Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile"
$configPath = Join-Path $profileRoot 'config.yaml'
$templatePath = Join-Path $packageRoot 'config\hermes\config.template.yaml'
$dmlRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml'
$dmlStore = Join-Path $dmlRoot 'stores\cliff-house-modifications-windows-bounded-v2'
$dmlPython = Join-Path $dmlRoot '.venv-dml\Scripts\python.exe'

if ($Provider -notmatch '^custom:([a-zA-Z0-9_-]+)$') { throw 'Provider must use custom:<name> form.' }
$providerName = $Matches[1]
if ($KeyEnvironmentVariable -notmatch '^[A-Z][A-Z0-9_]+$') { throw 'Invalid key environment variable.' }
if ((Test-Path -LiteralPath $configPath) -and -not $Force) {
  throw "Profile config already exists: $configPath. Use -Force only after reviewing it."
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

if ($PSCmdlet.ShouldProcess($profileRoot, 'deploy Cliff House quick-modification profile')) {
  New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
  if (Test-Path -LiteralPath $configPath) {
    Copy-Item -LiteralPath $configPath -Destination "$configPath.$(Get-Date -Format 'yyyyMMdd_HHmmssfff').bak"
  }
  Write-Utf8NoBom -LiteralPath $configPath -Value $config
  Copy-Item -LiteralPath (Join-Path $packageRoot 'AGENTS.md') -Destination (Join-Path $profileRoot 'AGENTS.md') -Force
  $pluginSource = Join-Path $dmlRoot 'source\integrations\hermes\plugins\daystrom_dml'
  if (-not (Test-Path $pluginSource) -or -not (Test-Path $dmlPython)) { throw 'Daystrom DML is not installed. Run Deploy-AECDemos.ps1.' }
  $pluginDestination = Join-Path $profileRoot 'plugins\daystrom_dml'
  New-Item -ItemType Directory -Force -Path $pluginDestination | Out-Null
  Copy-Item -Path (Join-Path $pluginSource '*') -Destination $pluginDestination -Recurse -Force
  & $dmlPython (Join-Path (Split-Path $packageRoot -Parent) 'memory\seed_dml.py') `
    --config (Join-Path $dmlRoot 'config\aec-demo.yaml') --storage $dmlStore `
    --knowledge (Join-Path $packageRoot 'memory') --project-id 'project:cliff-house-modifications-windows'
  if ($LASTEXITCODE) { throw 'Could not seed Cliff House modification memory.' }
  Write-Host "HERMES_PROFILE_DEPLOYED profile=$Profile rhino_port=$RhinoPort"
}
