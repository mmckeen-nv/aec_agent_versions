# Cliff House full-build playbook

This playbook ports NVIDIA's original
[`stwagstaff/2026_aec_cptx_demo`](https://github.com/stwagstaff/2026_aec_cptx_demo)
from Rhino on Windows to FreeCAD on ARM64 Ubuntu. It preserves the original live-demo shape:
Hermes reads a design brief, builds the project in visible phases, crosses explicit review
gates, transfers semantic geometry to Blender, and produces a final visualization through
ComfyUI.

This document is the implementation plan. A phase is not complete until its code, prompt,
receipt, rollback behavior, and live Spark smoke test exist.

## Non-negotiable operating principles

1. **Derive, do not redraw.** New geometry must be constrained to audited references,
   dimensions, sketches, or existing edges. No eyeballed coordinates.
2. **Build visibly and incrementally.** The agent performs small, named operations suitable
   for a live audience and reports phase receipts rather than dumping opaque bulk geometry.
3. **Preserve semantic metadata.** Every exported object carries its name, group, material
   role, architectural role, level, and source identifier into Blender.
4. **Validate before crossing applications.** Invalid shapes, duplicates, non-finite bounds,
   missing metadata, or hash mismatches block the next phase.
5. **Protect source assets.** Checked-in references and masters are immutable. Each run uses a
   timestamped working directory and phase checkpoints.
6. **Keep OOBE honest.** Deployment does not select a Hermes provider or model. The operator
   completes OOBE before attaching FreeCAD and Blender MCP.
7. **Keep services local.** FreeCAD MCP, Blender MCP, vLLM, and ComfyUI remain loopback-only.
8. **Emit evidence.** Every phase writes a machine-readable receipt with inputs, outputs,
   hashes, counts, elapsed time, and gate result.

## Target runtime

| Component | Role | Expected endpoint |
|---|---|---|
| Hermes Agent | Orchestration and operator conversation | Interactive OOBE-selected provider |
| vLLM | Optional local inference choice | `127.0.0.1:8000` |
| FreeCAD 1.1.3 ARM64 | Parametric architectural construction | GUI + FreeCAD MCP on `127.0.0.1:9875` |
| Blender ARM64 | Scene assembly, materials, camera, lighting, rendering | Blender MCP on `127.0.0.1:9876` |
| ComfyUI | Geometry-locked architectural post-processing | `127.0.0.1:8188` |

## Planned workflow package

```text
cliff_house_full_build/
├── PLAYBOOK.md
├── WORKFLOW.md
├── hermes/
│   ├── DEMO_RULES.md
│   └── phase_state.json
├── system_prompts/
│   ├── 00_session_startup.md
│   ├── 01_phase_config.md
│   ├── 02_phase_site_prep.md
│   ├── 03_phase_massing.md
│   ├── 04_phase_floorplan_2d.md
│   ├── 05_phase_floorplan_3d.md
│   ├── 06_phase_detailing.md
│   ├── 07_phase_export_blender.md
│   ├── 08_phase_lighting_camera.md
│   ├── 09_phase_materials.md
│   ├── 10_phase_test_render.md
│   ├── 11_phase_final_render.md
│   ├── 12_phase_layer_reveal.md
│   └── 13_phase_sun_study.md
├── skills/
│   ├── INDEX.md
│   ├── freecad_modeling.md
│   ├── freecad_validation.md
│   ├── freecad_blender_handoff.md
│   ├── validate_blender_scene.py
│   └── comfyui_archviz.py
├── projects/cliff_house_01/
│   ├── user_prompts/project_prompt.md
│   ├── references/
│   ├── freecad_assets/
│   ├── blender_assets/
│   ├── comfy_source/
│   ├── comfy_output/
│   ├── renders/
│   ├── receipts/
│   └── work/
└── scripts/
    ├── export_freecad_scene.py
    ├── import_freecad_bundle.py
    ├── render_cliff_house.py
    ├── comfyui_archviz.py
    └── verify_full_build.py
```

Generated project outputs remain ignored. Only prompts, deterministic scripts, small reference
assets, and explicitly approved masters belong in Git.

## Phase plan

### Phase 00 — Session startup

**Purpose:** establish a known-safe session before geometry work.

- Read `hermes/DEMO_RULES.md`, the skills index, phase state, and project brief.
- Confirm Hermes setup is complete without logging provider credentials.
- Test FreeCAD MCP, Blender MCP, ComfyUI health, and optional vLLM health.
- Confirm FreeCAD and Blender have the expected working documents open.
- Report degraded components and block only the phases that depend on them.

**Receipt:** `PHASE_00_STARTUP_PASS` with service states and selected project, excluding secrets.

### Phase 01 — Project configuration and design brief

**Purpose:** translate the natural-language brief into explicit build parameters.

- Create the ignored project working tree.
- Read the original Cliff House brief and interview the operator for unresolved decisions.
- Record units, north, ocean/view direction, level elevations, primary dimensions, materials,
  render targets, and review checkpoints.
- Create a FreeCAD document in metres and a clean Blender scene in metres.

**Gate 01:** no unresolved dimensional or orientation decisions.

**Receipt:** `PHASE_01_CONFIG_PASS` plus a normalized `project_config.json` hash.

### Phase 02 — Site preparation in FreeCAD

**Purpose:** establish terrain, buildable pad, driveway, patio, pool zone, and reference axes.

- Import or reconstruct audited site reference curves.
- Use Draft/Part geometry with named groups and stable object identifiers.
- Derive terrain and pads from references; do not use arbitrary placement.
- Add property metadata: `architectural_role`, `level`, `material_role`, and `source_id`.
- Recompute, fit view, and save a phase checkpoint.

**Gate 02:** finite bounds, valid shapes, expected site groups, no duplicate identifiers.

**Receipt:** `PHASE_02_SITE_PASS` with object counts, bounds, and checkpoint hash.

### Phase 03 — Architectural massing in FreeCAD

**Purpose:** build the three-storey modernist massing and cantilever hierarchy.

- Construct Level 1, 2, and 3 masses from constrained sketches and named dimensions.
- Add floor/roof slabs, balconies, garage volume, and primary voids.
- Keep each architectural element as an independently named object or Body.
- Save a checkpoint after each level so the live demo can recover without replaying the phase.

**Gate 03:** all Bodies recompute, required levels exist, cantilevers match the brief, and no
invalid or zero-volume solids remain.

**Receipt:** `PHASE_03_MASSING_PASS` with per-level counts and volumes.

### Phase 04 — 2D floor plans

**Purpose:** derive readable plan geometry from the approved massing.

- Create level-specific Draft/Sketcher plan groups.
- Add room boundaries, circulation, stairs, labels, and dimensions.
- Link plan references to the massing datum system.
- Keep presentation annotations separate from build geometry.

**Gate 04:** closed room boundaries, no duplicate labels, correct level association.

**Receipt:** `PHASE_04_PLAN2D_PASS` with room and annotation counts.

### Phase 05 — 3D floor-plan stacking

**Purpose:** turn approved plans into coordinated interior and enclosure geometry.

- Extrude walls and room volumes from constrained plan boundaries.
- Cut doors, circulation voids, and primary openings.
- Validate vertical alignment between levels and slab clearances.
- Maintain semantic groups for rooms, walls, floors, ceilings, and circulation.

**Gate 05:** valid solids, expected room set, no unintended inter-level intersections.

**Receipt:** `PHASE_05_PLAN3D_PASS` with room volumes and collision summary.

### Phase 06 — Architectural detailing

**Purpose:** add the visible components required for the final architectural visualization.

- Add glazing, bronze mullions, balcony railings, stairs, entry, slab edges, cladding, pool
  shell/water, and required landscape hardscape.
- Derive repeated systems from parametric arrays or constrained source edges.
- Keep finish geometry offset from substrates to prevent coplanar surfaces.
- Assign canonical material roles, not final renderer-specific node trees.

**Gate 06:** geometry audit passes, pool is present, glazing/frame clearance is positive, and
all renderable objects carry semantic metadata.

**Receipt:** `PHASE_06_DETAIL_PASS` with role coverage and geometry-audit results.

### Phase 07 — Deterministic FreeCAD-to-Blender handoff

**Purpose:** replace the original `.3dm` metadata import with a reproducible, auditable bundle.

The planned exporter traverses visible FreeCAD objects in stable name order and writes:

```text
work/freecad_blender_bundle/
├── geometry/<stable_id>.obj
├── scene_manifest.json
└── SHA256SUMS.txt
```

Each manifest entry records:

- stable ID and FreeCAD object name;
- group path and level;
- architectural and material roles;
- source identifier;
- placement matrix, units, bounds, vertex/face counts;
- geometry-file SHA-256.

Use fixed tessellation tolerances so identical inputs produce identical mesh counts and hashes.
The Blender importer rebuilds collections from group paths, applies transforms, copies metadata
to custom properties, and refuses missing or mismatched files.

**Gate 07A — FreeCAD:** valid shapes, complete metadata, finite bounds, bundle hashes valid.

**Gate 07B — Blender:** object count and bounds agree with the manifest, no duplicate stable
IDs, no unexpected origin objects, and scene validation passes.

**Receipts:** `FREECAD_BLENDER_EXPORT_PASS` and `FREECAD_BLENDER_IMPORT_PASS`.

### Phase 08 — Lighting and cameras in Blender

**Purpose:** establish the approved ocean-view presentation without changing architecture.

- Create deterministic camera positions from the project configuration.
- Configure world/HDRI or an approved procedural sky.
- Add sun and controlled supplemental lighting.
- Lock camera transforms after operator approval.

**Gate 08:** required cameras exist, primary framing includes the house and full pool, exposure
is finite, and no architectural object moved after import.

**Receipt:** `PHASE_08_CAMERA_LIGHT_PASS` with camera matrices and lighting summary.

### Phase 09 — Materials

**Purpose:** convert semantic material roles into Blender material node groups.

- Map canonical roles to versioned material recipes.
- Preserve geometry; material assignment cannot create, delete, or transform objects.
- Verify every renderable mesh has a material and every role maps to a known recipe.

**Gate 09:** zero unassigned meshes, no unknown material roles, architecture hash unchanged.

**Receipt:** `PHASE_09_MATERIAL_PASS` with role-to-material mapping.

### Phase 10 — Test render

**Purpose:** run an inexpensive visual and technical gate before final rendering.

- Render the primary camera at `960×540` with bounded samples.
- Check output size, blank/black frames, missing textures, pool visibility, and geometry hash.
- Require operator review before final resolution.

**Gate 10:** render exists, passes technical checks, and receives operator approval.

**Receipt:** `PHASE_10_TEST_RENDER_PASS` with image hash and render settings.

### Phase 11 — Final render and ComfyUI

**Purpose:** produce the beauty image, supporting passes, and geometry-locked post-process.

- Render the approved camera at `1920×1080` to PNG and multilayer EXR.
- Extract depth and segmentation passes using the adapted original scripts.
- Submit the beauty frame and conditioning data to a self-contained ComfyUI client.
- Enforce the geometry-lock prompt and retain source dimensions.
- Write provenance containing source, workflow, output, prompt, model, and seed hashes.

**Gate 11:** Blender and ComfyUI outputs exist, dimensions match, hashes are recorded, and the
house/pool silhouette remains unchanged under the approved comparison rule.

**Receipts:** `PHASE_11_FINAL_RENDER_PASS`, `COMFY_FLUX2_PREFLIGHT_PASS`, and
`COMFY_OUTPUT_PASS`.

### Phase 12 — Layer reveal

**Purpose:** show how the project was assembled without mutating the saved model.

- Translate FreeCAD group paths into Blender collection reveal order.
- Animate visibility for site, massing, plans, detailing, materials, and landscape.
- Keep the reveal scene as a derived Blender working copy.

**Gate 12:** every target collection appears exactly once and the source scene hash is unchanged.

**Receipt:** `PHASE_12_LAYER_REVEAL_PASS` with collection order and animation range.

### Phase 13 — Sun study

**Purpose:** produce a deterministic time-of-day study from project location and orientation.

- Use documented latitude, longitude, timezone, date, and time range.
- Animate the Blender sun while preserving the approved camera and architecture.
- Render a bounded preview or approved final sequence.

**Gate 13:** location parameters are recorded, frame count is bounded, and geometry/camera
hashes remain unchanged.

**Receipt:** `PHASE_13_SUN_STUDY_PASS`.

## Review gates

| Gate | Operator decision | Automation must prove |
|---|---|---|
| 00 | Start or continue in degraded mode | Required services for next phase are healthy |
| 01 | Approve brief and dimensions | No unresolved configuration fields |
| 02 | Approve site | Valid site shapes and expected groups |
| 03 | Approve massing | Valid solids, level and volume checks |
| 04 | Approve plans | Closed plans and correct labels |
| 05 | Approve spatial model | Room/level coordination and collision checks |
| 06 | Approve details | Metadata coverage and geometry audit |
| 07 | Approve Blender handoff | Export/import manifests agree |
| 08 | Approve camera and light | Architecture hash unchanged |
| 09 | Approve materials | Complete material-role mapping |
| 10 | Approve test render | Technical checks and visual review |
| 11 | Approve final image | Provenance complete and geometry lock satisfied |

Phases 12 and 13 are optional derived deliverables after Gate 11.

## Implementation workstreams

### Workstream A — Import the original prompt system

- Vendor the original design brief, phase prompts, demo rules, appendixes, and relevant skills.
- Preserve upstream provenance in `THIRD_PARTY_NOTICES.md`.
- Replace machine-specific paths, passwords, personal names, and unsupported integrations.
- Keep phase numbering stable so the original operator script remains recognizable.

### Workstream B — Port Rhino phases to FreeCAD

- Define the exact FreeCAD MCP tool contract available on the Spark.
- Implement reusable FreeCAD helpers for documents, groups, properties, sketches, Parts,
  arrays, validation, checkpoints, and screenshots.
- Port phases 02–06 one at a time, with a headless audit after each GUI build phase.

### Workstream C — Build the application handoff

- Implement `export_freecad_scene.py` and a versioned `scene_manifest.schema.json`.
- Implement `import_freecad_bundle.py` for Blender.
- Establish fixed tessellation settings and a small deterministic fixture test.
- Compare bounds, counts, metadata, and hashes on both sides.

### Workstream D — Adapt Blender and ComfyUI

- Vendor and generalize the original import validation, camera, material, render, depth,
  segmentation, landscaping, and ComfyUI scripts.
- Remove the missing external ComfyUI-helper dependency.
- Pin required Blender/ComfyUI versions and provide CPU-free CUDA smoke tests.

### Workstream E — Orchestration and acceptance

- Implement phase-state persistence and restart-safe checkpoints.
- Add `verify_full_build.py` to validate receipt order and artifact hashes.
- Run a complete Spark rehearsal from clean Hermes OOBE through final ComfyUI output.
- Record elapsed time, GPU/memory behavior, manual gates, and recovery drills.

## Delivery milestones

| Milestone | Deliverable | Exit criterion |
|---|---|---|
| M1 | Prompt and brief import | Original 13 phases mapped; no machine-specific secrets |
| M2 | FreeCAD site and massing | Phases 02–03 pass live and headless audits |
| M3 | FreeCAD plans and detailing | Phases 04–06 pass with complete metadata |
| M4 | FreeCAD-to-Blender bundle | Phase 07 round trip passes manifest comparison |
| M5 | Blender visualization | Phases 08–10 produce approved deterministic test render |
| M6 | ComfyUI final | Phase 11 produces provenance-complete final image |
| M7 | Derived sequences | Optional phases 12–13 pass without source mutation |
| M8 | Full rehearsal | Clean Spark run passes every required gate and rollback drill |

## Definition of done

The full-build demo is complete only when a clean Spark deployment can start from the approved
brief/reference package, construct the FreeCAD model without a prebuilt architectural master,
reproduce the Blender scene through the manifest handoff, generate the final ComfyUI image,
and validate every phase receipt without relying on Rhino, Windows, an unbundled helper, or an
unrecorded manual geometry edit.
