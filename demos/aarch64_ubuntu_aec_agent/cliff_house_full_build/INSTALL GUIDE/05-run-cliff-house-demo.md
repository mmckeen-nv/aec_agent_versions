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

## Prepare the applications

1. Start FreeCAD and its MCP bridge. Do not open or overwrite a master document.
2. Start Blender and BlenderMCP. Do not open or import the protected Blender master.
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

To run the saved deterministic test workflow directly, follow [RUN_WORKFLOW.md](../RUN_WORKFLOW.md).
It reconstructs the pinned source guides in a clean FreeCAD document, creates the handoff manifest, assembles the Blender
scene, and emits `FULL_BUILD_TEST_RENDER_PASS` when the render succeeds.

## Expected result

Hermes recognizes the full-build workflow without further explanation, selects Phase 00 (or
the next phase after a valid receipt), reports FreeCAD, Blender, and ComfyUI availability, and
performs no mutation during the first inspection turn.

## Next step

Continue to [verify the stack](06-verify-stack.md).
