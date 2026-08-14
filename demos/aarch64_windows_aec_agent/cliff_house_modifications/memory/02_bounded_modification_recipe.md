memory_summary: Derive and validate any requested addition or edit from inspected Rhino geometry.
memory_class: procedural_tool_call

For additions, transforms, attribute changes, or removals, derive targets and dimensions from `rhino_scene_query`; never invent global coordinates or select by visual guess alone. Express the smallest complete change with typed operations, semantic names, and explicit layers. Verify the transaction against request-specific invariants: intended targets changed, unrelated stable IDs remain, created IDs and object-count delta agree, resulting bounds and attributes are correct, and required clearances or relationships hold. Save only the timestamped working copy and return concise evidence.
