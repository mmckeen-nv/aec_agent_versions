"""Enable BlenderMCP and record the exact Blender process owning the demo bridge."""

import bpy
import json
import os
import socket
import subprocess
from datetime import datetime, timezone
from pathlib import Path


os.environ["DISABLE_TELEMETRY"] = "true"
PORT = 9876
MARKER = Path(os.environ.get("LOCALAPPDATA", Path.home())) / "hermes" / "integrations" / "blender-mcp" / "active-instance.json"


def _port_open():
    with socket.socket() as probe:
        probe.settimeout(0.2)
        return probe.connect_ex(("127.0.0.1", PORT)) == 0


def _listener_owner():
    if os.name != "nt":
        return None
    try:
        output = subprocess.check_output(["netstat.exe", "-ano", "-p", "TCP"], text=True, timeout=5)
        for line in output.splitlines():
            fields = line.split()
            if len(fields) >= 5 and fields[1].endswith(f":{PORT}") and fields[3].upper() == "LISTENING":
                return int(fields[4])
    except Exception as exc:
        print(f"HERMES_AEC_BLENDER_OWNER_PROBE_FAILED {exc}")
    return None


def _record_owner():
    if not _port_open():
        return 0.5
    MARKER.parent.mkdir(parents=True, exist_ok=True)
    temporary = MARKER.with_suffix(".tmp")
    temporary.write_text(json.dumps({
        "schema_version": 1,
        "process_id": os.getpid(),
        "port": PORT,
        "blender_version": list(bpy.app.version),
        "started_at": datetime.now(timezone.utc).isoformat(),
    }), encoding="utf-8")
    temporary.replace(MARKER)
    print(f"HERMES_AEC_BLENDER_INSTANCE_READY port={PORT} pid={os.getpid()} marker={MARKER}")
    return None


def _start_blender_mcp():
    try:
        if _port_open():
            owner = _listener_owner()
            if owner == os.getpid():
                _record_owner()
                print(f"HERMES_AEC_BLENDER_MCP_ALREADY_READY port={PORT} pid={owner}")
            else:
                print(f"HERMES_AEC_BLENDER_MCP_SKIPPED port={PORT} reason=occupied owner={owner} pid={os.getpid()}")
            return None
        if "blender_mcp" not in bpy.context.preferences.addons:
            bpy.ops.preferences.addon_enable(module="blender_mcp")
        bpy.ops.blendermcp.start_server()
        bpy.app.timers.register(_record_owner, first_interval=0.5)
        print(f"HERMES_AEC_BLENDER_MCP_STARTING port={PORT} pid={os.getpid()}")
    except Exception as exc:
        print(f"HERMES_AEC_BLENDER_MCP_FAILED {exc}")
    return None


if not bpy.app.background:
    bpy.app.timers.register(_start_blender_mcp, first_interval=4.0)
