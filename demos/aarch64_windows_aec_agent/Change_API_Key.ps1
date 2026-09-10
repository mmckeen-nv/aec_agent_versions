[CmdletBinding()]
param(
  [ValidateSet('Ask', 'Set', 'Erase')][string]$Action = 'Ask',
  [string]$HermesRoot = (Join-Path $env:LOCALAPPDATA 'hermes')
)

$ErrorActionPreference = 'Stop'

trap {
  Write-Host ''
  Write-Host 'AEC_API_KEY_CHANGE_FAILED' -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  exit 1
}

. (Join-Path $PSScriptRoot 'inference\Inference.ps1')

$profiles = @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')
$profileRoot = Join-Path $HermesRoot 'profiles'
$missing = @($profiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $profileRoot $_) -PathType Container) })
if ($missing.Count) {
  throw "The Cliff House demo profiles are not installed: $($missing -join ', '). Run Deploy-AECDemos.cmd first."
}

if ($Action -eq 'Ask') {
  Write-Host 'Inference API key management for both Cliff House demo profiles'
  Write-Host '  S = set or replace the key'
  Write-Host '  E = erase the saved key'
  Write-Host '  C = cancel'
  $choice = (Read-Host 'Choose S, E, or C').Trim()
  if ($choice -match '^(?i:s|set)$') { $Action = 'Set' }
  elseif ($choice -match '^(?i:e|erase)$') { $Action = 'Erase' }
  elseif ($choice -match '^(?i:c|cancel)$') { Write-Host 'AEC_API_KEY_CHANGE_CANCELLED'; exit 0 }
  else { throw 'Invalid choice. Enter S, E, or C.' }
}

$keyValue = $null
if ($Action -eq 'Set') {
  $secure = Read-Host 'New Inference API key (input is hidden)' -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { $keyValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  if ([string]::IsNullOrWhiteSpace($keyValue) -or $keyValue -match '[\r\n]') {
    $keyValue = $null
    throw 'The API key was empty or invalid. No profile was changed.'
  }
}

# Validate both configurations before writing either credential.
foreach ($profile in $profiles) { Get-AECInference -Profile $profile -HermesRoot $HermesRoot | Out-Null }
foreach ($profile in $profiles) {
  Invoke-AECInference -HermesRoot $HermesRoot -Payload @{ action = 'key'; root = (Join-Path $profileRoot $profile); key = $keyValue } | Out-Null
  Write-Host "AEC_API_KEY_PROFILE_UPDATED profile=$profile action=$($Action.ToLowerInvariant())"
}

$keyValue = $null
if ($Action -eq 'Set') { Write-Host 'AEC_API_KEY_SET profiles=2' -ForegroundColor Green }
else { Write-Host 'AEC_API_KEY_ERASED profiles=2' -ForegroundColor Green }
Write-Host 'Close and restart Hermes before running either demo shortcut.' -ForegroundColor Yellow
