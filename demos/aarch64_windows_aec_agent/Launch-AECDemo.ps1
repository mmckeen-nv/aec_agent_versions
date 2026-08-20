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
Write-LaunchLog "START demo=$Demo"

$state = Get-Content -Raw -LiteralPath (Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\deployment.json') | ConvertFrom-Json
$desktopHermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\apps\desktop\release\win-arm64-unpacked\Hermes.exe'
if (-not (Test-Path $desktopHermes)) { throw 'Hermes Desktop is not installed.' }
$hermesCli = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
if (-not (Test-Path $hermesCli)) { throw 'Hermes CLI is not installed.' }

$rhino = 'C:\Program Files\Rhino 8\System\Rhino.exe'
if (-not (Test-Path $rhino)) { throw 'Rhino 8 is not installed.' }

if ($state.blender_enabled) {
  $blender = Get-ChildItem -LiteralPath 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
  if (-not $blender) { throw 'Blender was enabled during deployment but is no longer installed.' }
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
  $listener = Get-NetTCPConnection -LocalAddress 127.0.0.1 -LocalPort $state.rhino_port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $listener) { return $false }
  $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
  return [bool]($owner -and $owner.ProcessName -eq 'Rhino')
}

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
  } while (-not $activated -and (Get-Date) -lt $focusDeadline)
  if (-not $activated -and -not (Test-RhinoMCPReady)) {
    throw "Could not activate the Rhino window for '$documentStem' after 30 seconds, so AECMCPStart could not be sent safely."
  }
  Write-LaunchLog "RHINO_ACTIVATION activated=$activated mcp_already_ready=$(Test-RhinoMCPReady)"
  if (-not (Test-RhinoMCPReady)) {
    $shell.SendKeys('{ESC}')
    $shell.SendKeys('AECMCPStart{ENTER}')
  }

  # Opening a document can restart Rhino MCP. Do not expose Hermes to an
  # empty/stale document or a listener that is still cycling.
  $deadline = (Get-Date).AddSeconds(90)
  $stableChecks = 0
  do {
    Start-Sleep -Seconds 1
    $listening = Test-RhinoMCPReady
    if ($listening) { $stableChecks++ } else { $stableChecks = 0 }
  } while ($stableChecks -lt 3 -and (Get-Date) -lt $deadline)
  if ($stableChecks -lt 3) {
    throw "Rhino opened the working copy, but MCP did not become stable on port $($state.rhino_port) within 90 seconds."
  }
}

if (-not (Test-RhinoMCPReady)) {
  $deadline = (Get-Date).AddSeconds(90)
  do { Start-Sleep -Seconds 1 } while (-not (Test-RhinoMCPReady) -and (Get-Date) -lt $deadline)
  if (-not (Test-RhinoMCPReady)) {
    throw "AEC RhinoMCP is not ready on loopback port $($state.rhino_port). In Rhino run AECMCPStart, then click the shortcut again."
  }
}

# Select the profile through Hermes itself. The packaged Electron executable
# silently ignores CLI profile arguments and some releases do not inherit
# HERMES_PROFILE when they spawn their backend.
& $hermesCli profile use $profile
if ($LASTEXITCODE -ne 0) { throw "Could not activate Hermes profile '$profile'." }
$env:HERMES_PROFILE = $profile
$env:HERMES_DESKTOP_CWD = $workspace
Start-Process -FilePath $desktopHermes -WorkingDirectory $workspace
Write-LaunchLog "READY demo=$Demo profile=$profile workspace=$workspace"
