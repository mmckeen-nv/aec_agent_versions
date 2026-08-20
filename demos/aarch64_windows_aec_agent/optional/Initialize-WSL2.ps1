[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$StatusPath,
  [Parameter(Mandatory)][string]$ExpectedRevision
)

$ErrorActionPreference = 'Stop'

function Save-Status([string]$Status, [string]$Message = '', [string]$Distribution = '') {
  $parent = Split-Path -Parent $StatusPath
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
  [IO.File]::WriteAllText($StatusPath, (@{ status = $Status; message = $Message; distribution = $Distribution; initializer_revision = $ExpectedRevision } | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
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
    Save-Status 'restart_required' 'Windows enabled the WSL2 prerequisites. RESTART WINDOWS AND RUN Deploy-AECDemos.cmd AGAIN.'
    exit 0
  }

  $wsl = (Get-Command wsl.exe -ErrorAction Stop).Source
  & $wsl --set-default-version 2
  # Do not run `wsl --update` here. Store-managed, inbox, and enterprise WSL
  # service through incompatible channels. The live WSL2 kernel and Ubuntu
  # checks below are the authoritative compatibility gates.

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
    $release = ((& $wsl -d $candidate -u root -- cat /etc/os-release 2>$null) -join "`n")
    $machine = ((& $wsl -d $candidate -u root -- uname -m 2>$null | Select-Object -First 1) -replace "`0", '').Trim()
    if ($release -match '(?m)^ID=ubuntu\s*$' -and $release -match '(?m)^VERSION_ID="?24\.04"?\s*$' -and $machine -match '^(aarch64|arm64)$') {
      $distribution = $candidate
      break
    }
  }
  if (-not $distribution) {
    & $wsl --install -d Ubuntu-24.04 --no-launch
    $distribution = 'Ubuntu-24.04'
    $release = ((& $wsl -d $distribution -u root -- cat /etc/os-release 2>$null) -join "`n")
    if ($release -notmatch '(?m)^VERSION_ID="?24\.04"?\s*$') {
      Save-Status 'restart_required' 'Ubuntu 24.04 was installed. RESTART WINDOWS AND RUN Deploy-AECDemos.cmd AGAIN.' $distribution
      exit 0
    }
  }

  $kernel = ((& $wsl -d $distribution -u root -- uname -r 2>$null | Select-Object -First 1) -replace "`0", '').Trim()
  if ($kernel -notmatch '(?i)WSL2') {
    & $wsl --set-version $distribution 2
    $kernel = ((& $wsl -d $distribution -u root -- uname -r 2>$null | Select-Object -First 1) -replace "`0", '').Trim()
  }
  if ($kernel -notmatch '(?i)WSL2') { throw "$distribution did not start with a WSL2 kernel after configuration (reported '$kernel')." }
  # Base64 avoids wsl.exe/bash argument conversion corrupting embedded newlines.
  $initialize = 'set -e; id -u nvidia >/dev/null 2>&1 || useradd -m -s /bin/bash nvidia; echo nvidia:nvidia | chpasswd; usermod -aG sudo nvidia; echo W3VzZXJdCmRlZmF1bHQ9bnZpZGlhCg== | base64 -d > /etc/wsl.conf; test $(base64 -w0 /etc/wsl.conf) = W3VzZXJdCmRlZmF1bHQ9bnZpZGlhCg=='
  & $wsl -d $distribution -u root -- bash -lc $initialize
  if ($LASTEXITCODE) { throw "Could not initialize the nvidia demo user in $distribution." }
  & $wsl --terminate $distribution
  Save-Status 'ready' 'WSL2 and Ubuntu are initialized.' $distribution
} catch {
  Save-Status 'error' $_.Exception.Message
  exit 1
}
