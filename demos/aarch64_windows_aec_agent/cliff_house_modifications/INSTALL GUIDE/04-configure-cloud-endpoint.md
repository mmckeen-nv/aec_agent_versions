# Profile and inference configuration

Run the top-level `Deploy-AECDemos.ps1`; do not attach RhinoMCP directly through the Hermes UI.
The installer creates `cliff-house-modifications-windows`, configures the NVIDIA Responses
endpoint, stores the API key only in that local profile environment, and registers the typed AEC
sidecar on Rhino port `1999`.

See [../../DEPLOY.md](../../DEPLOY.md) for the supported command and verification procedure.
