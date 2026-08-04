# Step 6 — Verify the complete stack

Run the repository health check from a PowerShell session that has the endpoint key loaded:

```powershell
$env:AEC_ENDPOINT_API_KEY = 'temporary-session-value'
.\installer\Test-LocalAEC.ps1
```

The check validates executable discovery, the Hermes profile, current-session credentials,
and the ComfyUI health endpoint. A fully ready machine ends with:

```text
LOCAL_AEC_STACK_PASS
```

## Application checks

In Hermes, request these read-only checks:

1. List connected MCP servers and tool counts.
2. Read Rhino document metadata and object counts.
3. Read Blender scene metadata, object counts, cameras, and renderer.
4. Confirm ComfyUI responds at `http://127.0.0.1:8188/system_stats`.

## Mutation safety check

On working copies only, ask Hermes to create one clearly named test point or empty, verify it,
then ask for confirmation before deletion. This proves the mutation path and approval boundary
without risking the demo geometry.

## Success criteria

- Cloud model responds through the isolated Hermes profile.
- Rhino MCP and Blender MCP both enumerate tools.
- ComfyUI reports an NVIDIA CUDA device.
- Masters remain unchanged and no secrets appear in Git status.

```powershell
git status --short
git grep -n -i -E 'api[_-]?key\s*[:=]\s*[^r]|bearer [A-Za-z0-9]'
```
