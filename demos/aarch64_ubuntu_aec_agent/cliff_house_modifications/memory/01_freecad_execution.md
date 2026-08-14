memory_summary: Execute bounded FreeCAD modifications through the registered MCP bridge.
memory_class: procedural_tool_call

Create a timestamped working copy with `platform/linux-dgx-spark/scripts/prepare-working-copy.sh`, then open only that copy. Inspect the active document, object count, labels, validity, and bounds through registered FreeCAD MCP tools. Prefer typed tools; use `execute_code` only for one complete deterministic FreeCAD Python operation. Recompute after mutation, report changed object names and before/after counts, validate shapes and bounds, then save the working copy. Never edit checked-in FCStd, STEP, Rhino, OBJ, Blender MASTER, or HERO assets.
