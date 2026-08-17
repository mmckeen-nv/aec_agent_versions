[CmdletBinding()]
param(
  [ValidateRange(0, 65535)][int]$RhinoPort = 0,
  [ValidateRange(8192, 1050000)][int]$ContextLength = 1000000,
  [switch]$Force,
  [switch]$NoPauseOnError
)

$ErrorActionPreference = 'Stop'

function Write-Utf8NoBom {
  param([Parameter(Mandatory)][string]$LiteralPath, [Parameter(Mandatory)][AllowEmptyString()][string]$Value)
  [IO.File]::WriteAllText($LiteralPath, $Value, (New-Object Text.UTF8Encoding($false)))
}

# Keep an installer window opened from Explorer visible when deployment fails. Automation can
# opt out with -NoPauseOnError while retaining the non-zero process exit code.
trap {
  $failureMessage = $_.Exception.Message
  Write-Host ''
  Write-Host 'AEC_DEMOS_DEPLOYMENT_FAILED' -ForegroundColor Red
  Write-Host $failureMessage -ForegroundColor Red
  Write-Host ''
  Write-Host 'Correct the error above, then run Deploy-AECDemos.ps1 again.' -ForegroundColor Yellow
  if (-not $NoPauseOnError -and [Environment]::UserInteractive) {
    Read-Host 'Press Enter to close this window' | Out-Null
  }
  exit 1
}

$platformRoot = $PSScriptRoot
$fullRoot = Join-Path $platformRoot 'cliff_house_full_build'
$quickRoot = Join-Path $platformRoot 'cliff_house_modifications'

# Validate non-redistributable host applications before creating profiles or installing anything.
$missingPrerequisites = [System.Collections.Generic.List[string]]::new()
$rhinoPath = 'C:\Program Files\Rhino 8\System\Rhino.exe'
$hermesRoot = Join-Path $env:LOCALAPPDATA 'hermes'
$hermesDesktop = Join-Path $hermesRoot 'hermes-agent\apps\desktop\release\win-arm64-unpacked\Hermes.exe'
$hermesCli = Join-Path $hermesRoot 'hermes-agent\venv\Scripts\hermes.exe'
$hermesPython = Join-Path $hermesRoot 'hermes-agent\venv\Scripts\python.exe'
$hermesUv = Join-Path $hermesRoot 'bin\uv.exe'
if (-not (Test-Path -LiteralPath $rhinoPath)) { $missingPrerequisites.Add('Rhino 8 (installed and licensed)') }
if (-not (Test-Path -LiteralPath $hermesDesktop)) { $missingPrerequisites.Add('Hermes Desktop for Windows ARM64') }
if (-not (Test-Path -LiteralPath $hermesCli)) { $missingPrerequisites.Add('Hermes CLI/OOBE completion') }
if (-not (Test-Path -LiteralPath $hermesPython) -and -not (Test-Path -LiteralPath $hermesUv)) {
  $missingPrerequisites.Add('Hermes managed Python or uv runtime')
}
if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { $missingPrerequisites.Add('Git for Windows') }
if ($missingPrerequisites.Count) {
  throw "Prerequisite check failed before deployment changed the machine: $($missingPrerequisites -join '; ')."
}
Write-Host 'AEC_PREREQUISITES_PASS rhino=ready hermes=ready python=managed git=ready'

$runtimeVersionFile = Join-Path (Split-Path -Parent $platformRoot) 'hermes-aec-runtime.version'
$runtimeVersion = (Get-Content -Raw -LiteralPath $runtimeVersionFile).Trim()
if ($runtimeVersion -notmatch '^v\d+\.\d+\.\d+$') { throw "Invalid Hermes AEC runtime pin: $runtimeVersion" }

& (Join-Path $platformRoot 'memory\Install-AECDml.ps1') -Force:$Force

if (-not $RhinoPort) {
  $RhinoPort = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object {
      $_.LocalPort -ge 1024 -and $_.LocalPort -le 65535 -and
      (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -eq 'Rhino'
    } |
    Sort-Object LocalPort -Descending |
    Select-Object -First 1 -ExpandProperty LocalPort
  if (-not $RhinoPort) { $RhinoPort = 1999 }
}

$deployArguments = @{
  RhinoPort = $RhinoPort
  ContextLength = $ContextLength
  Force = $Force
}
& (Join-Path $fullRoot 'installer\Deploy-HermesProfile.ps1') @deployArguments -Profile 'cliff-house-full-build-windows'
& (Join-Path $quickRoot 'installer\Deploy-HermesProfile.ps1') @deployArguments -Profile 'cliff-house-modifications-windows'
& (Join-Path $platformRoot 'runtime\Install-HermesAECRuntime.ps1') -Version $runtimeVersion -RhinoPort $RhinoPort -Force:$Force

$profiles = @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')
$keyValue = $env:NVIDIA_API_KEY
if (-not $keyValue) {
  foreach ($profile in $profiles) {
    $envFile = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\.env"
    if (Test-Path $envFile) {
      $line = Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^NVIDIA_API_KEY=.+' } | Select-Object -First 1
      if ($line) { $keyValue = $line.Substring('NVIDIA_API_KEY='.Length); break }
    }
  }
}
if (-not $keyValue) {
  $secure = Read-Host 'NVIDIA API key (stored only in the two local Hermes profiles)' -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try { $keyValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
  if ([string]::IsNullOrWhiteSpace($keyValue)) { throw 'An NVIDIA API key is required.' }
}
foreach ($profile in $profiles) {
  $envFile = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\.env"
  $lines = if (Test-Path $envFile) { @(Get-Content -LiteralPath $envFile | Where-Object { $_ -notmatch '^NVIDIA_API_KEY=' }) } else { @() }
  $lines += "NVIDIA_API_KEY=$keyValue"
  Write-Utf8NoBom -LiteralPath $envFile -Value (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
}
$keyValue = $null

$stateRoot = Join-Path $env:LOCALAPPDATA 'hermes\aec-demos'
New-Item -ItemType Directory -Force -Path $stateRoot | Out-Null
$deploymentState = @{ schema_version = 2; rhino_transport = 'rhinomcp-direct'; rhino_port = $RhinoPort; legacy_rhino_port = 10500; platform_root = $platformRoot; memory = 'daystrom_dml'; hermes_aec_runtime = $runtimeVersion } | ConvertTo-Json
Write-Utf8NoBom -LiteralPath (Join-Path $stateRoot 'deployment.json') -Value ($deploymentState + [Environment]::NewLine)

$desktop = [Environment]::GetFolderPath('Desktop')
$shell = New-Object -ComObject WScript.Shell
foreach ($shortcutDefinition in @(
  @{ Name = 'AEC Full Build'; Demo = 'FullBuild' },
  @{ Name = 'AEC House Modification'; Demo = 'Modification' }
)) {
  $shortcut = $shell.CreateShortcut((Join-Path $desktop "$($shortcutDefinition.Name).lnk"))
  $shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
  $shortcut.Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$platformRoot\Launch-AECDemo.ps1`" -Demo $($shortcutDefinition.Demo)"
  $shortcut.WorkingDirectory = $platformRoot
  $shortcut.Description = $shortcutDefinition.Name
  $shortcut.Save()
}

Write-Host "AEC_DEMOS_DEPLOYED transport=rhinomcp-direct rhino_port=$RhinoPort memory=daystrom_dml runtime=$runtimeVersion"
Write-Host 'Use the two new Desktop shortcuts: AEC Full Build and AEC House Modification.'
