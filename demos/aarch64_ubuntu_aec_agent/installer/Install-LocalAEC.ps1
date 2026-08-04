[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Profile = 'local-aec-cloud',
  [switch]$SkipApplications,
  [switch]$SkipComfyUI
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$hermesHome = Join-Path $env:LOCALAPPDATA 'hermes'
$profileDir = Join-Path $hermesHome "profiles\$Profile"

function Write-Step([string]$Text) { Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Require-Command([string]$Name) {
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $command) { throw "$Name is required but was not found." }
  $command.Source
}

Write-Step 'Check Windows prerequisites'
if ([Environment]::OSVersion.Platform -ne 'Win32NT') { throw 'This demo targets Windows 10 or 11.' }
$winget = Require-Command 'winget.exe'

if (-not $SkipApplications) {
  Write-Step 'Check Rhino 8 and install Blender when absent'
  if (-not (Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe')) {
    throw 'Rhino 8 is not available through winget. Install and license it from https://www.rhino3d.com/download/ and rerun.'
  }
  if (-not (Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue)) {
    & $winget install --id BlenderFoundation.Blender --exact --interactive --accept-source-agreements
  }
}

Write-Step 'Install Hermes Agent when absent'
$hermes = Join-Path $hermesHome 'hermes-agent\venv\Scripts\hermes.exe'
if (-not (Test-Path $hermes)) {
  & ([scriptblock]::Create((Invoke-RestMethod 'https://hermes-agent.nousresearch.com/install.ps1'))) -SkipSetup
}

Write-Step 'Install uv and Blender MCP'
if (-not (Get-Command uv.exe -ErrorAction SilentlyContinue)) {
  & $winget install --id astral-sh.uv --exact --accept-package-agreements --accept-source-agreements
}
$uv = (Get-Command uv.exe -ErrorAction SilentlyContinue).Source
if (-not $uv) { $uv = Join-Path $hermesHome 'bin\uv.exe' }
if (-not (Test-Path $uv)) { throw 'uv was not found after installation. Open a new terminal and rerun.' }
& $uv tool install --force --with 'mcp<2' blender-mcp

Write-Step 'Install Rhino MCP Platform 0.1.5'
$yak = 'C:\Program Files\Rhino 8\System\Yak.exe'
if (-not (Test-Path $yak)) { throw 'Rhino 8 Yak.exe is missing.' }
$routerRoot = Join-Path $env:APPDATA 'McNeel\Rhinoceros\packages\8.0\Rhino-MCP-Platform'
if (-not (Get-ChildItem $routerRoot -Filter rhino-mcp-router.exe -Recurse -File -ErrorAction SilentlyContinue)) {
  & $yak install Rhino-MCP-Platform 0.1.5
}

Write-Step 'Install the Blender MCP add-on from its upstream repository'
$addonUri = 'https://raw.githubusercontent.com/ahujasid/blender-mcp/main/addon.py'
$addonDir = Join-Path $env:APPDATA 'Blender Foundation\Blender\5.2\scripts\addons'
New-Item -ItemType Directory -Path $addonDir -Force | Out-Null
Invoke-WebRequest -UseBasicParsing $addonUri -OutFile (Join-Path $addonDir 'blender_mcp_addon.py')
$blender = Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File |
  Sort-Object FullName -Descending | Select-Object -First 1
if ($blender) {
  & $blender.FullName --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); bpy.ops.wm.save_userpref()"
}

if (-not $SkipComfyUI) {
  Write-Step 'Install ComfyUI Desktop'
  Write-Host 'Download the NVIDIA Windows build from https://www.comfy.org/download and select NVIDIA during initialization.'
  Write-Host 'ComfyUI remains an explicit GUI install because the upstream desktop installer manages CUDA and updates.'
}

Write-Step 'Create a secret-free Hermes profile template'
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
$template = Join-Path $repoRoot 'config\hermes\config.template.yaml'
$profileConfig = Join-Path $profileDir 'config.yaml'
if (-not (Test-Path $profileConfig)) {
  $router = Get-ChildItem $routerRoot -Filter rhino-mcp-router.exe -Recurse -File | Select-Object -First 1
  $blenderMcp = Join-Path $env:USERPROFILE '.local\bin\blender-mcp.exe'
  $content = (Get-Content $template -Raw).
    Replace('REPLACE_WITH_REPOSITORY_PATH', ($repoRoot -replace '\\','/')).
    Replace('REPLACE_WITH_RHINO_MCP_ROUTER_EXE', ($router.FullName -replace '\\','/')).
    Replace('REPLACE_WITH_BLENDER_MCP_EXE', ($blenderMcp -replace '\\','/'))
  [IO.File]::WriteAllText($profileConfig, $content, [Text.UTF8Encoding]::new($false))
}
Copy-Item (Join-Path $repoRoot 'config\hermes\AGENTS.md') (Join-Path $profileDir 'AGENTS.md') -Force

Write-Host "`nBootstrap complete. Edit: $profileConfig" -ForegroundColor Green
Write-Host "Then add AEC_ENDPOINT_API_KEY to $hermesHome\.env and run installer\Test-LocalAEC.ps1."
