memory_summary: Use registered MCP tools directly and recover from failures with bounded tests.
memory_class: procedural_tool_call

Use only tools currently registered by Hermes. Do not discover Rhino by guessing HTTP command endpoints. If a tool fails, capture its exact error, refresh the MCP connection once, run a read-only inventory call, then test a harmless bounded create/query/delete cycle before resuming the active phase. Do not replace MCP work with foreground UI automation. If the bridge remains unavailable, stop at the current gate and state the exact restart needed; never emit a phase receipt without its evidence.
