# FreeCAD modeling discipline

- Start from a new clean document named `cliff_house_02_working` in metres.
- Reconstruct and lock the upstream guide objects from
  `projects/cliff_house_02/freecad_reference/source_curves.json` before target construction.
- Use typed FreeCAD MCP tools when available. Use reviewed `execute_code` only for deterministic
  operations that the typed interface cannot express.
- Build one named architectural object per visible step and recompute after every step.
- Organize objects by site, level, role, and system using App::Part or DocumentObjectGroup.
- Derive placements and dimensions from the project brief, approved configuration, datum
  geometry, sketches, or previously approved edges. Never eyeball coordinates.
- Add stable IDs and semantic custom properties as specified in `PORT_FREECAD.md`.
- Never import the checked-in master, STEP, Rhino, OBJ, or Blender assets during Phases 00–06.
- Save only to timestamped working paths after the applicable operator approval.
