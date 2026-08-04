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

## Refresh required

The imported demo contains the major stages, but the inventory found two pieces that are not
self-contained yet:

1. The Blender master is checked in, but the script that deterministically converts the
   audited FreeCAD document into that Blender scene is not present.
2. `comfyui_flux2_direct.py` imports `comfyui_vp_stylize.py` from a separate
   `virtual_production_studio` demo that is not in this repository.

Refresh those two original sources before declaring the full-build workflow complete. Do not
silently substitute the prebuilt Blender master for the FreeCAD-to-Blender build stage.

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
