memory_summary: Build requested FreeCAD additions from inspected source geometry with semantic names.
memory_class: procedural_tool_call

For additions such as a pool fence, derive paths and dimensions from inspected source-object shapes and bounding boxes; never invent global coordinates. Create an `App::Part` or group with stable semantic labels, create deterministic Part geometry for posts, rails, panels, and gates, and retain editable properties for spacing and height. Keep additions clear of circulation and existing solids. Recompute once, require valid non-null shapes, verify combined bounds against the target, confirm no pre-existing object disappeared, save, and return a viewport image when available.
