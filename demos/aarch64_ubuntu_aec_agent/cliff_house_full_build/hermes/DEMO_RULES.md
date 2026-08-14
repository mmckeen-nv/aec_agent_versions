# Cliff House full-build demo rules

The upstream NVIDIA demo rules are preserved at
`upstream/stwagstaff-2026-aec-cptx-demo/hermes/DEMO_RULES.md`. Preserve their visible,
incremental build pacing and review-gate behavior, subject to these overrides:

- Use FreeCAD instead of Rhino.
- Build in a clean FreeCAD document from the immutable source-guide manifest and design brief.
- Reconstruct `projects/cliff_house_02/freecad_reference/source_curves.json` first. Keep its
  reference group non-selectable and never mutate it as target geometry.
- Never load, import, or copy the checked-in hero/master/STEP/OBJ/Blend assets to satisfy a
  construction phase.
- Do not conceal use of reference geometry or claim generated work that was imported.
- Use one named object per visible construction step; report validation after each step.
- Never mutate geometry before the applicable operator approval.
- Do not invoke OBS automatically.
- Never expose credentials or write to upstream machine-specific paths.
