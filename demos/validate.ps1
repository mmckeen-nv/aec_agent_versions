[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$demosRoot = $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

$packages = Get-ChildItem -LiteralPath $demosRoot -Directory | ForEach-Object {
  Get-ChildItem -LiteralPath $_.FullName -Directory -Filter 'cliff_house_*'
}

foreach ($required in @(
  'hermes-aec-runtime.version',
  'aarch64_windows_aec_agent\DEPLOY.md',
  'aarch64_windows_aec_agent\Deploy-AECDemos.ps1',
  'aarch64_windows_aec_agent\Launch-AECDemo.ps1',
  'aarch64_windows_aec_agent\Test-AECDeployment.ps1',
  'aarch64_windows_aec_agent\memory\Install-AECDml.ps1',
  'aarch64_windows_aec_agent\memory\dml.yaml',
  'aarch64_windows_aec_agent\memory\seed_dml.py',
  'aarch64_ubuntu_aec_agent\DEPLOY.md',
  'aarch64_ubuntu_aec_agent\deploy-aec-demos.sh',
  'aarch64_ubuntu_aec_agent\launch-aec-demo.sh',
  'aarch64_ubuntu_aec_agent\test-aec-deployment.sh',
  'aarch64_ubuntu_aec_agent\runtime\install-hermes-aec-runtime.sh',
  'aarch64_ubuntu_aec_agent\memory\install-aec-dml.sh',
  'aarch64_ubuntu_aec_agent\memory\dml.yaml',
  'aarch64_ubuntu_aec_agent\memory\seed_dml.py'
)) {
  if (-not (Test-Path -LiteralPath (Join-Path $demosRoot $required))) {
    $failures.Add("Missing platform deployment entrypoint: $required")
  }
}

$runtimePin = (Get-Content -Raw -LiteralPath (Join-Path $demosRoot 'hermes-aec-runtime.version')).Trim()
if ($runtimePin -notmatch '^v\d+\.\d+\.\d+$') {
  $failures.Add("Invalid Hermes AEC runtime pin: $runtimePin")
}
foreach ($script in @(
  'aarch64_windows_aec_agent\Deploy-AECDemos.ps1',
  'aarch64_windows_aec_agent\Test-AECDeployment.ps1',
  'aarch64_ubuntu_aec_agent\deploy-aec-demos.sh',
  'aarch64_ubuntu_aec_agent\test-aec-deployment.sh'
)) {
  $content = Get-Content -Raw -LiteralPath (Join-Path $demosRoot $script)
  if ($content -match "v0\.4\.1") { $failures.Add("Hard-coded runtime pin outside central file: $script") }
}

foreach ($template in @(
  'aarch64_ubuntu_aec_agent\cliff_house_full_build\config\hermes\config.template.yaml',
  'aarch64_ubuntu_aec_agent\cliff_house_modifications\config\hermes\config.template.yaml'
)) {
  $content = Get-Content -Raw -LiteralPath (Join-Path $demosRoot $template)
  if ($content -notmatch '(?m)^  hermes_aec:' -or $content -notmatch '__AEC_RUNTIME_SERVER__') {
    $failures.Add("Linux profile does not register Hermes AEC runtime: $template")
  }
}

foreach ($package in $packages) {
  foreach ($required in @('README.md', 'INSTALL GUIDE', 'installer')) {
    if (-not (Test-Path -LiteralPath (Join-Path $package.FullName $required))) {
      $failures.Add("$($package.FullName): missing $required")
    }
  }
}

$windowsFull = Join-Path $demosRoot 'aarch64_windows_aec_agent\cliff_house_full_build'
$sourceModel = Join-Path $windowsFull 'projects\cliff_house_02\rhino_assets\base_model.3dm'
$expectedHash = 'DDACAC2BA0CEA8DF75A1B02B9214C64BBCBF4B5D214E60C67DAC94A32E7272D0'
if (-not (Test-Path -LiteralPath $sourceModel)) {
  $failures.Add("Windows full build: missing upstream source model: $sourceModel")
} elseif ((Get-FileHash -LiteralPath $sourceModel -Algorithm SHA256).Hash -ne $expectedHash) {
  $failures.Add('Windows full build: source model hash does not match the pinned upstream revision')
}

foreach ($required in @(
  'UPSTREAM.md',
  'config\hermes\config.template.yaml',
  'installer\Deploy-HermesProfile.ps1',
  'projects\cliff_house_02\user_prompts\project_prompt.md',
  'projects\cliff_house_02\golden_build_contract.json',
  'system_prompts\00d_golden_master_contract.md',
  'scripts\validate_golden_contract.py'
)) {
  if (-not (Test-Path -LiteralPath (Join-Path $windowsFull $required))) {
    $failures.Add("Windows full build: missing $required")
  }
}

$linuxFull = Join-Path $demosRoot 'aarch64_ubuntu_aec_agent\cliff_house_full_build'
$linuxManifest = Join-Path $linuxFull 'projects\cliff_house_02\freecad_reference\source_curves.json'
foreach ($required in @(
  'UPSTREAM.md',
  'config\hermes\config.template.yaml',
  'platform\linux-dgx-spark\scripts\deploy-hermes-profile.sh',
  'projects\cliff_house_02\user_prompts\project_prompt.md',
  'scripts\extract_rhino_reference.py'
)) {
  if (-not (Test-Path -LiteralPath (Join-Path $linuxFull $required))) {
    $failures.Add("Linux full build: missing $required")
  }
}
if (-not (Test-Path -LiteralPath $linuxManifest)) {
  $failures.Add("Linux full build: missing source-curve manifest: $linuxManifest")
} else {
  $manifest = Get-Content -Raw -LiteralPath $linuxManifest | ConvertFrom-Json
  if ($manifest.source_sha256 -ne $expectedHash -or $manifest.objects.Count -ne 16) {
    $failures.Add('Linux full build: source-curve manifest does not match the pinned upstream model')
  }
}

$quickContracts = @(
  @{
    Name = 'Windows quick modifications'
    Root = Join-Path $demosRoot 'aarch64_windows_aec_agent\cliff_house_modifications'
    Master = 'demo\cliff-house\cliff_house_GOLDEN_MASTER.3dm'
    Hash = 'D7DB42D78B360C66D94E1E034C201EDD98EFF8F63F35B19C7995E7D1B63F4F7C'
    Required = @('AGENTS.md', 'config\hermes\config.template.yaml', 'installer\Deploy-HermesProfile.ps1', 'installer\New-WorkingCopy.ps1')
  },
  @{
    Name = 'Linux quick modifications'
    Root = Join-Path $demosRoot 'aarch64_ubuntu_aec_agent\cliff_house_modifications'
    Master = 'demo\cliff-house\cliff_house_FREECAD_MASTER.FCStd'
    Hash = 'B34C82FF5C2772740E7BC257F7D8164BABBED679D048D6265C81793AD0C23D8A'
    Required = @('AGENTS.md', 'config\hermes\config.template.yaml', 'platform\linux-dgx-spark\scripts\deploy-hermes-profile.sh', 'platform\linux-dgx-spark\scripts\prepare-working-copy.sh')
  }
)
foreach ($contract in $quickContracts) {
  foreach ($required in $contract.Required) {
    if (-not (Test-Path -LiteralPath (Join-Path $contract.Root $required))) {
      $failures.Add("$($contract.Name): missing $required")
    }
  }
  $master = Join-Path $contract.Root $contract.Master
  if (-not (Test-Path -LiteralPath $master)) {
    $failures.Add("$($contract.Name): missing protected master")
  } elseif ((Get-FileHash -LiteralPath $master -Algorithm SHA256).Hash -ne $contract.Hash) {
    $failures.Add("$($contract.Name): protected master hash mismatch")
  }
}

$trackedText = Get-ChildItem -LiteralPath $demosRoot -Recurse -File | Where-Object {
  $_.Extension -in @('.md', '.yaml', '.yml', '.json', '.ps1', '.py', '.sh', '.cmd', '.txt')
}
foreach ($file in $trackedText) {
  $content = Get-Content -Raw -LiteralPath $file.FullName
  if ($content -match 'sk-[A-Za-z0-9_-]{16,}') {
    $failures.Add("Potential committed API key: $($file.FullName)")
  }
}

if ($failures.Count) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Host "DEMO_PACKAGE_VALIDATION_PASS packages=$($packages.Count)"
