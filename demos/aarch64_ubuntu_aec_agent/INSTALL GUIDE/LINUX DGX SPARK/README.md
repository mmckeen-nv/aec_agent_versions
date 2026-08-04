# Deploy the Local AEC Agent on DGX Spark

Run a local AEC agent on NVIDIA DGX Spark with vLLM inference, Hermes Agent, FreeCAD,
FreeCAD MCP, and an optional ComfyUI service. This Linux/ARM64 deployment replaces Rhino
with FreeCAD and uses the native NVIDIA CUDA stack.

## Deployment status

Status last verified on `spark-1ce2` on 2026-08-04. The acceptance run started from a
clean Hermes installation and did not import an existing Hermes profile.

| Component | State | Evidence |
|---|---|---|
| DGX Spark platform | **Validated** | Ubuntu 24.04, ARM64, NVIDIA GB10 |
| vLLM inference | **Validated** | Qwen3.6 35B NVFP4 listening on port 8000 |
| FreeCAD 1.1.3 | **Installed** | ARM64 AppImage under `~/.local/opt/freecad-1.1.3` |
| FreeCAD MCP | **Installed; GUI handshake deferred** | Server, workbench, and loopback settings present |
| Hermes | **OOBE ready** | No provider or model preselected |
| Cliff House model | **Validated** | STEP, FCStd, preview, pool shell, and pool water present |
| ComfyUI | **Validated** | CUDA 13 generation passed while vLLM remained healthy |
| Blender 4.0.2 | **Installed** | Works for compatible/new scenes |
| Blender MCP 1.6.4 | **Installed; connect pending** | Server and add-on installed; Hermes attachment deferred |
| Cliff House Blender 5.2 master | **Blocked** | No reviewed Blender 5.x ARM64 build pinned |

## What you will build

```text
vLLM :8000  <- selectable by user ->  Hermes OOBE
                                      +-> FreeCAD MCP (attach after setup)
                                      +-> Blender MCP (attach after setup)
                    |         |
                    |         +--------------------->  ComfyUI :8188 (loopback)
```

## Before you begin

- Use the graphical session for FreeCAD; its RPC bridge runs inside the GUI process.
- Run commands as the normal `nvidia` user unless a step explicitly uses `sudo`.
- Keep MCP and ComfyUI listeners on loopback unless LAN access is intentionally secured.
- Never place inference credentials in this repository.
- Preserve `MASTER`, `.3dm`, and source STEP assets; modify working copies only.

## Playbook

1. [Validate the Spark baseline](01-platform-inventory.md).
2. [Install FreeCAD, FreeCAD MCP, and the migrated model](02-freecad-and-mcp.md).
3. [Install Hermes in OOBE state and validate vLLM](03-hermes-and-vllm.md).
4. [Deploy ComfyUI for GB10](04-comfyui.md).
5. [Connect Blender MCP and review the Blender 5.2 asset gate](05-blender-status.md).
6. [Run acceptance checks or roll back](06-validation-and-rollback.md).

## Success criteria

The distributable core is ready when `verify-platform.sh` prints
`LOCAL_AEC_DGX_CORE_PASS`, the ComfyUI smoke workflow prints `COMFYUI_CUDA_SMOKE_PASS`,
vLLM remains healthy, and a bare Hermes launch requests first-run setup. After the user
completes OOBE, attach FreeCAD and Blender MCP to the profile the user chose.
