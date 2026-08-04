# Step 3 — Configure Rhino MCP and Blender MCP

MCP gives Hermes typed, local tools for Rhino and Blender. Both application bridges remain
on the workstation; only model inference crosses the cloud boundary.

## Install Rhino MCP Platform

Close Rhino, then run:

```powershell
& 'C:\Program Files\Rhino 8\System\Yak.exe' install Rhino-MCP-Platform 0.1.5
```

Restart Rhino. The package router is installed below:

```text
%APPDATA%\McNeel\Rhinoceros\packages\8.0\Rhino-MCP-Platform\0.1.5\router\win-x64\
```

## Install Blender MCP

```powershell
winget install --id astral-sh.uv --exact
uv tool install --force --with "mcp<2" blender-mcp
```

The expected stdio server is `%USERPROFILE%\.local\bin\blender-mcp.exe`. The repository
bootstrap also downloads the upstream Blender add-on and enables it. To enable it manually,
install `addon.py` from the [Blender MCP repository](https://github.com/ahujasid/blender-mcp)
through Blender **Preferences > Add-ons**, then open **3D View > Sidebar > BlenderMCP** and
start the server on `localhost:9876`.

## Confirm both servers

```powershell
Get-ChildItem "$env:APPDATA\McNeel\Rhinoceros\packages\8.0\Rhino-MCP-Platform" `
  -Filter rhino-mcp-router.exe -Recurse
Test-Path "$env:USERPROFILE\.local\bin\blender-mcp.exe"
```

Expected result: the Rhino router is listed and the Blender MCP check returns `True`.

## Next step

Continue to [configure the cloud endpoint](04-configure-cloud-endpoint.md).
