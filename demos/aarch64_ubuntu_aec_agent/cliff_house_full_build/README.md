# cliff_house_full_build

The end-to-end Cliff House workflow for ARM64 Ubuntu on NVIDIA DGX Spark. This package is
being separated from the validated modifications demo so the complete FreeCAD → Blender →
ComfyUI build can evolve and be tested independently.

Start with [RUN_WORKFLOW.md](RUN_WORKFLOW.md) to reproduce the validated FreeCAD-to-Blender test
render. [WORKFLOW.md](WORKFLOW.md) records the broader phase and acceptance contract, including
the remaining ComfyUI beauty-pass boundary.

```text
Selectable inference endpoint <-> Hermes on DGX Spark
                                  |-> FreeCAD MCP <-> FreeCAD
                                  |-> Blender MCP <-> Blender
                                  \-> local ComfyUI (NVIDIA CUDA)
```

The Windows and DGX Spark playbooks exclude DML/CMA memory. Both platforms exclude Mission Control,
DirectML, application installers, model weights, logs, caches, and credentials.

## Quick start

1. Follow [the DGX Spark install guide](INSTALL%20GUIDE/LINUX%20DGX%20SPARK/README.md).
2. Configure the isolated `cliff-house-full-build` Hermes profile and select an inference
   provider during OOBE; credentials remain outside this repository.
3. Start FreeCAD, Blender, and their loopback MCP bridges.
4. Run the commands in [RUN_WORKFLOW.md](RUN_WORKFLOW.md).

## Repository layout

- `INSTALL GUIDE/` — numbered, copy-ready setup and rollback guides.
- `config/hermes/` — secret-free Hermes profile template.
- `demo/cliff-house/` — source masters and the migrated FreeCAD model.
- `installer/` — idempotent bootstrap, health check, and launcher scripts.
- `scripts/` — deterministic demo and ComfyUI helper scripts.

## Security model

MCP servers execute local application actions. Use this demo on a trusted workstation,
review requested mutations before approval, and never commit `%LOCALAPPDATA%\hermes\.env`
or a populated profile. The default MCP hosts bind only to loopback.
