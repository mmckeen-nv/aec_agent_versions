# aarch64_windows_aec_agent

AEC agent workflows for Windows on ARM64 with Hermes Desktop, Rhino 8, Blender, and ComfyUI.
Hermes is always installed in OOBE state: the repository never selects an inference provider,
model, endpoint, credential, or active profile.

## Install once

Read the complete [requirements and test guide](DEPLOY.md), then run:

```powershell
.\Deploy-AECDemos.ps1
```

This creates **AEC Full Build** and **AEC House Modification** shortcuts on the Desktop.

## Workflows

| Workflow | Purpose | Starting point |
|---|---|---|
| [`cliff_house_modifications`](cliff_house_modifications/) | Fast, reversible edits for the live demo | Protected Rhino and Blender masters |
| [`cliff_house_full_build`](cliff_house_full_build/) | Original phase-driven Rhino → Blender → ComfyUI build | Empty Rhino document |

The workflows use separate Hermes projects and must be attached only after the operator completes
Hermes OOBE. Runtime profiles, sessions, credentials, logs, generated geometry, renders, ComfyUI
models, and application preferences stay on the workstation and are not repository content.
