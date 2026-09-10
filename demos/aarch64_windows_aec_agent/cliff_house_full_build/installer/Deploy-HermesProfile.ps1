[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Profile = 'cliff-house-full-build-windows',
  [ValidateRange(1024, 65535)][int]$RhinoPort = 1999,
  [string]$Provider = 'custom:nvidia-switchyard',
  [string]$Model = 'switchyard/openai/gpt-5.6-sol',
  [string]$BaseUrl = 'https://inference-api.nvidia.com/v1',
  [string]$KeyEnvironmentVariable = 'NVIDIA_API_KEY',
  [ValidateSet('chat_completions', 'codex_responses')][string]$ApiMode = 'codex_responses',
  [switch]$PreserveInference,
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

$platformRoot = Split-Path -Parent $packageRoot
. (Join-Path $platformRoot 'inference\Inference.ps1')
$settings = @{ provider = $Provider; model = $Model; base_url = $BaseUrl; key_env = $KeyEnvironmentVariable; api_mode = $ApiMode; context_length = $ContextLength }
if ($PreserveInference -and (Test-Path -LiteralPath $configPath)) {
  $existing = Get-AECInference -Profile $Profile
  foreach ($key in @($settings.Keys)) { $settings[$key] = $existing.$key }
}
$rendered = Invoke-AECInference -Payload @{
  action = 'render'; root = $profileRoot; template = $templatePath; settings = $settings
  replacements = @{ '__RHINO_PORT__' = [string]$RhinoPort; '__DML_ROOT__' = $dmlRoot.Replace('\', '/'); '__DML_STORE__' = $dmlStore.Replace('\', '/') }
}
$config = $rendered.text

if ($PSCmdlet.ShouldProcess($profileRoot, 'deploy Cliff House Hermes profile')) {
  New-Item -ItemType Directory -Force -Path $profileRoot | Out-Null
  if (Test-Path -LiteralPath $configPath) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmssfff'
    Copy-Item -LiteralPath $configPath -Destination "$configPath.$stamp.bak"
  }
  Write-Utf8NoBom -LiteralPath $configPath -Value $config

  foreach ($name in @('AGENTS.md', 'hermes', 'projects', 'skills', 'system_prompts')) {
    $source = Join-Path $packageRoot $name
    $destination = Join-Path $profileRoot $name
    if (Test-Path -LiteralPath $source -PathType Container) {
      New-Item -ItemType Directory -Force -Path $destination | Out-Null
      Copy-Item -Path (Join-Path $source '*') -Destination $destination -Recurse -Force
    } else { Copy-Item -LiteralPath $source -Destination $destination -Force }
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
  Write-Host "Set $($settings.key_env) through Hermes secrets or the profile environment; no credential was written."
}
