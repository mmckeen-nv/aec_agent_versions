[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidatePattern('^v\d+\.\d+\.\d+$')][string]$Version,
  [int]$RhinoPort = 10500,
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

if ($Force -and (Test-Path -LiteralPath $resolvedTarget)) {
  Remove-Item -LiteralPath $resolvedTarget -Recurse -Force
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
    if (-not $source) { throw "Downloaded $Version but could not locate its source directory." }
    Move-Item -LiteralPath $source.FullName -Destination $resolvedTarget
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
  }
}

& (Join-Path $resolvedTarget 'Install.ps1') -RhinoPort $RhinoPort
@{ version = $Version; root = $resolvedTarget; installed_at = (Get-Date).ToUniversalTime().ToString('o') } |
  ConvertTo-Json | Set-Content -LiteralPath (Join-Path $integrationRoot 'active.json') -Encoding utf8NoBOM
Write-Host "HERMES_AEC_RUNTIME_READY version=$Version root=$resolvedTarget"
