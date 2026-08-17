[CmdletBinding()]
param(
  [ValidateSet('cliff-house-modifications-windows', 'cliff-house-full-build-windows')]
  [string]$Profile = 'cliff-house-modifications-windows',
  [ValidateRange(5, 120)][int]$TimeoutSeconds = 60
)

$ErrorActionPreference = 'Stop'
$model = 'switchyard/openai/gpt-5.6-sol'
$uri = 'https://inference-api.nvidia.com/v1/responses'
$envFile = Join-Path $env:LOCALAPPDATA "hermes\profiles\$Profile\.env"
if (-not (Test-Path -LiteralPath $envFile)) {
  throw "Profile '$Profile' is not deployed. Run Deploy-AECDemos.ps1 first."
}

$keyLine = Get-Content -LiteralPath $envFile |
  Where-Object { $_ -match '^NVIDIA_API_KEY=.+' } |
  Select-Object -First 1
if (-not $keyLine) {
  throw "NVIDIA_API_KEY is missing from profile '$Profile'. Rerun Deploy-AECDemos.ps1."
}
$key = $keyLine.Substring('NVIDIA_API_KEY='.Length).Trim()
if ([string]::IsNullOrWhiteSpace($key)) { throw "NVIDIA_API_KEY is empty in profile '$Profile'." }

$body = @{
  model = $model
  input = 'Reply with the single word READY.'
  max_output_tokens = 16
} | ConvertTo-Json -Compress
$headers = @{ Authorization = "Bearer $key" }
$timer = [Diagnostics.Stopwatch]::StartNew()
try {
  $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType 'application/json' -Body $body -TimeoutSec $TimeoutSeconds
} catch {
  $status = if ($_.Exception.Response -and $_.Exception.Response.StatusCode) { [int]$_.Exception.Response.StatusCode } else { 0 }
  throw "Inference endpoint failed (HTTP $status). See INFERENCE_ENDPOINT.md. $($_.Exception.Message)"
} finally {
  $key = $null
  $headers = $null
}
$timer.Stop()
if (-not $response.id -and -not $response.output) { throw 'Inference endpoint returned an unexpected Responses payload.' }
Write-Host "INFERENCE_ENDPOINT_PASS model=$model profile=$Profile latency_ms=$([math]::Round($timer.Elapsed.TotalMilliseconds))"
