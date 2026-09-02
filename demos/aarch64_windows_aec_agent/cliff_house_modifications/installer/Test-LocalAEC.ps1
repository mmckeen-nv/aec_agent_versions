[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'
$checks = [ordered]@{
  'Hermes binary' = (Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'))
  'Rhino 8' = (Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe')
}
$statePath = Join-Path $env:LOCALAPPDATA 'hermes\aec-demos\deployment.json'
if (Test-Path -LiteralPath $statePath) {
  $state = Get-Content -Raw -LiteralPath $statePath | ConvertFrom-Json
  if ($state.blender_enabled) { $checks['Managed Blender 5.2.0'] = Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\integrations\blender-5.2.0\blender.exe') }
}
$checks.GetEnumerator() | ForEach-Object { Write-Host ("{0} {1}" -f ($(if($_.Value){'PASS'}else{'FAIL'}), $_.Key)) }
if ($checks.Values -contains $false) { exit 1 }
Write-Host 'WINDOWS_AEC_PREREQUISITES_PASS oobe_configuration_unmodified=true'
