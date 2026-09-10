[CmdletBinding()]
param(
  [string]$BaseUrl,
  [string]$Model,
  [ValidateSet('chat_completions', 'codex_responses')][string]$ApiMode = 'chat_completions',
  [ValidateRange(8192, 1050000)][int]$ContextLength = 32768,
  [string]$KeyEnvironmentVariable = 'AEC_INFERENCE_API_KEY',
  [Security.SecureString]$ApiKey,
  [string]$HermesRoot = (Join-Path $env:LOCALAPPDATA 'hermes')
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'inference\Inference.ps1')
$profiles = @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')
# Read both profiles before changing either one.
foreach ($profile in $profiles) { Get-AECInference -Profile $profile -HermesRoot $HermesRoot | Out-Null }
if (-not $BaseUrl) { $BaseUrl = Read-Host 'API base URL (for example http://localhost:8000/v1)' }
if (-not $Model) { $Model = Read-Host 'Served model ID' }
$settings = @{ provider = 'custom:aec-inference'; model = $Model; base_url = $BaseUrl; key_env = $KeyEnvironmentVariable; api_mode = $ApiMode; context_length = $ContextLength }
Invoke-AECInference -HermesRoot $HermesRoot -Payload @{ action = 'validate'; settings = $settings } | Out-Null
if (-not $ApiKey) { $ApiKey = Read-Host 'API key (input is hidden; use a placeholder for a server without authentication)' -AsSecureString }
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApiKey)
try {
  $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  foreach ($profile in $profiles) {
    Invoke-AECInference -HermesRoot $HermesRoot -Payload @{ action = 'configure'; root = (Join-Path $HermesRoot "profiles\$profile"); settings = $settings; key = $key } | Out-Null
    Write-Host "AEC_INFERENCE_CONFIGURED profile=$profile model=$Model mode=$ApiMode"
  }
} finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  $key = $null
  $ApiKey = $null
}
Write-Host 'Restart Hermes, then run Test-InferenceEndpoint.cmd.'
