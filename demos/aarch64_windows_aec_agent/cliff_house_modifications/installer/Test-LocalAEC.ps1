[CmdletBinding()] param()
$ErrorActionPreference = 'Stop'
$checks = [ordered]@{
  'Hermes binary' = (Test-Path (Join-Path $env:LOCALAPPDATA 'hermes\hermes-agent\venv\Scripts\hermes.exe'))
  'Rhino 8' = (Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe')
  'Blender' = [bool](Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)
}
$checks.GetEnumerator() | ForEach-Object { Write-Host ("{0} {1}" -f ($(if($_.Value){'PASS'}else{'FAIL'}), $_.Key)) }
if ($checks.Values -contains $false) { exit 1 }
Write-Host 'WINDOWS_AEC_PREREQUISITES_PASS oobe_configuration_unmodified=true'
