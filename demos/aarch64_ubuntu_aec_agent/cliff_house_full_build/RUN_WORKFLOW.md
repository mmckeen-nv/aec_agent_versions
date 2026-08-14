# Run the reproducible Cliff House workflow

This is the saved, executable FreeCAD-to-Blender workflow used for the DGX Spark test render.
It starts with a clean FreeCAD document, reconstructs Wagstaff's immutable source guides from the
checked-in JSON manifest, creates named architectural objects through FreeCAD MCP, exports a
hashed geometry bundle and manifest, then uses Blender MCP to assemble and render the scene. It
never imports a completed hero, master, STEP, OBJ, or Blend asset as construction geometry.

## Prerequisites

- Run the deployment and profile setup in `INSTALL GUIDE/LINUX DGX SPARK/`.
- Start FreeCAD with its MCP bridge available as `~/.local/bin/freecad-mcp`.
- Start Blender with BlenderMCP listening on loopback.
- Run commands from this `cliff_house_full_build` directory.

ComfyUI is deployed separately and is not required for the geometry-locked test render below.

## Run a new build

```bash
RUN_ID="live-$(date -u +%Y%m%dT%H%M%SZ)"
~/.hermes/hermes-agent/venv/bin/python scripts/run_full_build_mcp.py \
  --root "$PWD" \
  --run-id "$RUN_ID"
```

The runner writes only to the ignored directory `work/$RUN_ID/`. A successful run ends with:

```text
FULL_BUILD_TEST_RENDER_PASS
```

## Resume after an MCP or application interruption

Restart the affected application and MCP bridge, then reuse the same run identifier:

```bash
~/.hermes/hermes-agent/venv/bin/python scripts/run_full_build_mcp.py \
  --root "$PWD" \
  --run-id "$RUN_ID" \
  --resume
```

Resume reuses the completed FreeCAD handoff and continues the Blender assembly/render stage.

## Saved workflow stages

1. Create a new timestamped FreeCAD document and reconstruct the 16 source guide objects.
2. Build the terrain, site, pool, architectural masses, glazing, and entry objects one named
   object at a time through FreeCAD MCP.
3. Save `freecad/cliff_house_02_working.FCStd` and emit per-object receipts.
4. Tessellate only the generated objects into `freecad_blender_bundle/geometry/`.
5. Write `freecad_blender_bundle/scene_manifest.json` with object roles, materials, levels,
   source constraints, and SHA-256 hashes.
6. Import the bundle through Blender MCP while preserving FreeCAD Z-up coordinates.
7. Assign semantic materials, frame the imported bounds, add lighting, and render a test image.
8. Save the Blender scene and the final workflow receipt.

## Expected artifacts

```text
work/$RUN_ID/
├── freecad/cliff_house_02_working.FCStd
├── freecad_blender_bundle/
│   ├── geometry/*.obj
│   └── scene_manifest.json
├── blender/cliff_house_02_working.blend
├── blender/cliff_house_test_render.png
└── receipts/*.json
```

These are run artifacts, not repository source. Do not commit `work/` or `outputs/`.

## Current acceptance boundary

This runner proves the geometry build, deterministic handoff, Blender scene assembly, and test
render. The ComfyUI beauty pass remains a separate downstream stage until a pinned, redistributable
workflow and its model requirements are added. Do not describe `FULL_BUILD_TEST_RENDER_PASS` as a
final ComfyUI acceptance receipt.
