[CmdletBinding()]
param([Parameter(Mandatory)][string]$StatusPath)

$ErrorActionPreference = 'Stop'

function Save-Status([string]$Status, [string]$Message = '', [string]$Distribution = '') {
  $parent = Split-Path -Parent $StatusPath
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  [IO.File]::WriteAllText($StatusPath, (@{ status = $Status; message = $Message; distribution = $Distribution } | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
}

try {
  $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'WSL2 initialization must run as Administrator.' }

  $restartRequired = $false
  foreach ($featureName in @('Microsoft-Windows-Subsystem-Linux', 'VirtualMachinePlatform')) {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName
    if ($feature.State -ne 'Enabled') {
      $result = Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All -NoRestart
      if ($result.RestartNeeded) { $restartRequired = $true }
    }
  }
  if ($restartRequired) {
    Save-Status 'restart_required' 'Windows enabled WSL2 prerequisites. Restart Windows, then rerun deployment.'
    exit 0
  }

  $wsl = (Get-Command wsl.exe -ErrorAction Stop).Source
  & $wsl --set-default-version 2
  if ($LASTEXITCODE) { throw 'Could not set WSL default version to 2.' }
  & $wsl --update
  if ($LASTEXITCODE) { throw 'WSL update failed.' }

  $names = @()
  try { $names += (& $wsl --list --quiet 2>$null) | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ } } catch {}
  try {
    $names += Get-ChildItem -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction Stop | ForEach-Object {
      (Get-ItemProperty -LiteralPath $_.PSPath -Name DistributionName -ErrorAction Stop).DistributionName
    }
  } catch {}
  $distribution = $null
  $ubuntuCandidates = $names | Where-Object { $_ -match '(?i)ubuntu' } | Sort-Object @{ Expression = { if ($_ -eq 'Ubuntu-24.04') { 0 } elseif ($_ -eq 'Ubuntu') { 1 } else { 2 } } }, @{ Expression = { $_ } } -Unique
  foreach ($candidate in $ubuntuCandidates) {
    $release = ((& $wsl -d $candidate -- cat /etc/os-release 2>$null) -join "`n")
    $machine = ((& $wsl -d $candidate -- uname -m 2>$null | Select-Object -First 1) -replace "`0", '').Trim()
    if ($release -match '(?m)^ID=ubuntu\s*$' -and $release -match '(?m)^VERSION_ID="?24\.04"?\s*$' -and $machine -match '^(aarch64|arm64)$') {
      $distribution = $candidate
      break
    }
  }
  if (-not $distribution) {
    & $wsl --install -d Ubuntu-24.04 --no-launch
    if ($LASTEXITCODE) { throw 'Ubuntu 24.04 installation through WSL failed.' }
    $distribution = 'Ubuntu-24.04'
    $release = ((& $wsl -d $distribution -u root -- cat /etc/os-release 2>$null) -join "`n")
    if ($LASTEXITCODE -ne 0 -or $release -notmatch '(?m)^VERSION_ID="?24\.04"?\s*$') {
      Save-Status 'restart_required' 'Ubuntu 24.04 was installed. Restart Windows, then rerun deployment to initialize it.' $distribution
      exit 0
    }
  }

  & $wsl --set-version $distribution 2
  if ($LASTEXITCODE) { throw "Could not configure $distribution as WSL2." }
  $initialize = 'set -e; id -u nvidia >/dev/null 2>&1 || useradd -m -s /bin/bash nvidia; echo nvidia:nvidia | chpasswd; usermod -aG sudo nvidia; printf "[boot]\nsystemd=true\n\n[user]\ndefault=nvidia\n" > /etc/wsl.conf'
  & $wsl -d $distribution -u root -- bash -lc $initialize
  if ($LASTEXITCODE) { throw "Could not initialize the nvidia demo user in $distribution." }
  & $wsl --terminate $distribution
  Save-Status 'ready' 'WSL2 and Ubuntu are initialized.' $distribution
} catch {
  Save-Status 'error' $_.Exception.Message
  exit 1
}
