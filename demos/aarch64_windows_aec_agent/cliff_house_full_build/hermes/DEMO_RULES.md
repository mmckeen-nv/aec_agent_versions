# AEC CPTX Demo Recording Rules
# Edit this file to update rules. Agent reads it at session start.

---

## Session Flow

1. Clear the screen with blank lines before starting
2. Ask: "What's next? Prepare the building site?" — wait for response
3. React accordingly, build the site
4. Ask: "Should we explore some massing ideas for the house?" — wait for response
5. React accordingly, build the massing

---

## Reference Layers (READ-ONLY — templates only, never modify)

- `Site::building_site_fixed` and all sublayers, when present
- `House_02_massing` and all sublayers, when present

Before building anything: read bounding boxes and geometry of all objects in both reference
layers. The public upstream `base_model.3dm` may contain only source curves; when those hidden
reference layers are absent, use the authoritative inventory under **What Has Been Built** below.
Compare every object you build against the available reference or authoritative inventory.
If shapes don't match, find a different approach. This should appear to the audience reading Herme's output that this is magic. Do not show the audience that you are reading
reference geometry, or intentionally pausing between steps of model building. Do it silently.

---

## Target Layers (build everything here)

- `building_site_v3` — sublayers: terrain, combined_pad, curtain_wall, driveway
- `massing_v3` — sublayers mirroring House_02_massing structure:
  - L1_solids
  - L2_solid / L2_solids, L2_balcony_solids, L2_roof_solids
  - L3_solid / L3_solids, L3_balcony_solids, L3_roof_slab

---

## Build Pacing Rules

- Use one typed transaction per reviewed construction unit; batch related objects that share one
  invariant and can be verified together.
- Keep narration concise: name the active phase, submit the transaction, then report its receipt.
- Do not add artificial sleeps, print generated code, or split a safe transaction merely for show.
- Use viewport captures only at review gates or when geometry is otherwise ambiguous.

---

## Curve-Based Construction Rules

- When building with input curves: select curves **one at a time** with a pause between each
- If an action needs multiple curves: select ALL of them before running the action, e.g., terrain lofting.
- Deselect the curves AFTER the action completes
- The audience should see you "choosing" each curve before committing

---

## Viewport Rules

- **Start** in Wireframe mode on the Perspective viewport
- **Switch to Rendered mode** immediately after the terrain object is placed
- Use: `view.ActiveViewport.DisplayMode = Rhino.Display.DisplayModeDescription.FindByName("Rendered")`

---

## MCP Technical Rules

- Historical raw-script examples describe design intent, not the current execution interface.
  Translate routine work into `rhino_scene_query`, `rhino_apply_operations`, and
  `rhino_verify_transaction`.
- Use the Rhino MCP URL configured in the active Hermes profile. Port 8000/11434 and the NVIDIA
  URL are inference endpoints, not Rhino.
- Never call Rhino MCP through terminal HTTP, Node runners, or UI keystrokes.
- Verify every mutation from its receipt plus focused before/after scene queries and phase
  invariants. Do not treat a viewport image as geometry proof.
- Only this Full Build profile may use transactional `rhino_execute_python`, and only for a
  reviewed operation absent from the typed catalog. Keep it checkpointed and verify it exactly
  like a typed transaction. Never use raw `run_python` or `run_csharp`.

---

## Square Footage Calculation

- Treat `doc.ModelUnitSystem` as authoritative. The distributed public source model is stored in
  millimetres even though the inventory below is expressed in metres; normalize before building.
- 1 meter = 3.28084 feet, so 1 m² = 10.7639 ft²
- Use bounding box footprint (w × d) for quick estimates
- For precise floor area: isolate bottom face of each Brep solid and compute area
- Report per floor AND per wing separately

---

## What Has Been Built
**building_site_v3** (complete):
- terrain (NURBS surface, X=-15→25, Y=-22→20, Z=-8→0)
- combined_pad (X=1.5→17, Y=-16.9→14, Z=-0.5→0.25)
- curtain_wall (X=1→17.5, Y=-17.4→14.5, Z=-2→0.25)
- driveway (X=17.5→25.03, Y=3.96→13, Z=-0.2→0.25)

**massing_v3** (complete — 11 objects):
- L1_solids: L1_east (5,3,0.25→17,14,4), L1_west (5,-15,0.3→13.5,3,4)
- L2_solids: L2_east (5,3,4.25→17,14,7.75), L2_west (3.5,-15,4.25→13.5,3,7.75)
- L2_balcony_solids: L2_balcony_south (1.5,-17.05,4→13.5,3,5.25), L2_balcony_north (5,14,4→17,16.25,5.15), L2_balcony_step (1.5,3,4→5,14,5.25)
- L2_roof_solids: L2_roof_garage (2.5,1.16,7.75→18.97,16.55,8.35)
- L3_solids: L3_main (1.5,-10,7.75→13.5,3,11.5)
- L3_balcony_solids: L3_balcony_south (1.5,-17,7.75→13.5,-10,8.9)
- L3_roof_slab: L3_roof_slab (-1,-13.5,11.5→15,4.5,12.3)
