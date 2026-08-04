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
5. `projects/cliff_house_01/user_prompts/project_prompt.md`
6. the active phase prompt under `system_prompts/`

Begin Phase 00 or resume the next incomplete phase represented by a valid receipt. State the
selected phase and perform its read-only preflight. Do not mutate geometry before its review gate.

## Pipeline

1. Rhino MCP creates and validates the architectural model from an empty document.
2. Phase 07 transfers audited geometry and metadata to Blender.
3. Blender MCP assembles materials, cameras, lighting, and renders.
4. ComfyUI performs geometry-locked architectural visualization.
5. Each phase emits the receipt required by the active prompt.

Never load or import the checked-in hero Rhino file, quick Blender master, or another completed
model as a full-build shortcut.

## OOBE and safety

- Hermes provider, model, endpoint, credentials, profile, and MCP configuration are user-owned.
- Do not change inference configuration or activate another profile.
- Files containing `MASTER` or `HERO` are immutable references.
- Work only in timestamped ignored `work/` or `outputs/` directories.
- Inspect before mutation and ask before deletion, replacement, or overwrite.
- Preserve units, axes, semantic names, layer paths, identifiers, materials, and placements.
- ComfyUI output is visualization, not verified geometry.
- Never expose secrets or unrelated files.
- DML and CMA are out of scope.
