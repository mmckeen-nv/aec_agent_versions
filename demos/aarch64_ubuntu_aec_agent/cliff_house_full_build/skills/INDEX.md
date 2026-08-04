# Cliff House full-build skills index

Read this file at the start of every session, followed by `hermes/phase_state.json` and the
active phase wrapper under `system_prompts/`.

This index adapts the original catalog preserved at
`upstream/stwagstaff-2026-aec-cptx-demo/skills/INDEX.md`.

## Precedence

1. `system_prompts/PORT_FREECAD.md`
2. This active skills index and active FreeCAD skills
3. The active phase wrapper
4. The corresponding upstream phase prompt and upstream skills

The original prompt's design and sequencing remain authoritative. FreeCAD adapter rules win
only where application, platform, path, or safety mechanics differ.

## Active skills

| Skill | When to read |
|---|---|
| `skills/freecad_modeling.md` | Phases 02–06; any FreeCAD creation or edit |
| `skills/freecad_validation.md` | After every FreeCAD construction step and review gate |
| `skills/freecad_blender_handoff.md` | Phase 07 export/import |
| `skills/BACKUP_RULE.md` | Before substantive FreeCAD or Blender changes; interpret Rhino as FreeCAD |
| `skills/VISUAL_ENGAGEMENT_RULE.md` | Design discussion and viewport review |
| `skills/validate_blender_scene.py` | Blender post-import validation |
| `skills/coplanar_detector.py` | Blender geometry audit |
| `skills/derive_geometry.py` | Blender derived geometry only |
| `skills/depth_and_segmentation.md` | Final-render conditioning passes |

Never use the upstream Rhino execution skills directly. They are preserved for provenance and
behavioral reference only.

