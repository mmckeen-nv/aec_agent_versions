[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('FullBuild', 'Modification')][string]$Demo)

$ErrorActionPreference = 'Stop'
$logRoot = Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\logs'
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null
$logPath = Join-Path $logRoot ("launch-$($Demo.ToLower())-$(Get-Date -Format 'yyyyMMdd').log")
function Write-LaunchLog([string]$Message) {
  Add-Content -LiteralPath $logPath -Encoding UTF8 -Value ("{0} {1}" -f (Get-Date).ToUniversalTime().ToString('o'), $Message)
}
trap {
  $message = $_.Exception.Message
  Write-LaunchLog "FAILED $message"
  Write-Host ''
  Write-Host 'AEC_DEMO_LAUNCH_FAILED' -ForegroundColor Red
  Write-Host $message -ForegroundColor Red
  Write-Host "Launch log: $logPath" -ForegroundColor Yellow
  Read-Host 'Press Enter to close this window' | Out-Null
  exit 1
}
. (Join-Path $PSScriptRoot 'optional\Blender-Pin.ps1')
Write-LaunchLog "START demo=$Demo"

$state = Get-Content -Raw -LiteralPath (Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\deployment.json') | ConvertFrom-Json
$desktopHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\apps\desktop\release\win-arm64-unpacked\Hermes.exe'
if (-not (Test-Path $desktopHermes)) { throw 'Hermes Desktop is not installed.' }
$hermesCli = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
if (-not (Test-Path $hermesCli)) { throw 'Hermes CLI is not installed.' }
$existingHermes = Get-Process Hermes -ErrorAction SilentlyContinue | Where-Object {
  try { $_.Path -eq $desktopHermes } catch { $false }
}
if ($existingHermes) {
  throw 'Hermes Desktop is already running. Close every Hermes window completely, then launch the demo shortcut again so it can start the correct isolated profile.'
}

$rhino = 'C:\Program Files\Rhino 8\System\Rhino.exe'
if (-not (Test-Path $rhino)) { throw 'Rhino 8 is not installed.' }

if ($state.blender_enabled) {
  if ($state.blender_version -ne $RequiredBlenderVersion -or -not $state.blender_executable) {
    throw "Deployment state does not pin Blender $RequiredBlenderVersion. Rerun Deploy-AECDemos.cmd to repair it."
  }
  if (-not (Test-Path -LiteralPath $state.blender_executable)) { throw "Pinned Blender executable is missing: $($state.blender_executable). Rerun deployment." }
  if ([IO.Path]::GetFullPath($state.blender_executable) -ne [IO.Path]::GetFullPath($ManagedBlenderExecutable)) { throw 'Deployment state points outside the managed per-user Blender installation. Rerun deployment.' }
  $actualBlenderVersion = Get-BlenderVersionString -Executable $state.blender_executable
  if ($actualBlenderVersion -ne $RequiredBlenderVersion) { throw "Pinned Blender executable reports version '$actualBlenderVersion'; version $RequiredBlenderVersion is required. Rerun deployment." }
  $blender = Get-Item -LiteralPath $state.blender_executable
  $blenderMarkerPath = Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-mcp\active-instance.json'
  $existingBlenderListener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.blender_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $existingBlenderListener -and -not (Get-Process blender -ErrorAction SilentlyContinue)) {
    Remove-Item -LiteralPath $blenderMarkerPath -Force -ErrorAction SilentlyContinue
    $env:DISABLE_TELEMETRY = 'true'
    Start-Process -FilePath $blender.FullName
  } elseif (-not $existingBlenderListener) {
    throw 'Blender is already open without the managed MCP listener. Save that work, close every Blender window, and launch the demo again; the demo will start one managed instance.'
  }
  # Blender 5.x can spend several minutes on first-run extension discovery and
  # shader/cache initialization before its startup timer runs.
  $blenderDeadline = (Get-Date).AddMinutes(4)
  do {
    Start-Sleep -Seconds 2
    $blenderReady = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.blender_port -State Listen -ErrorAction SilentlyContinue
  } while (-not $blenderReady -and (Get-Date) -lt $blenderDeadline)
  if (-not $blenderReady) { throw 'Blender opened, but the managed BlenderMCP server did not start on port 9876 within four minutes. In Blender, enable Interface: Blender MCP and click Start MCP Server.' }
  $markerDeadline = (Get-Date).AddSeconds(15)
  do {
    Start-Sleep -Milliseconds 500
    try { $blenderMarker = Get-Content -Raw -LiteralPath $blenderMarkerPath -ErrorAction Stop | ConvertFrom-Json } catch { $blenderMarker = $null }
  } while ((-not $blenderMarker -or $blenderMarker.process_id -ne $blenderReady.OwningProcess) -and (Get-Date) -lt $markerDeadline)
  if (-not $blenderMarker -or $blenderMarker.process_id -ne $blenderReady.OwningProcess) {
    throw "Blender MCP ownership is ambiguous. Listener owner is PID $($blenderReady.OwningProcess), but the managed instance marker does not match. Save Blender work, close all Blender windows, and relaunch the demo."
  }
  $blenderProcess = Get-Process -Id $blenderMarker.process_id -ErrorAction SilentlyContinue
  if (-not $blenderProcess -or $blenderProcess.ProcessName -ne 'blender') { throw 'The managed Blender MCP owner is no longer running.' }
  try { $blenderOwnerPath = $blenderProcess.Path } catch { $blenderOwnerPath = $null }
  if (-not $blenderOwnerPath -or [IO.Path]::GetFullPath($blenderOwnerPath) -ne [IO.Path]::GetFullPath($ManagedBlenderExecutable)) {
    throw "Blender MCP is owned by an unmanaged Blender executable: '$blenderOwnerPath'. Close all Blender windows and relaunch the demo."
  }
  Write-LaunchLog "BLENDER_READY port=$($state.blender_port) owner=$($blenderReady.OwningProcess) marker=$blenderMarkerPath"
}

