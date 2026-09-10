[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'optional\Blender-Pin.ps1')
$failures = [System.Collections.Generic.List[string]]::new()
$runtimeVersion = (Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'hermes-aec-runtime.version')).Trim()
$desktop = [Environment]::GetFolderPath('Desktop')
$hermesCommand = Get-Command hermes -ErrorAction SilentlyContinue
$bundledHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$hermes = if ($hermesCommand) { $hermesCommand.Source } elseif (Test-Path $bundledHermes) { $bundledHermes } else { $null }

function Test-NativeWindowsArm64 {
  $candidates = @($env:PROCESSOR_ARCHITEW6432, $env:PROCESSOR_ARCHITECTURE)
  try { $candidates += (Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name PROCESSOR_ARCHITECTURE -ErrorAction Stop).PROCESSOR_ARCHITECTURE } catch {}
  try { $candidates += (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).OSArchitecture } catch {}
  return [bool]($candidates | Where-Object { $_ -match '(?i)^ARM64$|ARM\s*64' } | Select-Object -First 1)
}

$checks = [ordered]@{
  'Rhino 8' = Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe'
  'Hermes' = [bool]$hermes
  'Hermes Desktop UI' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\apps\desktop\release\win-arm64-unpacked\Hermes.exe')
  'Full-build profile' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\profiles\cliff-house-full-build-windows\config.yaml')
  'Modification profile' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\profiles\cliff-house-modifications-windows\config.yaml')
  'Daystrom DML runtime' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml\.venv-dml\Scripts\python.exe')
  "Hermes AEC runtime $runtimeVersion" = Test-Path (Join-Path $env:LOCALAPPDATA "hermes\integrations\hermes-aec-runtime\$runtimeVersion\.venv\Scripts\hermes-aec-mcp.exe")
  'Full-build memory seed' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml\stores\cliff-house-full-build-windows\.aec-seed.json')
  'Modification memory seed' = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\daystrom-dml\stores\cliff-house-modifications-windows-bounded-v2\.aec-seed.json')
  'AEC Full Build shortcut' = Test-Path (Join-Path $desktop 'AEC Full Build.lnk')
  'AEC House Modification shortcut' = Test-Path (Join-Path $desktop 'AEC House Modification.lnk')
  'Full-build source model' = Test-Path (Join-Path $PSScriptRoot 'cliff_house_full_build\projects\cliff_house_02\rhino_assets\base_model.3dm')
  'Quick-demo golden master' = Test-Path (Join-Path $PSScriptRoot 'cliff_house_modifications\demo\cliff-house\cliff_house_GOLDEN_MASTER.3dm')
}

foreach ($item in $checks.GetEnumerator()) {
  Write-Host ("{0,-5} {1}" -f $(if ($item.Value) { 'PASS' } else { 'FAIL' }), $item.Key)
  if (-not $item.Value) { $failures.Add($item.Key) }
}

if ($hermes) {
  foreach ($profile in @('cliff-house-full-build-windows')) {
    & $hermes -p $profile mcp test daystrom_dml *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "PASS  Daystrom DML via $profile" }
    else { Write-Host "FAIL  Daystrom DML via $profile"; $failures.Add("Daystrom DML via $profile") }
  }
  foreach ($profile in @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')) {
    & $hermes -p $profile mcp test hermes_aec *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "PASS  Hermes AEC runtime via $profile" }
    else { Write-Host "FAIL  Hermes AEC runtime via $profile"; $failures.Add("Hermes AEC runtime via $profile") }
  }
}

