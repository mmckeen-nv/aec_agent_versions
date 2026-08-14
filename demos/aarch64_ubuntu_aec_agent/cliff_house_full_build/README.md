# cliff_house_full_build

The end-to-end Cliff House workflow for ARM64 Ubuntu on NVIDIA DGX Spark. It adapts Wagstaff's
source-curve-driven Rhino workflow to FreeCAD while preserving the same project brief,
authoritative massing extents, and validation gates.

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
2. Start local vLLM, then deploy the isolated Hermes profile using the exact served model ID:

   ```bash
   MODEL_ID='your-vllm-served-model-id' \
   CONTEXT_LENGTH=262144 \
   platform/linux-dgx-spark/scripts/deploy-hermes-profile.sh
   ```
3. Start FreeCAD, Blender, and their loopback MCP bridges.
4. Run the commands in [RUN_WORKFLOW.md](RUN_WORKFLOW.md).

The FreeCAD reference input is the checked-in, platform-neutral
`projects/cliff_house_02/freecad_reference/source_curves.json`. It contains the 10 guide curves
and six labels extracted from the pinned upstream `base_model.3dm`, normalized from millimetres
to metres. The completed `.FCStd`, STEP, Rhino, OBJ, and Blender assets under `demo/cliff-house/`
remain protected comparison/migration references and are never construction inputs.

## Repository layout

- `INSTALL GUIDE/` — numbered, copy-ready setup and rollback guides.
- `config/hermes/` — secret-free Hermes profile template.
- `demo/cliff-house/` — source masters and the migrated FreeCAD model.
- `installer/` — idempotent bootstrap, health check, and launcher scripts.
- `scripts/` — deterministic demo and ComfyUI helper scripts.
- `projects/cliff_house_02/` — upstream project brief and platform-neutral FreeCAD guide manifest.

## Security model

MCP servers execute local application actions. Use this demo on a trusted workstation,
review requested mutations before approval, and never commit `%LOCALAPPDATA%\hermes\.env`
or a populated profile. The default MCP hosts bind only to loopback.
