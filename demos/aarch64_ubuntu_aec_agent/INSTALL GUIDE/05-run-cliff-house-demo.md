# Step 5 — Run the Cliff House demo

Start every local application before asking Hermes to use its MCP tools.

## Start ComfyUI

Launch ComfyUI Desktop, select the NVIDIA runtime, and wait for the UI at:

```text
http://127.0.0.1:8188
```

Import your approved workflow and install its required models through ComfyUI. Model weights
are intentionally not stored in this repository.

## Open copies of the demo masters

1. Open `demo/cliff-house/cliff_house_HERO_RHINO_MODEL.3dm` in Rhino.
2. Immediately save a working copy outside the repository.
3. Open `demo/cliff-house/cliff_house_QUICK_MASTER.blend` in Blender.
4. Immediately save a working copy, then start BlenderMCP from the sidebar.

Never overwrite a file containing `HERO` or `MASTER`.

## Start Hermes

```powershell
.\installer\Start-LocalAEC.ps1
```

Suggested first prompt:

```text
Inspect the open Rhino and Blender documents without changing them. Report document units,
object counts, named cameras, and MCP connectivity. Do not delete or create geometry.
```

After the inspection succeeds, use narrowly scoped prompts and approve geometry mutations
only when the intended target is explicit.

## Expected result

Hermes lists Rhino and Blender MCP tools, describes both documents, and performs no mutation
during the first inspection turn.

## Next step

Continue to [verify the stack](06-verify-stack.md).
