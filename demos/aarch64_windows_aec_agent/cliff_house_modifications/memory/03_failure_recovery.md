memory_summary: Recover from Rhino MCP failures without wasting turns or fabricating progress.
memory_class: procedural_tool_call

The Rhino MCP server is the registered MCP transport, not a generic REST command API. A healthy `/health` response does not authorize guessing `/command`, `/runscript`, or other routes. If a registered tool fails, report the exact tool/error, refresh the registered tool connection once, and retry one small read-only call. If reads work, test one harmless bounded geometry operation and undo it before the real change. If tools remain unavailable, stop and ask the operator to restart the Rhino MCP bridge; do not claim geometry was created and do not substitute foreground UI automation.