if ($state.comfyui_enabled) {
  $comfyRoot = Join-Path $env:LOCALAPPDATA 'hermes\integrations\comfyui-aec'
  $comfyController = Join-Path $comfyRoot 'Start-AEC-ComfyUI.ps1'
  $comfyControllerLog = Join-Path $comfyRoot 'comfyui-controller.log'
  if (-not (Test-Path -LiteralPath $comfyController)) { throw 'ComfyUI was enabled, but its managed startup controller is missing. Rerun deployment with -Force.' }
  $comfyStarter = $null
  if (-not (Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort 8188 -State Listen -ErrorAction SilentlyContinue)) {
    $comfyArguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File `"$comfyController`" -WaitSeconds 420"
    $comfyStarter = Start-Process -FilePath powershell.exe -ArgumentList $comfyArguments -WindowStyle Hidden -PassThru
    Write-LaunchLog "COMFYUI_AUTOSTART_REQUESTED controller_pid=$($comfyStarter.Id)"
  }
  $comfyDeadline = (Get-Date).AddMinutes(7.5)
  do {
    Start-Sleep -Seconds 3
    try { $comfyReady = Invoke-RestMethod -UseBasicParsing -Uri 'http://127.0.0.1:8188/system_stats' -TimeoutSec 5 } catch { $comfyReady = $null }
    if ($comfyStarter -and $comfyStarter.HasExited -and -not $comfyReady) { break }
  } while (-not $comfyReady -and (Get-Date) -lt $comfyDeadline)
  if (-not $comfyReady) {
    $detail = if (Test-Path -LiteralPath $comfyControllerLog) { (Get-Content -LiteralPath $comfyControllerLog -Tail 30 -ErrorAction SilentlyContinue) -join ' | ' } else { 'controller log was not created' }
    throw "Managed ComfyUI did not become ready on port 8188. $detail"
  }
  $comfyHealthText = $comfyReady | ConvertTo-Json -Depth 10
  if ($comfyHealthText -notmatch '(?i)cuda' -or $comfyHealthText -notmatch '(?i)nvidia') { throw 'Managed ComfyUI is online but did not report an NVIDIA CUDA device.' }
  Write-LaunchLog "COMFYUI_READY port=8188"
}

