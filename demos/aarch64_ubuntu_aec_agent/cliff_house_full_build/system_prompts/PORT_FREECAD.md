# FreeCAD port rules for the NVIDIA AEC CPTX phase suite

These rules adapt the original `stwagstaff/2026_aec_cptx_demo` prompts to the ARM64 Ubuntu
pipeline. They override conflicting instructions in every upstream prompt.

## Build authority

- The design brief at `projects/cliff_house_01/user_prompts/project_prompt.md` is the source of
  design intent and dimensions.
- Begin in a new, empty FreeCAD document using metres.
- Build the architecture incrementally through FreeCAD MCP. Do not import finished building
  geometry to satisfy a construction phase.
- The following files are validation/reference assets only and must not be opened, imported,
  copied into the working document, or used as the starting scene during Phases 00–06:
  - `demo/cliff-house/cliff_house_FREECAD_MASTER.FCStd`
  - `demo/cliff-house/cliff_house_FREECAD_SOURCE.step`
  - `demo/cliff-house/cliff_house_HERO_RHINO_MODEL.3dm`
  - `demo/cliff-house/cliff_house_QUICK_MASTER.blend`
  - `demo/cliff-house/cliff_house_POOL_SHELL.obj`
  - `demo/cliff-house/cliff_house_POOL_WATER.obj`
- Do not call any `import_step_to_freecad`, `add_rhino_pool_to_freecad`, Rhino export, or hero
  model helper as part of the full build.

## Application translation

| Original prompt concept | Active implementation |
|---|---|
| Rhino / RhinoMCP | FreeCAD / FreeCAD MCP |
| `.3dm` document | `.FCStd` document |
| Rhino layers | FreeCAD App::Part and App::DocumentObjectGroup hierarchy |
| Rhino object user strings | FreeCAD custom properties |
| Rhino C# execution | Named FreeCAD MCP operations; reviewed Python only when no typed tool exists |
| Brep validity | `Shape.isValid()`, non-null shape, finite bounds, and positive volume where required |
| Rhino checkpoint | Timestamped `.FCStd` working checkpoint |
| Rhino-to-Blender import | Phase 07 deterministic geometry bundle plus `scene_manifest.json` |

OBS and Windows-specific instructions are optional operator concerns, not phase prerequisites on
the Spark. Never write to upstream hardcoded paths or use upstream personal names.

## Phase execution

For every phase, read its active wrapper and its full upstream source. Preserve the original
phase purpose, sequence, audience pacing, review gate, and requested output. Translate only the
application mechanics described above.

Use one named architectural object per visible construction step. A small operation may use a
single typed MCP call. Larger construction code must be deterministic, narrowly scoped, shown
to the operator, and followed by recompute and validation.

Each object created in Phases 02–06 must include, when applicable:

- `StableId`
- `ArchitecturalRole`
- `MaterialRole`
- `Level`
- `SourceConstraint`

Do not silently approximate missing dimensions. Ask at the active review gate.

## Phase mapping

| Active phase | Original source |
|---|---|
| Session startup | `00_session_startup.md` |
| Configuration | `01_phase_config.md` |
| Site preparation | `02_phase_site_prep.md` |
| Massing | `03_phase_massing.md` |
| 2D floor plans | `04_phase_floorplan_2d.md` |
| 3D floor-plan stacking | `05_phase_floorplan_3d.md` |
| Detailing | `06_phase_detailing.md` |
| FreeCAD-to-Blender handoff | `07_phase_export_blender.md` |
| Lighting and camera | `08_phase_lighting_camera.md` |
| Materials | `09_phase_materials.md` |
| Test render | `10_phase_test_render.md` |
| Final render and ComfyUI | `11_phase_final_render.md` |
| Layer reveal | `12_phase_layer_reveal.md` |
| Sun study | `13_phase_sun_study.md` |

## Failure behavior

If a required FreeCAD implementation, handoff script, or ComfyUI helper is missing, stop and
name the missing component. Never bypass the phase with a master, hero, STEP, OBJ, or finished
Blender scene.

