# Shared by deployment, configuration, launch, and verification (PowerShell 5.1+).
$script:AECInferenceHelper = Join-Path $PSScriptRoot 'configure.py'
function Invoke-AECInference {
  param([hashtable]$Payload, [string]$HermesRoot = (Join-Path $env:LOCALAPPDATA 'hermes'))
  $python = Join-Path $HermesRoot 'hermes-agent\venv\Scripts\python.exe'
  if (-not (Test-Path -LiteralPath $python)) { throw 'Hermes managed Python is missing. Complete Hermes installation first.' }
  # PowerShell 5.1 otherwise encodes stdin as ASCII, corrupting non-ASCII paths and keys.
  $previousEncoding = $OutputEncoding
  try {
    $OutputEncoding = New-Object Text.UTF8Encoding($false)
    $result = ($Payload | ConvertTo-Json -Depth 20 -Compress) | & $python $script:AECInferenceHelper
    if ($LASTEXITCODE -ne 0 -or -not $result) { throw 'Inference operation failed. Check the profile and inference settings.' }
    return ($result | ConvertFrom-Json)
  } finally { $OutputEncoding = $previousEncoding }
}
function Get-AECInference {
  param([string]$Profile, [string]$HermesRoot = (Join-Path $env:LOCALAPPDATA 'hermes'))
  Invoke-AECInference -HermesRoot $HermesRoot -Payload @{ action = 'read'; root = (Join-Path $HermesRoot "profiles\$Profile") }
}
function Assert-AECInference {
  param([string]$Profile, [string]$HermesCli)
  $settings = Get-AECInference -Profile $Profile
  if (-not $settings.has_key) { throw "API key is missing for '$Profile'. Run Change_API_Key.cmd." }
  $status = (& $HermesCli --profile $Profile status 2>&1) -join "`n"
  if ($LASTEXITCODE -ne 0 -or
      $status -notmatch ('(?m)^\s*Provider:\s+' + [regex]::Escape($settings.provider) + '\s*$') -or
      $status -notmatch ('(?m)^\s*Model:\s+' + [regex]::Escape($settings.model) + '\s*$')) {
    throw "Hermes could not resolve the configured provider and model for '$Profile'. Run Configure-Inference.cmd."
  }
  return $settings
}