function Test-RhinoMCPReady {
  param([int]$ExpectedOwnerPid = 0)
  $listener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.rhino_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $listener) { return $false }
  $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
  if (-not $owner -or $owner.ProcessName -ne 'Rhino') { return $false }
  if ($ExpectedOwnerPid -gt 0 -and $listener.OwningProcess -ne $ExpectedOwnerPid) { return $false }
  return $true
}

$expectedRhinoPid = 0
if ($Demo -eq 'FullBuild') {
  $profile = 'cliff-house-full-build-windows'
  $workspace = Join-Path $PSScriptRoot 'cliff_house_full_build'
  if (-not (Get-Process Rhino -ErrorAction SilentlyContinue)) { Start-Process -FilePath $rhino }
} else {
  $profile = 'cliff-house-modifications-windows'
  $workspace = Join-Path $PSScriptRoot 'cliff_house_modifications'
  $working = & (Join-Path $workspace 'installer\New-WorkingCopy.ps1') -PassThru
  $rhinoProcess = Start-Process -FilePath $rhino -ArgumentList "`"$working`"" -PassThru

  # Rhino executes /runscript before a document finishes opening, and opening
  # the document then tears down the listener. Wait for the actual document
  # window before starting MCP so Hermes never observes that transient port.
  $documentStem = [IO.Path]::GetFileNameWithoutExtension($working)
  $uiDeadline = (Get-Date).AddSeconds(90)
  $documentProcess = $null
  do {
    Start-Sleep -Seconds 1
    # Rhino may delegate the file-open request to an existing process, making
    # the PID returned by Start-Process a short-lived bootstrapper. Locate the
    # real document window by its unique timestamped working-copy filename.
    $documentProcess = Get-Process Rhino -ErrorAction SilentlyContinue |
      Where-Object { $_.MainWindowHandle -ne 0 -and $_.Responding -and $_.MainWindowTitle -like "*$documentStem*" } |
      Select-Object -First 1
    if (-not $documentProcess -and -not $rhinoProcess.HasExited) {
      $rhinoProcess.Refresh()
      if ($rhinoProcess.MainWindowHandle -ne 0 -and $rhinoProcess.Responding) { $documentProcess = $rhinoProcess }
    }
  } while (-not $documentProcess -and (Get-Date) -lt $uiDeadline)
  if (-not $documentProcess) {
    throw "Rhino started but the '$documentStem' document window did not become ready within 90 seconds."
  }
  $expectedRhinoPid = $documentProcess.Id
  Write-LaunchLog "RHINO_DOCUMENT_READY pid=$($documentProcess.Id) title=$($documentProcess.MainWindowTitle)"
  Start-Sleep -Seconds 3
  if (-not ('AECWinFocus' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class AECWinFocus {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@
  }
  $shell = New-Object -ComObject WScript.Shell
  $focusDeadline = (Get-Date).AddSeconds(30)
  $activated = $false
  do {
    [AECWinFocus]::ShowWindow($documentProcess.MainWindowHandle, 9) | Out-Null
    $activated = [bool]$shell.AppActivate($documentProcess.Id)
    if (-not $activated) { $activated = [AECWinFocus]::SetForegroundWindow($documentProcess.MainWindowHandle) }
    if (-not $activated) { Start-Sleep -Milliseconds 500 }
  } while (-not $activated -and -not (Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid) -and (Get-Date) -lt $focusDeadline)
  if (-not $activated -and -not (Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid)) {
    throw "Could not activate the Rhino window for '$documentStem' after 30 seconds, so AECMCPStart could not be sent safely."
  }
  Write-LaunchLog "RHINO_ACTIVATION activated=$activated mcp_already_ready=$(Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid)"
  if (-not (Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid)) {
    $shell.SendKeys('{ESC}')
    $shell.SendKeys('AECMCPStart{ENTER}')
  }

  # Opening a document can restart Rhino MCP. Do not expose Hermes to an
  # empty/stale document or a listener that is still cycling.
  $deadline = (Get-Date).AddSeconds(90)
  $stableChecks = 0
  do {
    Start-Sleep -Seconds 1
    $listening = Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid
    if ($listening) { $stableChecks++ } else { $stableChecks = 0 }
  } while ($stableChecks -lt 3 -and (Get-Date) -lt $deadline)
  if ($stableChecks -lt 3) {
    throw "Rhino opened the working copy, but MCP did not become stable on port $($state.rhino_port) within 90 seconds."
  }
}

if (-not (Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid)) {
  $deadline = (Get-Date).AddSeconds(90)
  do { Start-Sleep -Seconds 1 } while (-not (Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid) -and (Get-Date) -lt $deadline)
  if (-not (Test-RhinoMCPReady -ExpectedOwnerPid $expectedRhinoPid)) {
    throw "AEC RhinoMCP is not ready in the expected Rhino process on loopback port $($state.rhino_port). Close duplicate Rhino processes and retry; AECMCPStart is available only as a manual repair command."
  }
}

# Select the profile through Hermes itself. The packaged Electron executable
# silently ignores CLI profile arguments. Current Desktop releases also keep
# their own active-profile.json preference, which wins over the legacy
# active_profile file written by `hermes profile use`; pin both selectors.
& $hermesCli profile use $profile
if ($LASTEXITCODE -ne 0) { throw "Could not activate Hermes profile '$profile'." }
$profileConfig = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\config.yaml"
$profileEnvironment = Join-Path $env:LOCALAPPDATA "hermes\profiles\$profile\.env"
if (-not (Test-Path -LiteralPath $profileConfig)) { throw "Hermes profile config is missing: $profileConfig" }
if (-not (Test-Path -LiteralPath $profileEnvironment) -or -not (Get-Content -LiteralPath $profileEnvironment | Where-Object { $_ -match '^NVIDIA_API_KEY=.+$' } | Select-Object -First 1)) {
  throw "NVIDIA_API_KEY is not configured for '$profile'. Run Change_API_Key.cmd and set the key, then retry."
}
$profileStatus = (& $hermesCli --profile $profile status 2>&1) -join "`n"
if ($LASTEXITCODE -ne 0 -or $profileStatus -notmatch '(?m)^\s*Provider:\s+custom:nvidia-switchyard\s*$' -or $profileStatus -notmatch '(?m)^\s*Model:\s+switchyard/openai/gpt-5\.6-sol\s*$') {
  throw "Hermes could not resolve the NVIDIA provider and model for '$profile'. Rerun Deploy-AECDemos.cmd before launching the demo."
}
$desktopProfilePath = Join-Path $env:APPDATA 'Hermes\active-profile.json'
$desktopProfileParent = Split-Path -Parent $desktopProfilePath
New-Item -ItemType Directory -Force -Path $desktopProfileParent | Out-Null
$desktopProfileTemporary = "$desktopProfilePath.$([guid]::NewGuid().ToString('N')).tmp"
try {
  $desktopProfileJson = @{ profile = $profile } | ConvertTo-Json
  [IO.File]::WriteAllText($desktopProfileTemporary, $desktopProfileJson + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
  Move-Item -LiteralPath $desktopProfileTemporary -Destination $desktopProfilePath -Force
} finally {
  if (Test-Path -LiteralPath $desktopProfileTemporary) { Remove-Item -LiteralPath $desktopProfileTemporary -Force }
}
$env:HERMES_PROFILE = $profile
$env:HERMES_DESKTOP_CWD = $workspace
Start-Process -FilePath $desktopHermes -WorkingDirectory $workspace
Write-LaunchLog "READY demo=$Demo profile=$profile provider=custom:nvidia-switchyard model=switchyard/openai/gpt-5.6-sol desktop_profile=$desktopProfilePath workspace=$workspace"
