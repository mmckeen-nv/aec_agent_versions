# Step 5 — Run the Cliff House full-build demo

Start every local application before asking Hermes to use its MCP tools.

## Start ComfyUI

Launch ComfyUI Desktop, select the NVIDIA runtime, and wait for the UI at:

```text
http://127.0.0.1:8188
```

Import your approved workflow and install its required models through ComfyUI. Model weights
are intentionally not stored in this repository.

## Bind the isolated Hermes project

Run this once from the cloned repository:

```bash
./platform/linux-dgx-spark/scripts/configure-hermes-project.sh
```

This registers only this directory as the `cliff-house-full-build` project, activates it only
inside the matching Hermes profile, and installs a launcher that starts in this workspace.
It does not choose an inference provider, copy credentials, or configure another demo.

## Prepare application working documents

1. Start FreeCAD and its MCP bridge. Do not overwrite `cliff_house_FREECAD_MASTER.FCStd`.
2. Start Blender and BlenderMCP. Treat `cliff_house_QUICK_MASTER.blend` as a protected
   reference, not as a substitute for the planned deterministic FreeCAD-to-Blender handoff.
3. Keep all generated documents under ignored `work/` or `outputs/` directories.

Never overwrite a file containing `HERO` or `MASTER`.

## Start Hermes

```bash
cliff-house-full-build
```

Suggested first prompt:

```text
Start the cliff house build.
```

Hermes loads `AGENTS.md`, `WORKFLOW.md`, and `PLAYBOOK.md` from the bound workspace. It begins
or resumes Phase 00, reports service and implementation state, and does not mutate geometry
before the relevant review gate.

After the inspection succeeds, use narrowly scoped prompts and approve geometry mutations
only when the intended target is explicit.

## Expected result

Hermes recognizes the full-build workflow without further explanation, selects Phase 00 (or
the next phase after a valid receipt), reports FreeCAD, Blender, and ComfyUI availability, and
performs no mutation during the first inspection turn.

## Next step

Continue to [verify the stack](06-verify-stack.md).
