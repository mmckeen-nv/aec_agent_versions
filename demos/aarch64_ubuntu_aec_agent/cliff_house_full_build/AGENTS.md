# Cliff House full-build agent context

This workspace is the **Cliff House Full Build** demo. It is separate from
`cliff_house_modifications` and must not read, activate, or modify that demo's Hermes profile,
projects, sessions, outputs, or configuration.

## Intent recognition

Treat any of these requests as an instruction to begin or resume this workflow:

- "start the cliff house build"
- "start cliff house"
- "run the full build"
- "build the cliff house"
- "continue the cliff house build"

On a start request, do not ask the operator what "Cliff House" means. Read, in order:

1. `skills/INDEX.md`
2. `system_prompts/PORT_FREECAD.md`
3. `hermes/DEMO_RULES.md`
4. `hermes/phase_state.json`
5. `projects/cliff_house_02/user_prompts/project_prompt.md`
6. the active wrapper and its upstream source prompt

Then begin Phase 00 (or resume the next incomplete phase represented by a valid receipt).
State the selected phase and perform its read-only preflight. Do not mutate geometry until the
applicable review gate is approved.

## Pipeline

The intended end-to-end workflow is:

1. Hermes performs Phase 00 preflight and reads the design/build playbook.
2. FreeCAD MCP creates and validates the architectural model.
3. A deterministic manifest transfers audited geometry and metadata to Blender.
4. Blender MCP assembles materials, cameras, lighting, and renders.
5. ComfyUI performs geometry-locked architectural post-processing.
6. Each completed phase emits the receipt defined in `PLAYBOOK.md`.

FreeCAD replaces Rhino in this workflow. Do not invoke Rhino or a Rhino MCP server. Phases 00–06
must begin from a clean FreeCAD working document, reconstruct the immutable source guides from
`projects/cliff_house_02/freecad_reference/source_curves.json`, and build from the prompt suite.
Never load or import the checked-in completed FreeCAD master, STEP source, hero Rhino file, pool
OBJ files, or quick Blender master as construction geometry.

The `hermes_aec` sidecar is shared infrastructure, not the Linux geometry bridge. Use its
host-neutral request routing, contracts, proof/receipt, memory, recorder, and Blender tools when
available. Never call a `rhino_*` sidecar tool on Linux; execute and verify model changes through
the `freecad` MCP server.

## Startup behavior

For Phase 00:

1. Read the active skill index, FreeCAD port rules, project brief, and both the active and
   upstream Phase 00 prompts.
2. Confirm the current working directory is this `cliff_house_full_build` directory.
3. Inspect MCP availability for FreeCAD and Blender without mutating either document.
4. Check ComfyUI health at its configured local endpoint.
5. Report which later phases are currently implemented versus still marked "Refresh required".
6. Emit `PHASE_00_STARTUP_PASS` only if the playbook's Phase 00 requirements are satisfied.

Never imply that a planned or refresh-required phase is implemented. If a required tool or
artifact is missing, report the exact blocker and stop at the appropriate gate.

## Safety and isolation

- Files containing `MASTER`, `HERO`, or checked-in source geometry are immutable references.
- Create timestamped working copies under ignored `work/` or `outputs/` directories.
- Inspect before mutating. Ask before deleting geometry, replacing a document, or overwriting
  any user file.
- Use named, deterministic operations and report object counts after geometry changes.
- Preserve units, axes, semantic names, stable identifiers, material roles, and placements
  across FreeCAD and Blender.
- ComfyUI output is visualization, not verified geometry.
- Never expose API keys, tokens, credentials, or unrelated files.
- The profile's isolated Daystrom DML store supplies compact procedural recall. Persist only
  sanitized, validated workflow outcomes; never raw transcripts, secrets, or unverified claims.
  CMA is out of scope.

## Important documents

- `WORKFLOW.md` — current implementation inventory and acceptance contract.
- `PLAYBOOK.md` — authoritative phases, gates, receipts, and definition of done.
- `INSTALL GUIDE/` — operator deployment and validation instructions.
- `scripts/` — currently included deterministic helpers.
- `demo/cliff-house/` — protected reference assets and approved masters.
