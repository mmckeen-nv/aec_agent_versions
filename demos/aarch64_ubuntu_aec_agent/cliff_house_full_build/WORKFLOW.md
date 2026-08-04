# Cliff House full-build workflow

## Target pipeline

```text
Hermes OOBE
  → FreeCAD MCP: create and validate the architectural model
  → deterministic FreeCAD-to-Blender handoff
  → Blender MCP: materials, cameras, lighting, and beauty render
  → ComfyUI: geometry-locked architectural visualization
  → provenance and acceptance receipts
```

The detailed port and delivery plan is in [PLAYBOOK.md](PLAYBOOK.md). The authoritative source
workflow is NVIDIA's [`stwagstaff/2026_aec_cptx_demo`](https://github.com/stwagstaff/2026_aec_cptx_demo).

## Extracted implementation inventory

| Stage | Included implementation | Receipt or invariant | State |
|---|---|---|---|
| Empty-document FreeCAD build | `scripts/run_full_build_mcp.py` | Per-object phase receipts | **Validated** |
| Pool construction | `scripts/run_full_build_mcp.py` | `PHASE_06_OBJECT_PASS` | **Validated** |
| Geometry audit and metadata | Generated manifest plus receipts | Named roles, levels, constraints, and hashes | **Validated** |
| FreeCAD → Blender handoff | Explicit tessellation plus `scene_manifest.json` | Hashed geometry bundle | **Validated** |
| Blender scene assembly/render | `scripts/run_full_build_mcp.py` | `FULL_BUILD_TEST_RENDER_PASS` | **Validated** |
| Blender → ComfyUI handoff | Rendered PNG | Source hash captured | Present |
| ComfyUI processing | `scripts/comfyui_flux2_direct.py` | `COMFY_OUTPUT_PASS` | **Helper refresh required** |
| Platform deployment | `platform/linux-dgx-spark/` | `LOCAL_AEC_DGX_CORE_PASS` | Validated |

## Prompt-suite integration

The complete upstream 00–13 prompt suite, Cliff House project brief, demo rules, and skills are
now pinned under `upstream/stwagstaff-2026-aec-cptx-demo/`. Active phase wrappers under
`system_prompts/` preserve the upstream intent and require the FreeCAD overrides in
`system_prompts/PORT_FREECAD.md`.

`AGENTS.md` recognizes “start the cliff house build,” loads the active phase state and original
source prompt, and prohibits the hero/master/STEP/OBJ/Blend assets as construction shortcuts.
The full-build workflow starts from an empty FreeCAD document.

## Remaining ComfyUI port

The visible MCP runner now provides the deterministic empty-document FreeCAD build and
FreeCAD-to-Blender handoff without using protected reference assets. One downstream piece is not
self-contained yet: `comfyui_flux2_direct.py` imports `comfyui_vp_stylize.py` from a separate
   `virtual_production_studio` demo that is not in this repository.

The authoritative original prompt suite and design brief are vendored with provenance and
activated through the FreeCAD adapter. The remaining ComfyUI implementation must be ported
according to `PLAYBOOK.md`. Do not silently substitute the prebuilt Blender master for any stage.

## Acceptance contract

A complete run must emit, in order:

1. a FreeCAD build/import receipt and geometry audit receipt;
2. a deterministic FreeCAD-to-Blender handoff receipt;
3. Blender scene-audit and render receipts;
4. a ComfyUI preflight and output receipt;
5. hashes for the source model, Blender render, final image, and workflow metadata;
6. `LOCAL_AEC_DGX_CORE_PASS` with vLLM still healthy.

Generated working files belong under an ignored `work/` or `outputs/` directory. Checked-in
masters and source geometry remain immutable.
