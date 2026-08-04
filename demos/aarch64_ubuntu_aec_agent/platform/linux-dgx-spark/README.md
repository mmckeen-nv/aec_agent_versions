# Linux / DGX Spark deployment assets

This directory contains the repeatable scripts and pinned configuration used by the
[DGX Spark installation playbook](../../INSTALL%20GUIDE/LINUX%20DGX%20SPARK/README.md).

## Validated architecture

```text
vLLM :8000  <- selectable ->  Hermes OOBE  ->  FreeCAD MCP :9875  ->  FreeCAD
                                      +---->  Blender MCP :9876  ->  Blender
ComfyUI :8188 (independent loopback CUDA service)
```

## Current state

| Component | State |
|---|---|
| vLLM / Qwen3.6 35B NVFP4 | Running and validated |
| Hermes | Installed; OOBE-first, provider/model selected by the user |
| FreeCAD 1.1.3 ARM64 | Installed |
| FreeCAD MCP | Installed; live GUI handshake pending |
| Migrated Cliff House FCStd and pool assets | Present |
| ComfyUI | CUDA generation validated; user service on 127.0.0.1:8188 |
| Blender 4.0.2 ARM64 | Installed; suitable for compatible/new scenes |
| Blender MCP 1.6.4 | Installed; GUI Connect action required per Blender session |
| Cliff House Blender 5.2 master | Blocked pending a reviewed Blender 5.x ARM64 build |

## Scripts

- `scripts/install-freecad.sh` installs the pinned FreeCAD ARM64 AppImage.
- `scripts/install-freecad-mcp.sh` installs the Python server and versioned FreeCAD workbench.
- `scripts/install-blender-mcp.sh` installs the pinned server/add-on pair without configuring Hermes.
- `scripts/reset-hermes-oobe.sh` recoverably resets mutable state without reinstalling Hermes.
- `scripts/install-hermes-oobe.sh` performs a pinned clean Hermes installation with no model selected.
- `scripts/install-comfyui.sh` installs the pinned NVIDIA GB10 route and user service.
- `scripts/verify-platform.sh` performs non-destructive platform checks.

The scripts are repairable and repeatable deployment helpers, not evidence of runtime success.
Use the playbook acceptance checks to record live results.
