$RequiredBlenderVersion = '5.2.0'
$RequiredBlenderArm64ArchiveUrl = 'https://download.blender.org/release/Blender5.2/blender-5.2.0-windows-arm64.zip'
$RequiredBlenderArm64ArchiveSha256 = 'C00B6A5D80456D9299865AB4DB730B7C93B0AF4AE77D707548F886692786D881'
$ManagedBlenderRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-5.2.0'
$ManagedBlenderExecutable = Join-Path $ManagedBlenderRoot 'blender.exe'
$ManagedBlenderCacheRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-5.2.0-download'

function Get-BlenderVersionString {
  param([Parameter(Mandatory)][string]$Executable)
  if (-not (Test-Path -LiteralPath $Executable)) { return $null }
  try {
    $versionLine = (& $Executable --version 2>$null | Select-Object -First 1)
    if ($versionLine -match '^Blender\s+([0-9]+\.[0-9]+\.[0-9]+)(?:\s|$)') { return $Matches[1] }
  } catch {}
  return $null
}

function Get-ExternalBlenderCandidates {
  $paths = [System.Collections.Generic.List[string]]::new()
  foreach ($root in @('C:\Program Files\Blender Foundation', (Join-Path $env:LOCALAPPDATA 'Programs\Blender Foundation'))) {
    if (Test-Path -LiteralPath $root) {
      Get-ChildItem -LiteralPath $root -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object { $paths.Add($_.FullName) }
    }
  }
  Get-Process blender -ErrorAction SilentlyContinue | ForEach-Object {
    try { if ($_.Path) { $paths.Add($_.Path) } } catch {}
  }
  return @($paths | Where-Object {
    -not ([IO.Path]::GetFullPath($_).StartsWith([IO.Path]::GetFullPath($ManagedBlenderRoot) + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase))
  } | Sort-Object -Unique)
}

function Get-IncompatibleBlenderSummary {
  $found = @()
  foreach ($candidate in (Get-ExternalBlenderCandidates)) {
    $version = Get-BlenderVersionString -Executable $candidate
    if ($version -ne $RequiredBlenderVersion) {
      $found += "$(if ($version) { $version } else { 'unknown' }) at $candidate"
    }
  }
  foreach ($registryRoot in @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  )) {
    Get-ChildItem -LiteralPath $registryRoot -ErrorAction SilentlyContinue | ForEach-Object {
      try {
        $entry = Get-ItemProperty -LiteralPath $_.PSPath -ErrorAction Stop
        if ($entry.DisplayName -match '(?i)^Blender(?:\s|$)' -and $entry.DisplayVersion -and $entry.DisplayVersion -ne $RequiredBlenderVersion) {
          $found += "$($entry.DisplayVersion) registered as $($entry.DisplayName)"
        }
      } catch {}
    }
  }
  try {
    Get-AppxPackage -ErrorAction Stop | Where-Object { $_.Name -match '(?i)blender' } | ForEach-Object {
      if ($_.Version -and ([version]$_.Version).ToString(3) -ne $RequiredBlenderVersion) {
        $found += "$(([version]$_.Version).ToString(3)) installed as Microsoft Store package $($_.Name)"
      }
    }
  } catch {}
  $found = @($found | Sort-Object -Unique)
  if (-not $found.Count) { return 'none' }
  return ($found -join '; ')
}

function Assert-NoIncompatibleBlender {
  $conflicts = Get-IncompatibleBlenderSummary
  if ($conflicts -ne 'none') {
    throw "BLENDER_UNINSTALL_REQUIRED: Blender $RequiredBlenderVersion is the only supported demo version. Uninstall these conflicting Blender installations, restart Windows if requested, and rerun deployment: $conflicts"
  }
}

function Find-PinnedBlender {
  if ((Get-BlenderVersionString -Executable $ManagedBlenderExecutable) -eq $RequiredBlenderVersion) {
    return Get-Item -LiteralPath $ManagedBlenderExecutable
  }
  return $null
}

function Install-PinnedBlender {
  Assert-NoIncompatibleBlender
  $current = Find-PinnedBlender
  if ($current) {
    Write-Host "BLENDER_MANAGED_CURRENT version=$RequiredBlenderVersion executable=$($current.FullName)"
    return $current
  }

  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if (-not $curl) { throw 'Windows curl.exe is required to install managed Blender.' }
  $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
  if (-not $tar) { throw 'Windows tar.exe is required to extract managed Blender.' }

  New-Item -ItemType Directory -Force -Path $ManagedBlenderCacheRoot | Out-Null
  $archive = Join-Path $ManagedBlenderCacheRoot 'blender-5.2.0-windows-arm64.zip'
  $archiveReady = (Test-Path -LiteralPath $archive) -and ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -eq $RequiredBlenderArm64ArchiveSha256)
  if (-not $archiveReady) {
    if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
    Write-Host "BLENDER_MANAGED_DOWNLOAD_START version=$RequiredBlenderVersion destination=$archive"
    & $curl.Source --location --fail --retry 5 --retry-delay 5 --output $archive $RequiredBlenderArm64ArchiveUrl
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $archive)) { throw 'Managed Blender 5.2.0 download failed.' }
    $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actualHash -ne $RequiredBlenderArm64ArchiveSha256) {
      throw "Managed Blender archive checksum mismatch. Expected $RequiredBlenderArm64ArchiveSha256 but received $actualHash."
    }
  }
  Write-Host "BLENDER_MANAGED_ARCHIVE_VERIFIED sha256=$RequiredBlenderArm64ArchiveSha256"

  $integrationRoot = Split-Path -Parent $ManagedBlenderRoot
  $stage = Join-Path $integrationRoot ("blender-5.2.0-stage-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $stage | Out-Null
  & $tar.Source -xf $archive -C $stage
  $stagedRoot = Join-Path $stage 'blender-5.2.0-windows-arm64'
  $stagedExecutable = Join-Path $stagedRoot 'blender.exe'
  if ($LASTEXITCODE -ne 0 -or (Get-BlenderVersionString -Executable $stagedExecutable) -ne $RequiredBlenderVersion) {
    throw "Managed Blender extraction did not produce a valid $RequiredBlenderVersion ARM64 executable. Staging was preserved at $stage."
  }
  if (Test-Path -LiteralPath $ManagedBlenderRoot) {
    $backup = "$ManagedBlenderRoot.backup.$(Get-Date -Format 'yyyyMMddTHHmmssfff')"
    Move-Item -LiteralPath $ManagedBlenderRoot -Destination $backup
    Write-Host "BLENDER_MANAGED_BACKUP path=$backup"
  }
  Move-Item -LiteralPath $stagedRoot -Destination $ManagedBlenderRoot
  $installed = Find-PinnedBlender
  if (-not $installed) { throw 'Managed Blender 5.2.0 installation did not pass its executable version check.' }
  Write-Host "BLENDER_MANAGED_INSTALLED version=$RequiredBlenderVersion executable=$($installed.FullName)"
  return $installed
}

function Assert-PinnedBlender {
  $blender = Find-PinnedBlender
  if (-not $blender) { throw "Managed Blender $RequiredBlenderVersion is missing. Rerun Deploy-AECDemos.cmd with Blender enabled." }
  return $blender
}
