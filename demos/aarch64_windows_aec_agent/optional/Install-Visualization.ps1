[CmdletBinding()]
param(
  [switch]$EnableBlender,
  [switch]$EnableComfyUI
)

$ErrorActionPreference = 'Stop'
$integrationRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations'
$hermesUv = Join-Path $env:LOCALAPPDATA 'hermes\bin\uvx.exe'
$blenderMcpVersion = '1.8.3'
$comfyVersion = 'v0.33.1'
$comfyArchiveUrl = "https://github.com/Comfy-Org/ComfyUI/releases/download/$comfyVersion/ComfyUI_windows_portable_nvidia.7z"
$models = @(
  @{ Relative = 'diffusion_models\flux-2-klein-base-4b-fp8.safetensors'; Url = 'https://huggingface.co/black-forest-labs/FLUX.2-klein-base-4b-fp8/resolve/main/flux-2-klein-base-4b-fp8.safetensors'; Minimum = 4000000000 },
  @{ Relative = 'text_encoders\qwen_3_4b.safetensors'; Url = 'https://huggingface.co/Comfy-Org/flux2-klein-4B/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors'; Minimum = 8000000000 },
  @{ Relative = 'vae\flux2-vae.safetensors'; Url = 'https://huggingface.co/Comfy-Org/flux2-klein-4B/resolve/main/split_files/vae/flux2-vae.safetensors'; Minimum = 300000000 }
)

function Find-Blender {
  Get-ChildItem -LiteralPath 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1
}

function Test-NativeWindowsArm64 {
  # RuntimeInformation describes the PowerShell process. Windows PowerShell
  # may itself be x64-emulated on ARM64, so inspect native machine signals too.
  $candidates = @($env:PROCESSOR_ARCHITEW6432, $env:PROCESSOR_ARCHITECTURE)
  try { $candidates += (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PROCESSOR_ARCHITECTURE -ErrorAction Stop).PROCESSOR_ARCHITECTURE } catch {}
  try { $candidates += (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).OSArchitecture } catch {}
  return [bool]($candidates | Where-Object { $_ -match '(?i)^ARM64$|ARM\s*64' } | Select-Object -First 1)
}

function ConvertTo-WslMountedPath([string]$WindowsPath) {
  $absolute = [IO.Path]::GetFullPath($WindowsPath)
  if ($absolute -notmatch '^([A-Za-z]):\\(.*)$') { throw "Only absolute Windows drive paths can be passed into WSL: $absolute" }
  $drive = $Matches[1].ToLowerInvariant()
  $tail = $Matches[2] -replace '\\', '/'
  return "/mnt/$drive/$tail"
}

function Find-Ubuntu2404Distribution([string]$WslPath) {
  $names = [System.Collections.Generic.List[string]]::new()
  try {
    foreach ($line in (& $WslPath --list --quiet 2>$null)) {
      $name = ($line -replace "`0", '').Trim()
      if ($name) { $names.Add($name) }
    }
  } catch {}
  try {
    foreach ($key in (Get-ChildItem -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss' -ErrorAction Stop)) {
      $name = (Get-ItemProperty -LiteralPath $key.PSPath -Name DistributionName -ErrorAction Stop).DistributionName
      if ($name) { $names.Add([string]$name) }
    }
  } catch {}
  $candidates = $names | Sort-Object @{ Expression = { if ($_ -eq 'Ubuntu-24.04') { 0 } elseif ($_ -eq 'Ubuntu') { 1 } else { 2 } } }, @{ Expression = { $_ } } -Unique
  foreach ($name in $candidates) {
    if ($name -notmatch '(?i)ubuntu') { continue }
    try {
      $release = ((& $WslPath -d $name -u root -- cat /etc/os-release 2>$null) -join "`n")
      $machine = ((& $WslPath -d $name -u root -- uname -m 2>$null | Select-Object -First 1) -replace "`0", '').Trim()
      $reportedVersion = if ($release -match '(?m)^VERSION_ID="?([^"\r\n]+)') { $Matches[1] } else { 'unknown' }
      Write-Host "WSL_CANDIDATE distribution=$name version=$reportedVersion architecture=$machine"
      if ($release -match '(?m)^ID=ubuntu\s*$' -and $release -match '(?m)^VERSION_ID="?24\.04"?\s*$' -and $machine -match '^(aarch64|arm64)$') {
        return $name
      }
    } catch {}
  }
  $found = if ($names.Count) { ($names | Sort-Object -Unique) -join ', ' } else { 'none detected' }
  throw "A native ARM64 Ubuntu 24.04 WSL2 distribution is required. Installed WSL distributions: $found. A distribution registered as 'Ubuntu' is supported when /etc/os-release reports 24.04."
}

function Receive-LargeFile([string]$Uri, [string]$Destination, [long]$MinimumBytes) {
  if ((Test-Path -LiteralPath $Destination) -and (Get-Item -LiteralPath $Destination).Length -ge $MinimumBytes) {
    Write-Host "DOWNLOAD_CURRENT path=$Destination"
    return
  }
  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if (-not $curl) { throw 'Windows curl.exe is required for resumable visualization downloads.' }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
  Write-Host "DOWNLOAD_START destination=$Destination"
  & $curl.Source --location --fail --retry 5 --retry-delay 5 --continue-at - --output $Destination $Uri
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Destination) -or (Get-Item -LiteralPath $Destination).Length -lt $MinimumBytes) {
    throw "Download is incomplete: $Destination. Keep the partial file and rerun on a stable connection."
  }
  Write-Host "DOWNLOAD_READY bytes=$((Get-Item -LiteralPath $Destination).Length) path=$Destination"
}

