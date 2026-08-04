# Step 3 — Complete Hermes OOBE

1. Open Hermes Desktop normally. Do not launch it through a repository script.
2. Complete the product's first-run flow and choose any supported inference provider/model.
3. Store credentials only through Hermes' normal user configuration.
4. Use a profile isolated from the quick-modification demo.
5. Register this workspace after OOBE:

```powershell
.\installer\Register-HermesProject.ps1 -Profile '<your-full-build-profile>'
```

Then attach Rhino MCP and Blender MCP through Hermes' normal profile UI. Do not copy configuration
from another demo. The script never launches Hermes or changes inference/MCP configuration.
