# Step 7 — Troubleshoot

## Hermes does not see the profile

Confirm the path and YAML placeholders:

```powershell
Test-Path "$env:LOCALAPPDATA\hermes\profiles\local-aec-cloud\config.yaml"
Select-String -Path "$env:LOCALAPPDATA\hermes\profiles\local-aec-cloud\config.yaml" `
  -Pattern 'REPLACE_WITH'
```

Any placeholder match must be replaced.

## Cloud endpoint returns 401 or 403

- Confirm `%LOCALAPPDATA%\hermes\.env` contains `AEC_ENDPOINT_API_KEY`.
- Restart Hermes after changing `.env`.
- Confirm the key is authorized for the configured model.
- Do not paste the key into logs or issue reports.

## Rhino MCP is absent

```powershell
& 'C:\Program Files\Rhino 8\System\Yak.exe' list
```

If `Rhino-MCP-Platform (0.1.5)` is missing, reinstall it and restart Rhino. Rhino loads newly
installed Yak packages on its next launch.

## Blender MCP cannot connect

- In Blender, open **3D View > Sidebar > BlenderMCP** and click **Start MCP Server**.
- Confirm the add-on port is `9876`.
- Confirm no other process owns the port:

```powershell
Get-NetTCPConnection -LocalPort 9876 -ErrorAction SilentlyContinue
```

## ComfyUI is slow or reports CPU

Open ComfyUI maintenance settings and select/reinstall the NVIDIA runtime. Do not install
`torch-directml`. Verify:

```powershell
Invoke-RestMethod http://127.0.0.1:8188/system_stats | ConvertTo-Json -Depth 6
```

The device description should identify CUDA/NVIDIA.

## One health check remains red

Run `.\installer\Test-LocalAEC.ps1`, fix only the failing row, and rerun it. Avoid reinstalling
the entire stack until the component-specific check has been exhausted.