$statePath = Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\deployment.json'
if (Test-Path $statePath) {
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  if ($state.blender_enabled) {
    $pinnedBlender = if ($state.blender_executable -and (Test-Path -LiteralPath $state.blender_executable)) { Get-BlenderVersionString -Executable $state.blender_executable } else { $null }
    $managedPathMatches = $state.blender_executable -and ([IO.Path]::GetFullPath($state.blender_executable) -eq [IO.Path]::GetFullPath($ManagedBlenderExecutable))
    if ($state.blender_version -eq $RequiredBlenderVersion -and $pinnedBlender -eq $RequiredBlenderVersion -and $managedPathMatches) { Write-Host "PASS  Managed per-user Blender pin $RequiredBlenderVersion at $($state.blender_executable)" }
    else { Write-Host "FAIL  Blender must be pinned to $RequiredBlenderVersion"; $failures.Add("Blender $RequiredBlenderVersion pin") }
    $expectedHdris = @(
      @{ File = 'quadrangle_cloudy_2k.hdr'; Sha256 = '0278DD3217CD001728C0B9BA42515BBD8A0063C28F498D73ACBA0A461BD14D90' },
      @{ File = 'safari_sunset_2k.hdr'; Sha256 = '31A938E0DF1660752C2BCA5D2F3FF4419ADEACE482BC06D68C0C7E5B32AA45AF' },
      @{ File = 'studio_small_02_2k.hdr'; Sha256 = '1CCB8B66F93865832C14DA8E0231971B36E09E7D284CEA752A575EDDB4B99694' }
    )
    $hdriRootMatches = $state.blender_hdri_root -and ([IO.Path]::GetFullPath($state.blender_hdri_root) -eq [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-hdri\polyhaven-2k')))
    $hdriValid = [bool]$hdriRootMatches
    if ($state.blender_hdri_root) {
      foreach ($hdri in $expectedHdris) {
        $hdriPath = Join-Path $state.blender_hdri_root $hdri.File
        if (-not (Test-Path -LiteralPath $hdriPath) -or (Get-FileHash -LiteralPath $hdriPath -Algorithm SHA256).Hash -ne $hdri.Sha256) { $hdriValid = $false }
      }
    }
    if ($hdriValid) { Write-Host 'PASS  Managed Blender HDRI presets daylight, golden_hour, studio' }
    else { Write-Host 'FAIL  Managed Blender HDRI library'; $failures.Add('Blender HDRI library') }
    $blenderLauncher = Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-mcp\blender-mcp.cmd'
    if (Test-Path $blenderLauncher) { Write-Host 'PASS  Opted-in BlenderMCP launcher' } else { Write-Host 'FAIL  Opted-in BlenderMCP launcher'; $failures.Add('BlenderMCP launcher') }
    foreach ($profile in @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')) {
      $configPath = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\config.yaml"
      $configText = if (Test-Path -LiteralPath $configPath) { Get-Content -Raw -LiteralPath $configPath } else { '' }
      if ($configText -match '(?m)^\s*- blender_render_archviz\s*$') { Write-Host "PASS  Deterministic Blender render registered in $profile" }
      else { Write-Host "FAIL  Deterministic Blender render missing from $profile"; $failures.Add("Blender render tool in $profile") }
      if ($configText -match '(?m)^\s*- blender_list_hdri_files\s*$') { Write-Host "PASS  Blender HDRI listing registered in $profile" }
      else { Write-Host "FAIL  Blender HDRI listing missing from $profile"; $failures.Add("Blender HDRI listing tool in $profile") }
      if ($configText -match '(?m)^\s*HERMES_AEC_HDRI_ROOT:\s*.+blender-hdri/polyhaven-2k\s*$') { Write-Host "PASS  Managed HDRI root registered in $profile" }
      else { Write-Host "FAIL  Managed HDRI root missing from $profile"; $failures.Add("Blender HDRI root in $profile") }
    }
    $blenderListener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.blender_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($blenderListener) {
      $markerPath = Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-mcp\active-instance.json'
      try { $marker = Get-Content -Raw -LiteralPath $markerPath -ErrorAction Stop | ConvertFrom-Json } catch { $marker = $null }
      $listenerProcess = Get-Process -Id $blenderListener.OwningProcess -ErrorAction SilentlyContinue
      try { $listenerPath = $listenerProcess.Path } catch { $listenerPath = $null }
      if ($marker -and $marker.process_id -eq $blenderListener.OwningProcess -and $listenerPath -and [IO.Path]::GetFullPath($listenerPath) -eq [IO.Path]::GetFullPath($ManagedBlenderExecutable)) { Write-Host "PASS  Managed BlenderMCP instance ownership PID $($marker.process_id)" }
      else { Write-Host 'FAIL  BlenderMCP listener and managed instance marker disagree'; $failures.Add('BlenderMCP instance ownership') }
    } else { Write-Host 'WARN  BlenderMCP is installed but Blender is not running.' }
  } else { Write-Host 'SKIP  Blender was not selected during deployment.' }
  if ($state.comfyui_enabled) {
    $comfyLauncher = Join-Path $env:LOCALAPPDATA 'hermes\integrations\comfyui-aec\Start-AEC-ComfyUI.cmd'
    $comfyController = Join-Path $env:LOCALAPPDATA 'hermes\integrations\comfyui-aec\Start-AEC-ComfyUI.ps1'
    $comfyLaunchState = Join-Path $env:LOCALAPPDATA 'hermes\integrations\comfyui-aec\comfyui-launch.json'
    if ((Test-Path $comfyLauncher) -and (Test-Path $comfyController) -and (Test-Path $comfyLaunchState)) { Write-Host 'PASS  Managed ComfyUI autostart controller and FLUX bundle' } else { Write-Host 'FAIL  Managed ComfyUI autostart controller'; $failures.Add('ComfyUI autostart controller') }
    foreach ($profile in @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')) {
      $configPath = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\config.yaml"
      $configText = if (Test-Path -LiteralPath $configPath) { Get-Content -Raw -LiteralPath $configPath } else { '' }
      if ($configText -match '(?m)^\s*- comfyui_health\s*$' -and $configText -match '(?m)^\s*- comfyui_stylize_image\s*$') { Write-Host "PASS  ComfyUI tools registered in $profile" }
      else { Write-Host "FAIL  ComfyUI tools missing from $profile"; $failures.Add("ComfyUI tools in $profile") }
    }
    $isArm64 = Test-NativeWindowsArm64
    $comfyRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\comfyui-aec'
    if ($isArm64) {
      $wslStatePath = Join-Path $comfyRoot 'wsl-initialization.json'
      $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
      $wslState = if (Test-Path -LiteralPath $wslStatePath) { Get-Content -Raw -LiteralPath $wslStatePath | ConvertFrom-Json } else { $null }
      if ($wslCommand -and $wslState.status -eq 'ready' -and $wslState.distribution) {
        $kernel = ((& $wslCommand.Source -d $wslState.distribution -u root -- uname -r 2>$null | Select-Object -First 1) -replace "`0", '').Trim()
        $release = ((& $wslCommand.Source -d $wslState.distribution -u root -- cat /etc/os-release 2>$null) -join "`n")
        & $wslCommand.Source -d $wslState.distribution -u root -- id -u nvidia *> $null
        if ($LASTEXITCODE -eq 0 -and $kernel -match '(?i)WSL2' -and $release -match '(?m)^VERSION_ID="?24\.04"?\s*$') { Write-Host "PASS  WSL2 Ubuntu 24.04 ARM64 appliance ($($wslState.distribution))" }
        else { Write-Host 'FAIL  WSL2 Ubuntu appliance sanity check'; $failures.Add('WSL2 Ubuntu appliance') }
      } else { Write-Host 'FAIL  WSL2 Ubuntu initialization state'; $failures.Add('WSL2 Ubuntu initialization state') }
    }
    $modelsRoot = if ($isArm64) { Join-Path $comfyRoot 'models' } else { Join-Path $comfyRoot 'portable\ComfyUI_windows_portable\ComfyUI\models' }
    foreach ($model in @(
      @{ Relative = 'diffusion_models\flux-2-klein-base-4b-fp8.safetensors'; Minimum = 4000000000 },
      @{ Relative = 'text_encoders\qwen_3_4b.safetensors'; Minimum = 8000000000 },
      @{ Relative = 'vae\flux2-vae.safetensors'; Minimum = 300000000 }
    )) {
      $path = Join-Path $modelsRoot $model.Relative
      if ((Test-Path -LiteralPath $path) -and (Get-Item -LiteralPath $path).Length -ge $model.Minimum) { Write-Host "PASS  ComfyUI model $($model.Relative)" }
      else { Write-Host "FAIL  ComfyUI model $($model.Relative)"; $failures.Add("ComfyUI model $($model.Relative)") }
    }
    try { $comfyStats = Invoke-RestMethod -UseBasicParsing -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 5 } catch { $comfyStats = $null }
    if (-not $comfyStats) {
      Write-Host 'WARN  ComfyUI is installed but not running; launch a demo to exercise it.'
    } else {
      $comfyText = $comfyStats | ConvertTo-Json -Depth 10
      if ($comfyText -match '(?i)cuda' -and $comfyText -match '(?i)nvidia') { Write-Host 'PASS  ComfyUI reports NVIDIA CUDA' }
      else { Write-Host 'FAIL  ComfyUI does not report NVIDIA CUDA'; $failures.Add('ComfyUI CUDA backend') }
      if ($isArm64 -and ($comfyStats.system.os -ne 'linux' -or $comfyStats.system.pytorch_version -notmatch '\+cu130')) {
        Write-Host 'FAIL  ARM64 ComfyUI is not the native WSL2 CUDA 13 backend'; $failures.Add('ARM64 ComfyUI backend')
      } elseif ($isArm64) { Write-Host 'PASS  Native ARM64 WSL2 CUDA 13 ComfyUI backend' }
    }
  } else { Write-Host 'SKIP  ComfyUI was not selected during deployment.' }
  $listener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.rhino_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  $owner = if ($listener) { Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue } else { $null }
  if ($owner -and $owner.ProcessName -eq 'Rhino') {
    Write-Host "PASS  RhinoMCP direct listener on port $($state.rhino_port), Rhino PID $($owner.Id)"
  } else {
    Write-Host "WARN  RhinoMCP is not owned by Rhino on loopback port $($state.rhino_port). Run AECMCPStart in Rhino before a demo."
  }
} else {
  Write-Host 'FAIL  Deployment state is missing.'
  $failures.Add('Deployment state')
}

$hermesCli = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
foreach ($profile in @('cliff-house-full-build-windows', 'cliff-house-modifications-windows')) {
  if (-not (Test-Path -LiteralPath $hermesCli)) { Write-Host 'FAIL  Hermes CLI inference validation'; $failures.Add('Hermes CLI inference validation'); break }
  try {
    . (Join-Path $PSScriptRoot 'inference\Inference.ps1')
    Assert-AECInference -Profile $profile -HermesCli $hermesCli | Out-Null
    Write-Host "PASS  Configured inference provider and model resolve in $profile"
  } catch {
    Write-Host "FAIL  Inference provider/model resolution in $profile"
    $failures.Add("Inference provider/model: $profile")
  }
}

if ($failures.Count) { Write-Host "AEC_DEPLOYMENT_FAIL count=$($failures.Count)"; exit 1 }
Write-Host 'AEC_DEPLOYMENT_PASS'
