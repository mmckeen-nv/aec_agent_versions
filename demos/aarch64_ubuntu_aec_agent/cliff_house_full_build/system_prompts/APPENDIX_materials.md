# Active FreeCAD adapter — APPENDIX_materials.md

This phase uses the original NVIDIA AEC CPTX prompt at
`upstream/stwagstaff-2026-aec-cptx-demo/system_prompts/APPENDIX_materials.md`.

Before executing this phase:

1. Read `system_prompts/PORT_FREECAD.md`.
2. Read the upstream prompt named above in full.
3. Apply the upstream intent, sequencing, review gates, pacing, and deliverables.
4. Apply every FreeCAD override in `PORT_FREECAD.md`. The adapter takes precedence over
   Rhino-, Windows-, OBS-, and machine-specific instructions in the upstream prompt.
5. Never load or import a checked-in hero/master model as the starting point.

If a required upstream operation has no implemented FreeCAD equivalent, stop at the gate and
report that exact porting blocker. Do not substitute a prebuilt model.
