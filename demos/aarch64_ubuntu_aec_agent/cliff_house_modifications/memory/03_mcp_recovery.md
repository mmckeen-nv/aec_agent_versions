memory_summary: Recover from FreeCAD MCP failure with one bounded diagnostic sequence.
memory_class: procedural_tool_call

Use only FreeCAD tools registered in Hermes. If a call fails, report the exact tool and error, refresh the MCP connection once, and retry a read-only document inventory. If reads work, test one harmless create/query/delete transaction before the requested edit. Do not guess REST endpoints and do not claim changes without post-operation object and shape evidence. If the bridge stays unavailable, ask the operator to start the FreeCAD MCP workbench bridge on loopback port 9875.
