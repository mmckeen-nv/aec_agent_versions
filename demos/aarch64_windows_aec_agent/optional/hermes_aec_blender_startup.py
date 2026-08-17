"""Enable BlenderMCP and start its loopback server for the opted-in AEC demo."""

import bpy


def _start_blender_mcp():
    try:
        if "blender_mcp" not in bpy.context.preferences.addons:
            bpy.ops.preferences.addon_enable(module="blender_mcp")
        bpy.ops.blendermcp.start_server()
        print("HERMES_AEC_BLENDER_MCP_READY port=9876")
    except Exception as exc:
        print(f"HERMES_AEC_BLENDER_MCP_FAILED {exc}")
    return None


if not bpy.app.background:
    bpy.app.timers.register(_start_blender_mcp, first_interval=4.0)
