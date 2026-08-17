# Cliff House AEC demos — Windows on ARM

This package installs two Hermes Desktop demos for Rhino 8:

| Desktop shortcut | Purpose | Starting geometry |
|---|---|---|
| **AEC House Modification** | Make bounded changes to a completed house | A new disposable copy of the protected golden master |
| **AEC Full Build** | Construct the house phase by phase | Wagstaff source curves, never the completed model |

## Install

Read [DEPLOY.md](DEPLOY.md) for the requirements and verified installation procedure. The entire
package is installed with one command:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Deploy-AECDemos.ps1
```

The installer deploys the two isolated Hermes profiles, the pinned Hermes AEC runtime, the bundled
hardened RhinoMCP plug-in, workflow memory, and both desktop shortcuts. Users do not install a
separate Rhino MCP server.

After installation, use only the two desktop shortcuts. They select the correct Hermes profile and
open the graphical Hermes UI automatically.

## More detail

- [Inference endpoint and API-key setup](INFERENCE_ENDPOINT.md)
- [House modification workflow](cliff_house_modifications/README.md)
- [Full-build workflow](cliff_house_full_build/README.md)
- [Requirements, deployment, testing, and recovery](DEPLOY.md)

Credentials, sessions, logs, generated models, renders, and application preferences remain local
to the workstation and are not repository content.
