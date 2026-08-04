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
| FreeCAD source import | `scripts/import_step_to_freecad.py` | `FREECAD_STEP_IMPORT_PASS` | Present |
| Pool preservation | `scripts/add_rhino_pool_to_freecad.py` | `FREECAD_POOL_IMPORT_PASS` | Present |
| Geometry audit | `scripts/audit_freecad_geometry.py` | `FREECAD_GEOMETRY_AUDIT_PASS` | Present |
| Persisted FreeCAD view | `scripts/prepare_freecad_view.py` | `FREECAD_VIEW_PREP_PASS` | Present |
| FreeCAD → Blender handoff | Checked-in `cliff_house_QUICK_MASTER.blend` only | No deterministic export/build receipt | **Refresh required** |
| Blender scene validation/render | `scripts/blender_cliff_quick.py` | `CLIFF_QUICK_OPEN_PASS`, `CLIFF_QUICK_RENDER_PASS` | Present |
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

## Source refresh and port required

The imported demo contains the major stages, but the inventory found two pieces that are not
self-contained yet:

1. The Blender master is checked in as a protected reference, but the script that
   deterministically converts the
   audited FreeCAD document into that Blender scene is not present.
2. `comfyui_flux2_direct.py` imports `comfyui_vp_stylize.py` from a separate
   `virtual_production_studio` demo that is not in this repository.

The authoritative original prompt suite and design brief are now vendored with provenance and
activated through the FreeCAD adapter. The remaining Blender/ComfyUI implementation scripts
must still be ported according to `PLAYBOOK.md`. Do not silently substitute the prebuilt
Blender master for the FreeCAD-to-Blender build stage.

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
