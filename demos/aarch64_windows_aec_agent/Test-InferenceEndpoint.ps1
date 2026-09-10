[CmdletBinding()]
param(
  [ValidateSet('cliff-house-modifications-windows', 'cliff-house-full-build-windows')]
  [string]$Profile = 'cliff-house-modifications-windows',
  [ValidateRange(5, 120)][int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'inference\Inference.ps1')
$timer = [Diagnostics.Stopwatch]::StartNew()
$result = Invoke-AECInference -Payload @{ action = 'probe'; root = (Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile"); timeout = $TimeoutSeconds }
$timer.Stop()
Write-Host "INFERENCE_ENDPOINT_PASS model=$($result.model) mode=$($result.api_mode) profile=$Profile latency_ms=$([math]::Round($timer.Elapsed.TotalMilliseconds))"
