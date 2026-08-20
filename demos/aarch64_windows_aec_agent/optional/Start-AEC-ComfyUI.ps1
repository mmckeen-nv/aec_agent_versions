[CmdletBinding()]
param([ValidateRange(30, 1800)][int]$WaitSeconds = 420)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$statePath = Join-Path $root 'comfyui-launch.json'
$controllerLog = Join-Path $root 'comfyui-controller.log'
$lockPath = Join-Path $root 'comfyui-start.lock'
$healthUri = 'http://127.0.0.1:8188/system_stats'

function Write-ControllerLog([string]$Message) {
  $line = "{0} {1}" -f (Get-Date).ToUniversalTime().ToString('o'), $Message
  Add-Content -LiteralPath $controllerLog -Encoding UTF8 -Value $line
  Write-Host $Message
}

trap {
  try { Write-ControllerLog "COMFYUI_AUTOSTART_FAILED $($_.Exception.Message)" } catch {}
  exit 1
}

function Get-ComfyHealth {
  try { return Invoke-RestMethod -UseBasicParsing -Uri $healthUri -TimeoutSec 5 } catch { return $null }
}

function Write-AtomicJson([string]$Path, [hashtable]$Value) {
  $temporary = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
  try {
    $json = $Value | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($temporary, $json + [Environment]::NewLine, (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
  } finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
  }
}

if (-not (Test-Path -LiteralPath $statePath)) { throw "ComfyUI launch metadata is missing: $statePath. Rerun deployment with ComfyUI enabled." }
$state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
if ($state.schema_version -ne 1 -or $state.port -ne 8188) { throw 'ComfyUI launch metadata is invalid.' }

$health = Get-ComfyHealth
if ($health) {
  Write-ControllerLog "COMFYUI_ALREADY_READY backend=$($state.backend) port=8188"
  exit 0
}

$lock = $null
$lockDeadline = (Get-Date).AddSeconds(30)
do {
  try { $lock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None') } catch { Start-Sleep -Milliseconds 500 }
} while (-not $lock -and (Get-Date) -lt $lockDeadline)
if (-not $lock) { throw 'Another ComfyUI startup controller held the launch lock for more than 30 seconds.' }

try {
  $health = Get-ComfyHealth
  if ($health) {
    Write-ControllerLog "COMFYUI_ALREADY_READY backend=$($state.backend) port=8188"
    exit 0
  }

  $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffffffZ')
  $stdout = Join-Path $root "comfyui-start-$stamp.stdout.log"
  $stderr = Join-Path $root "comfyui-start-$stamp.stderr.log"
  $process = $null
  if ($state.backend -eq 'wsl2-arm64-cu130') {
    $wsl = (Get-Command wsl.exe -ErrorAction Stop).Source
    if (-not $state.distribution -or -not $state.user -or -not $state.linux_root) { throw 'WSL2 ComfyUI launch metadata is incomplete.' }
    $process = Start-Process -FilePath $wsl -ArgumentList @(
      '-d', [string]$state.distribution, '-u', [string]$state.user, '--', "$($state.linux_root)/start-comfyui.sh"
    ) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
  } elseif ($state.backend -eq 'windows-portable') {
    [string]$executable = $state.executable
    if (-not (Test-Path -LiteralPath $executable)) { throw "ComfyUI executable is missing: $executable" }
    $process = Start-Process -FilePath $executable -ArgumentList @($state.arguments) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
  } else {
    throw "Unsupported ComfyUI backend in launch metadata: $($state.backend)"
  }

  $markerPath = Join-Path $root 'active-instance.json'
  Write-AtomicJson $markerPath @{
    schema_version = 1; backend = [string]$state.backend; port = 8188
    windows_process_id = $process.Id; started_at = (Get-Date).ToUniversalTime().ToString('o')
    stdout_log = $stdout; stderr_log = $stderr
  }
  Write-ControllerLog "COMFYUI_PROCESS_LAUNCHED pid=$($process.Id) backend=$($state.backend) port=8188"

  $deadline = (Get-Date).AddSeconds($WaitSeconds)
  do {
    Start-Sleep -Seconds 3
    $health = Get-ComfyHealth
    if ($process.HasExited -and -not $health) { break }
  } while (-not $health -and (Get-Date) -lt $deadline)

  if (-not $health) {
    foreach ($path in @($stdout, $stderr)) {
      if (Test-Path -LiteralPath $path) {
        Get-Content -LiteralPath $path -Tail 120 -ErrorAction SilentlyContinue | ForEach-Object { Write-ControllerLog "CHILD_LOG $_" }
      }
    }
    if ($state.backend -eq 'wsl2-arm64-cu130') {
      try {
        $wslTail = & wsl.exe -d $state.distribution -u $state.user -- tail -n 120 "$($state.linux_root)/comfyui.log" 2>$null
        $wslTail | ForEach-Object { Write-ControllerLog "WSL_LOG $_" }
      } catch {}
    }
    $exitDetail = if ($process.HasExited) { "child exit code $($process.ExitCode)" } else { "timeout after $WaitSeconds seconds" }
    throw "ComfyUI did not become ready on 127.0.0.1:8188 ($exitDetail). Review $controllerLog."
  }

  $healthText = $health | ConvertTo-Json -Depth 10
  if ($healthText -notmatch '(?i)cuda' -or $healthText -notmatch '(?i)nvidia') { throw 'ComfyUI started but did not report an NVIDIA CUDA device.' }
  Write-ControllerLog "COMFYUI_AUTOSTART_READY pid=$($process.Id) backend=$($state.backend) port=8188"
} finally {
  if ($lock) { $lock.Dispose() }
}
