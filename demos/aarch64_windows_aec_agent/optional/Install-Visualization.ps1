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
  $previousPythonUtf8 = $env:PYTHONUTF8
  $env:PYTHONUTF8 = '1'
  try {
    & $hermesUv --from "blender-mcp==$blenderMcpVersion" blender-mcp install-addon
  } finally {
    if ($null -eq $previousPythonUtf8) { Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue }
    else { $env:PYTHONUTF8 = $previousPythonUtf8 }
  }
  if ($LASTEXITCODE) { throw 'Pinned BlenderMCP add-on installation failed.' }
  $versionLine = (& $blender.FullName --version | Select-Object -First 1)
  if ($versionLine -notmatch 'Blender\s+(\d+\.\d+)') { throw "Could not determine Blender version from $($blender.FullName)." }
  $startupRoot = Join-Path $env:APPDATA "Blender Foundation\Blender\$($Matches[1])\scripts\startup"
  New-Item -ItemType Directory -Force -Path $startupRoot | Out-Null
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'hermes_aec_blender_startup.py') -Destination (Join-Path $startupRoot 'hermes_aec_blender_startup.py') -Force
  $wrapperRoot = Join-Path $integrationRoot 'blender-mcp'
  New-Item -ItemType Directory -Force -Path $wrapperRoot | Out-Null
  $wrapper = "@echo off`r`nset DISABLE_TELEMETRY=true`r`nset PYTHONUTF8=1`r`n`"$hermesUv`" --from blender-mcp==$blenderMcpVersion blender-mcp %*`r`n"
  Set-Content -LiteralPath (Join-Path $wrapperRoot 'blender-mcp.cmd') -Value $wrapper -Encoding ascii
  Write-Host "BLENDER_INTEGRATION_READY version=$($Matches[1]) mcp=$blenderMcpVersion port=9876"
}

if ($EnableComfyUI) {
  $comfyRoot = Join-Path $integrationRoot 'comfyui-aec'
  $isArm64 = Test-NativeWindowsArm64
  Write-Host "COMFYUI_PLATFORM_DETECTED arm64=$($isArm64.ToString().ToLowerInvariant()) process_architecture=$([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture)"
  $modelsRoot = if ($isArm64) { Join-Path $comfyRoot 'models' } else { Join-Path $comfyRoot 'portable\ComfyUI_windows_portable\ComfyUI\models' }
  foreach ($model in $models) {
    Receive-LargeFile -Uri $model.Url -Destination (Join-Path $modelsRoot $model.Relative) -MinimumBytes $model.Minimum
  }
  $launcher = Join-Path $comfyRoot 'Start-AEC-ComfyUI.cmd'
  if ($isArm64) {
    $wsl = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if (-not $wsl) { throw 'ComfyUI on Windows ARM64 requires WSL2. Run wsl --install, restart Windows, and rerun deployment.' }
    $distros = (& $wsl.Source --list --quiet) -replace "`0", ''
    if ($distros -notcontains 'Ubuntu-24.04') { throw 'Ubuntu-24.04 is required for native ARM64 ComfyUI. Run wsl --install -d Ubuntu-24.04, restart if requested, then rerun deployment.' }
    $linuxUser = (& $wsl.Source -d Ubuntu-24.04 -- id -un | Select-Object -First 1).Trim()
    if (-not $linuxUser -or $linuxUser -eq 'root') { throw 'Ubuntu-24.04 must have a normal default user before deploying ComfyUI.' }
    $setupScript = (& $wsl.Source -d Ubuntu-24.04 -- wslpath -a (Join-Path $PSScriptRoot 'install-comfy-wsl.sh') | Select-Object -First 1).Trim()
    $linuxModels = (& $wsl.Source -d Ubuntu-24.04 -- wslpath -a $modelsRoot | Select-Object -First 1).Trim()
    & $wsl.Source -d Ubuntu-24.04 -u root -- bash $setupScript $linuxUser $linuxModels
    if ($LASTEXITCODE) { throw 'Native ARM64 ComfyUI installation in WSL2 failed.' }
    # Keep one WSL client attached. WSL may idle-terminate the VM even while a
    # systemd unit is active; following the managed journal keeps inference alive.
    $launcherText = "@echo off`r`nwsl.exe -d Ubuntu-24.04 -u root -- bash -lc `"systemctl start hermes-aec-comfyui.service; exec journalctl -fu hermes-aec-comfyui.service`"`r`nif errorlevel 1 pause`r`n"
    $backend = 'wsl2-arm64-cu130'
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
    $launcherText = "@echo off`r`n`"$embeddedPython`" -s `"$mainScript`" --listen 127.0.0.1 --port 8188 --windows-standalone-build --disable-auto-launch`r`n"
    $backend = 'windows-portable'
  }
  Set-Content -LiteralPath $launcher -Value $launcherText -Encoding ascii
  if (-not (Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $launcher -WindowStyle Minimized
  }
  $deadline = (Get-Date).AddMinutes(5)
  do {
    Start-Sleep -Seconds 3
    try { $stats = Invoke-RestMethod -UseBasicParsing -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 5 } catch { $stats = $null }
  } while (-not $stats -and (Get-Date) -lt $deadline)
  if (-not $stats) { throw 'ComfyUI did not become ready on 127.0.0.1:8188 within five minutes.' }
  $statsText = $stats | ConvertTo-Json -Depth 10
  if ($statsText -notmatch '(?i)cuda' -or $statsText -notmatch '(?i)nvidia') { throw 'ComfyUI is online but did not report an NVIDIA CUDA device.' }
  if ($isArm64 -and ($stats.system.os -ne 'linux' -or $stats.system.pytorch_version -notmatch '\+cu130')) { throw 'Windows ARM64 must use native WSL2 ComfyUI with the CUDA 13 PyTorch build.' }
  $objectInfo = Invoke-RestMethod -UseBasicParsing -Uri 'http://127.0.0.1:8188/object_info' -TimeoutSec 30
  foreach ($node in @('UNETLoader', 'CLIPLoader', 'VAELoader', 'LoadImage', 'SaveImage')) {
    if (-not $objectInfo.$node) { throw "ComfyUI required node is unavailable: $node" }
  }
  Write-Host "COMFYUI_INTEGRATION_READY version=$comfyVersion backend=$backend port=8188 model=flux-2-klein-base-4b-fp8"
}
