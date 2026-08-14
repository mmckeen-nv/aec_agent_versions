memory_summary: Build requested FreeCAD additions from inspected source geometry with semantic names.
memory_class: procedural_tool_call

For any addition or edit, derive targets, paths, and dimensions from inspected source-object shapes, properties, and bounding boxes; never invent global coordinates. Prefer typed FreeCAD MCP operations. When the bridge lacks a required typed operation, use one reviewed, bounded `execute_code` transaction with stable semantic labels and editable properties. Recompute once, require valid non-null shapes, verify request-specific bounds and relationships, confirm no unrelated object disappeared, save only the working copy, and return a viewport image when useful.