if ($EnableBlender) {
  $blender = Find-Blender
  if (-not $blender) { throw 'Blender was selected but is not installed. Install Blender from https://www.blender.org/download/ and rerun deployment.' }
  if (-not (Test-Path -LiteralPath $hermesUv)) { throw 'Hermes uvx is missing; repair Hermes Desktop.' }
  $versionLine = (& $blender.FullName --version | Select-Object -First 1)
  if ($versionLine -notmatch 'Blender\s+(\d+\.\d+)') { throw "Could not determine Blender version from $($blender.FullName)." }
  $blenderVersion = $Matches[1]
  # A fresh Blender installation does not create its per-user script tree until
  # first use. The BlenderMCP installer otherwise fails before our startup hook
  # can be deployed, so create and explicitly select the deterministic target.
  $blenderScriptsRoot = Join-Path $env:APPDATA "Blender Foundation\Blender\$blenderVersion\scripts"
  $addonsRoot = Join-Path $blenderScriptsRoot 'addons'
  New-Item -ItemType Directory -Force -Path $addonsRoot | Out-Null
  $previousPythonUtf8 = $env:PYTHONUTF8
  $previousAddonsDir = $env:BLENDERMCP_ADDONS_DIR
  $env:PYTHONUTF8 = '1'
  $env:BLENDERMCP_ADDONS_DIR = $addonsRoot
  try {
    & $hermesUv --from "blender-mcp==$blenderMcpVersion" blender-mcp install-addon --addons-dir $addonsRoot
  } finally {
    if ($null -eq $previousPythonUtf8) { Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue }
    else { $env:PYTHONUTF8 = $previousPythonUtf8 }
    if ($null -eq $previousAddonsDir) { Remove-Item Env:BLENDERMCP_ADDONS_DIR -ErrorAction SilentlyContinue }
    else { $env:BLENDERMCP_ADDONS_DIR = $previousAddonsDir }
  }
  if ($LASTEXITCODE) { throw 'Pinned BlenderMCP add-on installation failed.' }
  $startupRoot = Join-Path $blenderScriptsRoot 'startup'
  New-Item -ItemType Directory -Force -Path $startupRoot | Out-Null
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'hermes_aec_blender_startup.py') -Destination (Join-Path $startupRoot 'hermes_aec_blender_startup.py') -Force
  $wrapperRoot = Join-Path $integrationRoot 'blender-mcp'
  New-Item -ItemType Directory -Force -Path $wrapperRoot | Out-Null
  $wrapper = "@echo off`r`nset DISABLE_TELEMETRY=true`r`nset PYTHONUTF8=1`r`n`"$hermesUv`" --from blender-mcp==$blenderMcpVersion blender-mcp %*`r`n"
  Set-Content -LiteralPath (Join-Path $wrapperRoot 'blender-mcp.cmd') -Value $wrapper -Encoding ascii
  Write-Host "BLENDER_INTEGRATION_READY version=$blenderVersion mcp=$blenderMcpVersion addons=$addonsRoot port=9876"
}

if ($EnableComfyUI) {
  $comfyRoot = Join-Path $integrationRoot 'comfyui-aec'
  $isArm64 = Test-NativeWindowsArm64
  Write-Host "COMFYUI_PLATFORM_DETECTED arm64=$($isArm64.ToString().ToLowerInvariant()) process_architecture=$([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
  $modelsRoot = if ($isArm64) { Join-Path $comfyRoot 'models' } else { Join-Path $comfyRoot 'portable\ComfyUI_windows_portable\ComfyUI\models' }
  foreach ($model in $models) {
    $candidate = Join-Path $modelsRoot $model.Relative
    $present = (Test-Path -LiteralPath $candidate) -and (Get-Item -LiteralPath $candidate).Length -ge $model.Minimum
    Write-Host "COMFY_MODEL_CHECK present=$($present.ToString().ToLowerInvariant()) path=$candidate minimum_bytes=$($model.Minimum)"
  }
  if ($isArm64) {
    $initializerRevision = '9'
    $statusPath = Join-Path $comfyRoot 'wsl-initialization.json'
    Remove-Item -LiteralPath $statusPath -Force -ErrorAction SilentlyContinue
    $initializer = Join-Path $PSScriptRoot 'Initialize-WSL2.ps1'
    $initializerHash = (Get-FileHash -LiteralPath $initializer -Algorithm SHA256).Hash
    Write-Host "WSL_INITIALIZER revision=$initializerRevision sha256=$initializerHash path=$initializer"
    $wslAlreadyReady = $false
    $existingWsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
    Write-Host "WSL2_CHECK executable_present=$([bool]$existingWsl)"
    if ($existingWsl) {
      try {
        $existingDistro = Find-Ubuntu2404Distribution $existingWsl.Source
        $kernel = ((& $existingWsl.Source -d $existingDistro -u root -- uname -r | Select-Object -First 1) -replace "`0", '').Trim()
        $nvidiaUid = (((& $existingWsl.Source -d $existingDistro -u root -- bash -lc 'id -u nvidia 2>/dev/null || true') -join '') -replace "`0", '').Trim()
        $nvidiaUserPresent = $nvidiaUid -match '^\d+$'
        $wslKernelReady = $kernel -match '(?i)WSL2'
        # Repair this on every run. Earlier installers could create a malformed
        # file when wsl.exe consumed quoted newline escapes.
        & $existingWsl.Source -d $existingDistro -u root -- bash -c 'echo W3VzZXJdCmRlZmF1bHQ9bnZpZGlhCg== | base64 -d > /etc/wsl.conf && test $(base64 -w0 /etc/wsl.conf) = W3VzZXJdCmRlZmF1bHQ9bnZpZGlhCg=='
        $wslConfigReady = $LASTEXITCODE -eq 0
        Write-Host "UBUNTU_CHECK installed=true distribution=$existingDistro version=24.04 architecture=arm64 wsl2=$($wslKernelReady.ToString().ToLowerInvariant())"
        Write-Host "WSL_DEMO_USER_CHECK present=$($nvidiaUserPresent.ToString().ToLowerInvariant()) user=nvidia"
        Write-Host "WSL_CONFIG_CHECK valid=$($wslConfigReady.ToString().ToLowerInvariant())"
        $wslAlreadyReady = $nvidiaUserPresent -and $wslKernelReady -and $wslConfigReady
        if ($wslAlreadyReady) {
          [IO.File]::WriteAllText($statusPath, (@{ status = 'ready'; message = 'Existing WSL2 appliance passed sanity checks.'; distribution = $existingDistro; initializer_revision = $initializerRevision } | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))
        }
      } catch { Write-Host "UBUNTU_CHECK installed=false detail=$($_.Exception.Message)" }
    }
    if (-not $wslAlreadyReady) {
      $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
      if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        & $initializer -StatusPath $statusPath -ExpectedRevision $initializerRevision
      } else {
        Write-Host 'WSL2 initialization requires one Windows administrator approval.' -ForegroundColor Yellow
        $arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$initializer`" -StatusPath `"$statusPath`" -ExpectedRevision `"$initializerRevision`""
        $process = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        if ($process.ExitCode -ne 0 -and -not (Test-Path -LiteralPath $statusPath)) { throw 'Elevated WSL2 initialization failed or was cancelled.' }
      }
    }
    if (-not (Test-Path -LiteralPath $statusPath)) { throw 'WSL2 initialization did not produce a status result.' }
    $wslStatus = Get-Content -Raw -LiteralPath $statusPath | ConvertFrom-Json
    if ($wslStatus.initializer_revision -ne $initializerRevision) { throw "Stale WSL initializer result detected. Expected revision $initializerRevision but received '$($wslStatus.initializer_revision)'." }
    if ($wslStatus.status -eq 'restart_required') { throw $wslStatus.message }
    if ($wslStatus.status -ne 'ready') { throw "WSL2 initialization failed: $($wslStatus.message)" }
    Write-Host "WSL2_INITIALIZATION_PASS distribution=$($wslStatus.distribution) user=nvidia"
    Write-Host 'DEMO_CREDENTIAL_NOTICE WSL user=nvidia password=nvidia. This weak credential is for the isolated demo appliance only.' -ForegroundColor Yellow
  }
  foreach ($model in $models) {
    $destination = Join-Path $modelsRoot $model.Relative
    if ($isArm64 -and -not (Test-Path -LiteralPath $destination)) {
      # Recover the three shallow model files from an earlier misdetected x64
      # attempt without traversing or deleting its deeply nested Python tree.
      $legacyModel = Join-Path $comfyRoot (Join-Path 'portable\ComfyUI_windows_portable\ComfyUI\models' $model.Relative)
      if ((Test-Path -LiteralPath $legacyModel) -and (Get-Item -LiteralPath $legacyModel).Length -ge $model.Minimum) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
        Copy-Item -LiteralPath $legacyModel -Destination $destination
        Write-Host "MODEL_RECOVERED_FROM_PORTABLE path=$destination"
      }
    }
    Receive-LargeFile -Uri $model.Url -Destination $destination -MinimumBytes $model.Minimum
  }
  $launcher = Join-Path $comfyRoot 'Start-AEC-ComfyUI.cmd'
  $controller = Join-Path $comfyRoot 'Start-AEC-ComfyUI.ps1'
  $launchStatePath = Join-Path $comfyRoot 'comfyui-launch.json'
  if ($isArm64) {
    $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $wsl) { throw 'ComfyUI on Windows ARM64 requires WSL2. Run wsl --install, restart Windows, and rerun deployment.' }
    $wslDistro = $null
    $probeError = $null
    $probeDeadline = (Get-Date).AddSeconds(60)
    do {
      try { $wslDistro = Find-Ubuntu2404Distribution $wsl.Source } catch { $probeError = $_.Exception.Message }
      if (-not $wslDistro) { Start-Sleep -Seconds 2 }
    } while (-not $wslDistro -and (Get-Date) -lt $probeDeadline)
    if (-not $wslDistro) { throw "Ubuntu did not become ready within 60 seconds after initialization: $probeError" }
    Write-Host "WSL_UBUNTU_DETECTED distribution=$wslDistro version=24.04 architecture=arm64"
    $linuxUser = 'nvidia'
    $linuxUid = (((& $wsl.Source -d $wslDistro -u root -- bash -lc 'id -u nvidia 2>/dev/null || true') -join '') -replace "`0", '').Trim()
    if ($linuxUid -notmatch '^\d+$') { throw "$wslDistro did not retain the required nvidia demo user after initialization." }
    $setupSource = Join-Path $PSScriptRoot 'install-comfy-wsl.sh'
    $setupStaged = Join-Path $comfyRoot 'install-comfy-wsl.lf.sh'
    $setupText = [IO.File]::ReadAllText($setupSource).Replace("`r`n", "`n").Replace("`r", "`n")
    [IO.File]::WriteAllText($setupStaged, $setupText, (New-Object Text.UTF8Encoding($false)))
    $setupScript = ConvertTo-WslMountedPath $setupStaged
    $linuxModels = ConvertTo-WslMountedPath $modelsRoot
    Write-Host "WSL_PATHS_READY setup=$setupScript models=$linuxModels"
    Write-Host "COMFY_WSL_BOOTSTRAP revision=4 line_endings=lf mode=direct-logged"
    & $wsl.Source -d $wslDistro -u root -- bash $setupScript $linuxUser $linuxModels
    if ($LASTEXITCODE) { throw 'Native ARM64 ComfyUI installation in WSL2 failed.' }
    # Keep the WSL client attached to ComfyUI. This works without systemd and
    # prevents WSL from idling out while the demo is running.
    $linuxComfyRoot = "/home/$linuxUser/.local/share/hermes-aec/comfyui"
    $backend = 'wsl2-arm64-cu130'
    $launchState = @{
      schema_version = 1; backend = $backend; port = 8188; distribution = $wslDistro
      user = $linuxUser; linux_root = $linuxComfyRoot
    }
  } else {
    $archive = Join-Path $comfyRoot "downloads\ComfyUI_windows_portable_nvidia-$comfyVersion.7z"
    Receive-LargeFile -Uri $comfyArchiveUrl -Destination $archive -MinimumBytes 1000000000
    $portableRoot = Join-Path $comfyRoot 'portable'
    $mainScript = Join-Path $portableRoot 'ComfyUI_windows_portable\ComfyUI\main.py'
    if (-not (Test-Path -LiteralPath $mainScript)) {
      $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
      if (-not $tar) { throw 'Windows tar.exe is required to extract the official ComfyUI portable package.' }
      $stage = Join-Path $comfyRoot ("stage-" + [guid]::NewGuid().ToString('N'))
      New-Item -ItemType Directory -Force -Path $stage | Out-Null
      & $tar.Source -xf $archive -C $stage
      if ($LASTEXITCODE -or -not (Test-Path -LiteralPath (Join-Path $stage 'ComfyUI_windows_portable\ComfyUI\main.py'))) { throw 'Official ComfyUI archive extraction failed.' }
      if (Test-Path -LiteralPath $portableRoot) { Remove-Item -LiteralPath $portableRoot -Recurse -Force }
      Move-Item -LiteralPath $stage -Destination $portableRoot
    }
    $embeddedPython = Join-Path $portableRoot 'ComfyUI_windows_portable\python_embeded\python.exe'
    if (-not (Test-Path -LiteralPath $embeddedPython)) { throw 'ComfyUI embedded Python is missing after extraction.' }
    $backend = 'windows-portable'
    $launchState = @{
      schema_version = 1; backend = $backend; port = 8188; executable = $embeddedPython
      arguments = @('-s', $mainScript, '--listen', '127.0.0.1', '--port', '8188', '--windows-standalone-build', '--disable-auto-launch')
    }
  }
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Start-AEC-ComfyUI.ps1') -Destination $controller -Force
  $launchStateText = $launchState | ConvertTo-Json -Depth 8
  [IO.File]::WriteAllText($launchStatePath, $launchStateText + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
  $launcherText = "@echo off`r`npowershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Start-AEC-ComfyUI.ps1`" %*`r`n"
  Set-Content -LiteralPath $launcher -Value $launcherText -Encoding ascii
  & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $controller -WaitSeconds 420
  if ($LASTEXITCODE) { throw "Managed ComfyUI startup controller failed with exit code $LASTEXITCODE." }
  $stats = Invoke-RestMethod -UseBasicParsing -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 10
  $statsText = $stats | ConvertTo-Json -Depth 10
  if ($statsText -notmatch '(?i)cuda' -or $statsText -notmatch '(?i)nvidia') { throw 'ComfyUI is online but did not report an NVIDIA CUDA device.' }
  if ($isArm64 -and ($stats.system.os -ne 'linux' -or $stats.system.pytorch_version -notmatch '\+cu130')) { throw 'Windows ARM64 must use native WSL2 ComfyUI with the CUDA 13 PyTorch build.' }
  $objectInfo = Invoke-RestMethod -UseBasicParsing -Uri 'http://127.0.0.1:8188/object_info' -TimeoutSec 30
  foreach ($node in @('UNETLoader', 'CLIPLoader', 'VAELoader', 'LoadImage', 'SaveImage')) {
    if (-not $objectInfo.$node) { throw "ComfyUI required node is unavailable: $node" }
  }
  Write-Host "COMFYUI_INTEGRATION_READY version=$comfyVersion backend=$backend port=8188 model=flux-2-klein-base-4b-fp8"
}
