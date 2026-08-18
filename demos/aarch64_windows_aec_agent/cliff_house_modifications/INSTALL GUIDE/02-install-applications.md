# Step 2 — Install the applications

Install the supported Windows applications. The repository script validates them without changing
Hermes configuration.

## Option A: guided bootstrap

From the repository root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\installer\Install-LocalAEC.ps1
```

The script performs read-only discovery. It does not install or launch Hermes, create a profile,
or configure inference and MCP.

## Option B: install applications manually

1. Install [Hermes Desktop for Windows](https://hermes-agent.nousresearch.com/).
2. Install Rhino 8 from McNeel and activate the license.
3. Install [Blender for Windows](https://www.blender.org/download/).
4. Do not install ComfyUI Desktop on Windows ARM64. When ComfyUI is selected,
   `Deploy-AECDemos.ps1` enables and validates WSL2, installs Ubuntu 24.04, creates the isolated
   `nvidia` demo account, and installs the supported native CUDA 13 ComfyUI environment.

## Confirm application discovery

```powershell
Get-Command "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe"
Test-Path 'C:\Program Files\Rhino 8\System\Rhino.exe'
Get-ChildItem 'C:\Program Files\Blender Foundation' -Filter blender.exe -Recurse
```

Expected result: each command returns a path or `True`.

## Next step

Continue to [configure MCP servers](03-configure-mcp-servers.md).
