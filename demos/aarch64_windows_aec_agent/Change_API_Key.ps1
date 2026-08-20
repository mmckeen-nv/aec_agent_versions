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

function Write-Utf8NoBomAtomic([string]$Path, [string[]]$Lines) {
  $parent = Split-Path -Parent $Path
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
  $swapBackup = "$Path.$([guid]::NewGuid().ToString('N')).swap"
  try {
    $text = if ($Lines.Count) { ($Lines -join [Environment]::NewLine) + [Environment]::NewLine } else { '' }
    [IO.File]::WriteAllText($temporary, $text, (New-Object Text.UTF8Encoding($false)))
    if (Test-Path -LiteralPath $Path) {
      [IO.File]::Replace($temporary, $Path, $swapBackup)
    } else {
      Move-Item -LiteralPath $temporary -Destination $Path
    }
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    if (Test-Path -LiteralPath $swapBackup) { Remove-Item -LiteralPath $swapBackup -Force }
  }
}

$profiles = @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')
$profileRoot = Join-Path $HermesRoot 'profiles'
$missing = @($profiles | Where-Object { -not (Test-Path -LiteralPath (Join-Path $profileRoot $_) -PathType Container) })
if ($missing.Count) {
  throw "The Cliff House demo profiles are not installed: $($missing -join ', '). Run Deploy-AECDemos.cmd first."
}

if ($Action -eq 'Ask') {
  Write-Host 'NVIDIA API key management for both Cliff House demo profiles'
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
  $secure = Read-Host 'New NVIDIA API key (input is hidden)' -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { $keyValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  if ([string]::IsNullOrWhiteSpace($keyValue) -or $keyValue.Length -lt 8 -or $keyValue.Length -gt 1000 -or $keyValue -match '[\r\n]') {
    $keyValue = $null
    throw 'The API key was empty or invalid. No profile was changed.'
  }
}

foreach ($profile in $profiles) {
  $envPath = Join-Path $profileRoot "$profile\.env"
  $lines = if (Test-Path -LiteralPath $envPath) {
    @(Get-Content -LiteralPath $envPath | Where-Object { $_ -notmatch '^\s*NVIDIA_API_KEY=' })
  } else { @() }
  if ($Action -eq 'Set') { $lines += "NVIDIA_API_KEY=$keyValue" }
  if ($lines.Count) { Write-Utf8NoBomAtomic -Path $envPath -Lines $lines }
  elseif (Test-Path -LiteralPath $envPath) { Remove-Item -LiteralPath $envPath -Force }
  Write-Host "AEC_API_KEY_PROFILE_UPDATED profile=$profile action=$($Action.ToLowerInvariant())"
}

$keyValue = $null
if ($Action -eq 'Set') { Write-Host 'AEC_API_KEY_SET profiles=2' -ForegroundColor Green }
else { Write-Host 'AEC_API_KEY_ERASED profiles=2' -ForegroundColor Green }
Write-Host 'Close and restart Hermes before running either demo shortcut.' -ForegroundColor Yellow
