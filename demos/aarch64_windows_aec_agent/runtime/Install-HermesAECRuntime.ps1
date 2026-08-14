[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidatePattern('^v\d+\.\d+\.\d+$')][string]$Version,
  [int]$RhinoPort = 1999,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$integrationRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\hermes-aec-runtime'
$target = Join-Path $integrationRoot $Version
$resolvedRoot = [IO.Path]::GetFullPath($integrationRoot)
$resolvedTarget = [IO.Path]::GetFullPath($target)
if (-not $resolvedTarget.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'Refusing to install outside the Hermes AEC integration directory.'
}

$backupTarget = $null
if ($Force -and (Test-Path -LiteralPath $resolvedTarget)) {
  $backupTarget = "$resolvedTarget.backup.$((Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffffffZ'))"
  Move-Item -LiteralPath $resolvedTarget -Destination $backupTarget
}
if (-not (Test-Path -LiteralPath (Join-Path $resolvedTarget 'Install.ps1'))) {
  New-Item -ItemType Directory -Force -Path $integrationRoot | Out-Null
  $temporary = Join-Path ([IO.Path]::GetTempPath()) ("hermes-aec-runtime-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $temporary | Out-Null
  try {
    $archive = Join-Path $temporary 'runtime.zip'
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/mmckeen-nv/hermes-aec-runtime/archive/refs/tags/$Version.zip" -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $temporary
    $source = Get-ChildItem -LiteralPath $temporary -Directory | Where-Object Name -Like 'hermes-aec-runtime-*' | Select-Object -First 1
    if (-not $source -or -not (Test-Path -LiteralPath (Join-Path $source.FullName 'Install.ps1')) -or
        -not (Test-Path -LiteralPath (Join-Path $source.FullName 'pyproject.toml'))) {
      throw "Downloaded $Version but its source layout is invalid."
    }
    Move-Item -LiteralPath $source.FullName -Destination $resolvedTarget
  } catch {
    if ($backupTarget -and (Test-Path -LiteralPath $backupTarget) -and -not (Test-Path -LiteralPath $resolvedTarget)) {
      Move-Item -LiteralPath $backupTarget -Destination $resolvedTarget
    }
    throw
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  }
}

try {
  & (Join-Path $resolvedTarget 'Install.ps1') -RhinoPort $RhinoPort
  if ($LASTEXITCODE) { throw "Runtime installer exited with code $LASTEXITCODE." }
} catch {
  if ($backupTarget -and (Test-Path -LiteralPath $backupTarget)) {
    if (Test-Path -LiteralPath $resolvedTarget) { Remove-Item -LiteralPath $resolvedTarget -Recurse -Force }
    Move-Item -LiteralPath $backupTarget -Destination $resolvedTarget
  }
  throw
}
$activePath = Join-Path $integrationRoot 'active.json'
$activeTemporary = "$activePath.$([guid]::NewGuid().ToString('N')).tmp"
try {
  @{ schema_version = 1; version = $Version; root = $resolvedTarget; installed_at = (Get-Date).ToUniversalTime().ToString('o') } |
    ConvertTo-Json | Set-Content -LiteralPath $activeTemporary -Encoding utf8NoBOM
  Move-Item -LiteralPath $activeTemporary -Destination $activePath -Force
} finally {
  if (Test-Path -LiteralPath $activeTemporary) { Remove-Item -LiteralPath $activeTemporary -Force }
}
Write-Host "HERMES_AEC_RUNTIME_READY version=$Version root=$resolvedTarget"
