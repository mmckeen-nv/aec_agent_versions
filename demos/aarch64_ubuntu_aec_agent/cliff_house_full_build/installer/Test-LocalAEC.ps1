[CmdletBinding()]
param(
  [string]$Profile = 'local-aec-cloud',
  [string]$ComfyUrl = 'http://127.0.0.1:8188'
)

$ErrorActionPreference = 'SilentlyContinue'
$results = [System.Collections.Generic.List[object]]::new()
function Add-Result([string]$Name, [bool]$Pass, [string]$Detail) {
  $results.Add([pscustomobject]@{ Component = $Name; Ready = $Pass; Detail = $Detail })
}

$hermes = Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'
$profilePath = Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile\config.yaml"
$rhino = 'C:\Program Files\Rhino 8\System\Rhino.exe'
$blender = Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File |
  Sort-Object FullName -Descending | Select-Object -First 1
$router = Get-ChildItem (Join-Path $env:APPDATA 'McNeel\Rhinoceros\packages\8.0\Rhino-MCP-Platform') `
  -Filter rhino-mcp-router.exe -Recurse -File | Select-Object -First 1
$blenderMcp = Join-Path $env:USERPROFILE '.local\bin\blender-mcp.exe'

Add-Result 'Hermes' (Test-Path $hermes) $hermes
Add-Result 'Hermes profile' (Test-Path $profilePath) $profilePath
Add-Result 'Cloud key' (-not [string]::IsNullOrWhiteSpace($env:AEC_ENDPOINT_API_KEY)) 'AEC_ENDPOINT_API_KEY in current environment'
Add-Result 'Rhino 8' (Test-Path $rhino) $rhino
Add-Result 'Rhino MCP router' ($null -ne $router) $(if ($router) { $router.FullName } else { 'not found' })
Add-Result 'Blender' ($null -ne $blender) $(if ($blender) { $blender.FullName } else { 'not found' })
Add-Result 'Blender MCP' (Test-Path $blenderMcp) $blenderMcp

try {
  $response = Invoke-WebRequest -UseBasicParsing -Uri "$ComfyUrl/system_stats" -TimeoutSec 3
  Add-Result 'ComfyUI' ($response.StatusCode -eq 200) "$ComfyUrl/system_stats"
} catch {
  Add-Result 'ComfyUI' $false "not reachable at $ComfyUrl"
}

$results | Format-Table -AutoSize
if ($results.Ready -contains $false) { exit 1 }
Write-Host 'LOCAL_AEC_STACK_PASS' -ForegroundColor Green
