# Step 8 — Cleanup and rollback

Rollback is component-scoped. Back up working CAD/DCC files before removing software.

## Remove only this Hermes profile

Close Hermes, verify the exact path, then remove it:

```powershell
$profile = "$env:LOCALAPPDATA\hermes\profiles\local-aec-cloud"
Resolve-Path $profile
Remove-Item -LiteralPath $profile -Recurse
```

Remove `AEC_ENDPOINT_API_KEY` from `%LOCALAPPDATA%\hermes\.env` if no other profile uses it.

## Remove MCP integrations

```powershell
uv tool uninstall blender-mcp
& 'C:\Program Files\Rhino 8\System\Yak.exe' uninstall Rhino-MCP-Platform
```

Restart Rhino after uninstalling the Yak package. Disable or remove the BlenderMCP add-on
from Blender Preferences.

## Remove applications

Use **Settings > Apps > Installed apps** for Rhino, Blender, and ComfyUI. Hermes provides:

```powershell
hermes uninstall
```

Hermes uninstall preserves user configuration by design. Remove its data directory only after
reviewing and backing up profiles, sessions, and skills.

## Remove generated demo data

Only delete working copies and renders you intentionally created. The checked-in `HERO` and
`MASTER` files are source assets and can be restored from Git.
