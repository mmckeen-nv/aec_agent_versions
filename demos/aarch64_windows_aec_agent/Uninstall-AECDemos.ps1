[CmdletBinding()]
param(
  [switch]$Yes,
  [switch]$RemoveRhino
)

$ErrorActionPreference = 'Stop'
$logPath = Join-Path $env:TEMP ("hermes-aec-demo-uninstall-{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Write-UninstallLog([string]$Message) {
  $line = "{0} {1}" -f (Get-Date).ToUniversalTime().ToString('o'), $Message
  Write-Host $Message
  Add-Content -LiteralPath $logPath -Encoding UTF8 -Value $line
}

function Assert-ChildPath([string]$Path, [string]$Root) {
  $resolvedPath = [IO.Path]::GetFullPath($Path)
  $resolvedRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar)
  if (-not $resolvedPath.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing unsafe uninstall target outside $resolvedRoot`: $resolvedPath"
  }
  return $resolvedPath
}

function Remove-ManagedPath([string]$Path, [string]$Root) {
  $safePath = Assert-ChildPath -Path $Path -Root $Root
  if (Test-Path -LiteralPath $safePath) {
    Remove-Item -LiteralPath $safePath -Recurse -Force
    Write-UninstallLog "REMOVED $safePath"
  }
}

function Find-RhinoUninstaller {
  $locations = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
  )
  return Get-ItemProperty -Path $locations -ErrorAction SilentlyContinue |
    Where-Object {
      $_.DisplayName -match '^(Rhino|Rhinoceros) 8(?:\b|$)' -and $_.Publisher -match 'McNeel'
    } | Select-Object -First 1
}

function Invoke-RhinoUninstaller {
  $entry = Find-RhinoUninstaller
  if (-not $entry) { throw 'Rhino 8 is installed, but its registered McNeel uninstaller was not found.' }
  $command = if ($entry.QuietUninstallString) { $entry.QuietUninstallString } else { $entry.UninstallString }
  if ([string]::IsNullOrWhiteSpace($command)) { throw 'Rhino 8 has no registered uninstall command.' }
  if ($command -match '^\s*"([^"]+\.exe)"\s*(.*)$') {
    $executable = $Matches[1]
    $arguments = $Matches[2]
  } elseif ($command -match '^\s*(.+?\.exe)\s*(.*)$') {
    $executable = $Matches[1]
    $arguments = $Matches[2]
  } else { throw 'Rhino 8 registered an unsupported uninstall command.' }
  if ([IO.Path]::GetFileName($executable) -ieq 'msiexec.exe') {
    $arguments = [regex]::Replace($arguments, '(?i)(^|\s)/I(?=\s|\{)', '$1/X', 1)
  }
  Write-UninstallLog "STARTING_RHINO_UNINSTALL display_name=$($entry.DisplayName)"
  $process = Start-Process -FilePath $executable -ArgumentList $arguments -Verb RunAs -Wait -PassThru
  if ($process.ExitCode -notin @(0, 1641, 3010)) { throw "Rhino uninstaller exited with code $($process.ExitCode)." }
  Write-UninstallLog "RHINO_UNINSTALL_FINISHED exit_code=$($process.ExitCode)"
}

trap {
  Write-UninstallLog "AEC_DEMOS_UNINSTALL_FAILED $($_.Exception.Message)"
  Write-Host "Uninstall log: $logPath" -ForegroundColor Yellow
  if ([Environment]::UserInteractive) { Read-Host 'Press Enter to close this window' | Out-Null }
  exit 1
}

Write-Host 'This removes both Cliff House Hermes profiles, their local API-key files, desktop shortcuts,'
Write-Host 'Daystrom DML, Hermes AEC runtime versions, and the managed AEC RhinoMCP plug-in.'
Write-Host 'The downloaded repository and generated project/work files are preserved.'
if (-not $Yes) {
  if ((Read-Host 'Type UNINSTALL to continue') -cne 'UNINSTALL') {
    Write-Host 'Uninstall cancelled. Nothing was removed.'
    exit 0
  }
}

$shouldRemoveRhino = [bool]$RemoveRhino
if (-not $RemoveRhino -and -not $Yes) {
  $answer = Read-Host 'Also uninstall Rhino 8 from this computer? [y/N]'
  $shouldRemoveRhino = $answer -match '^(?i:y|yes)$'
}

if (Get-Process Rhino -ErrorAction SilentlyContinue) { throw 'Close every Rhino window before uninstalling the demos.' }
if (Get-Process Hermes -ErrorAction SilentlyContinue) { throw 'Close Hermes Desktop before uninstalling the demos.' }

$localHermes = Join-Path $env:LOCALAPPDATA 'hermes'
$profilesRoot = Join-Path $localHermes 'profiles'
$integrationsRoot = Join-Path $localHermes 'integrations'
foreach ($profile in @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')) {
  Remove-ManagedPath -Path (Join-Path $profilesRoot $profile) -Root $profilesRoot
}
Remove-ManagedPath -Path (Join-Path $integrationsRoot 'hermes-aec-runtime') -Root $integrationsRoot
Remove-ManagedPath -Path (Join-Path $integrationsRoot 'daystrom-dml') -Root $integrationsRoot
Remove-ManagedPath -Path (Join-Path $localHermes 'aec-demos') -Root $localHermes

$desktop = [Environment]::GetFolderPath('Desktop')
foreach ($name in @('AEC Full Build.lnk', 'AEC House Modification.lnk')) {
  $shortcut = Assert-ChildPath -Path (Join-Path $desktop $name) -Root $desktop
  if (Test-Path -LiteralPath $shortcut) { Remove-Item -LiteralPath $shortcut -Force; Write-UninstallLog "REMOVED $shortcut" }
}

$pluginGuid = 'ca441fe8-afc4-43a4-bee5-53e65030d229'
$pluginRoot = Join-Path $env:APPDATA 'McNeel\Rhinoceros\8.0\Plug-ins'
Get-ChildItem -LiteralPath $pluginRoot -Directory -Filter "AEC RhinoMCP ($pluginGuid)*" -ErrorAction SilentlyContinue | ForEach-Object {
  Remove-ManagedPath -Path $_.FullName -Root $pluginRoot
}
$pluginRegistry = "HKCU:\Software\McNeel\Rhinoceros\8.0\Plug-ins\$pluginGuid"
if (Test-Path $pluginRegistry) { Remove-Item -Path $pluginRegistry -Recurse -Force; Write-UninstallLog "REMOVED $pluginRegistry" }

if ($shouldRemoveRhino -and (Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe')) {
  Invoke-RhinoUninstaller
} elseif ($shouldRemoveRhino) {
  Write-UninstallLog 'RHINO_ALREADY_ABSENT'
} else {
  Write-UninstallLog 'RHINO_PRESERVED'
}

Write-UninstallLog "AEC_DEMOS_UNINSTALLED rhino_removed=$($shouldRemoveRhino.ToString().ToLower())"
Write-Host "Uninstall log: $logPath"
