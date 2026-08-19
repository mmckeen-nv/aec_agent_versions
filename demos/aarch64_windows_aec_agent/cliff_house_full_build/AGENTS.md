# Cliff House full-build agent context

This workspace is the Windows ARM64 **Cliff House Full Build** demo. It is separate from
`cliff_house_modifications` and must not read, activate, or modify that workflow's Hermes profile,
project, sessions, outputs, or configuration.

## Intent recognition

Treat “start the cliff house build,” “run the full build,” “build the cliff house,” and
“continue the cliff house build” as instructions to begin or resume this workflow. Read:

1. `skills/INDEX.md`
2. `system_prompts/WINDOWS_WORKSPACE_RULES.md`
3. `hermes/DEMO_RULES.md`
4. `hermes/phase_state.json`
5. `projects/cliff_house_02/user_prompts/project_prompt.md`
6. `system_prompts/00d_golden_master_contract.md`
7. the active phase prompt under `system_prompts/`

Begin Phase 00 or resume the next incomplete phase represented by a valid receipt. State the
selected phase and perform its read-only preflight. Do not mutate geometry before its review gate.

## Pipeline

1. Rhino MCP imports the source-curve model from `projects/cliff_house_02/rhino_assets/base_model.3dm`, then creates and validates the architectural model.
2. Phase 07 transfers audited geometry and metadata to Blender.
3. `blender_import_handoff` imports, saves, frames, and foregrounds the exact managed Blender
   instance. For the standard hero still, `blender_render_archviz` owns the complete known-good
   camera-target, lighting, render, save, and presentation transaction; do not guess low-level
   operation fields.
4. `comfyui_health` and one idempotent `comfyui_stylize_image` transaction perform and retrieve the
   geometry-locked architectural visualization. A Blender render alone is not a ComfyUI result.
5. Each phase emits the receipt required by the active prompt.

Never load a completed hero Rhino file, quick Blender master, or another completed model as a
full-build shortcut. The source-curve `base_model.3dm` is required input, not a completed model.
The golden contract is normative: generic examples and adjustable defaults in upstream prompts
must resolve to its exact dimensions, names, layer paths, program, and acceptance counts.

## Rhino execution surface

For each construction unit, use `rhino_scene_query` to capture the current revision and targets,
then prefer one `rhino_apply_operations` batch and independently check it with
`rhino_verify_transaction`. Supply a stable idempotency key and the active working-document path as
the checkpoint path. Typed operations are required for primitives, curves, in-place transforms,
attributes, extrusion, offset, deletion, duplication, and booleans.

The Full Build profile alone exposes transactional `rhino_execute_python` as an escape hatch for
specialized annotations or geometry not represented by the typed catalog. Use it only when typed
operations cannot express the active phase, and still surround it with rich scene queries and
verification. Never call raw Rhino `run_python` or `run_csharp`.

## OOBE and safety

- Hermes provider, model, endpoint, credentials, profile, and MCP configuration are user-owned.
- Do not change inference configuration or activate another profile.
- Files containing `MASTER` or `HERO` are immutable references.
- Work only in timestamped ignored `work/` or `outputs/` directories.
- Inspect before mutation and ask before deletion, replacement, or overwrite.
- Preserve units, axes, semantic names, layer paths, identifiers, materials, and placements.
- ComfyUI output is visualization, not verified geometry.
- Never expose secrets or unrelated files.
- The profile's isolated Daystrom DML store supplies compact procedural recall. Persist only
  sanitized, validated workflow outcomes; never raw transcripts, secrets, or unverified claims.
  CMA is out of scope.
