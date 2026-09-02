# Step 3 — Install the typed application bridge

Run the top-level `Deploy-AECDemos.ps1`. It installs the pinned RhinoMCP plug-in and the Hermes AEC
sidecar. Restart Rhino and leave it open. The plug-in loads at startup and automatically binds its
loopback listener on port `1999`; `AECMCPStart` is retained only for manual repair.

Do not add RhinoMCP directly to Hermes. The full-build profile exposes only the sidecar's typed,
transactional allowlist. BlenderMCP is added later for rendering phases.

Continue to [complete Hermes OOBE](04-configure-cloud-endpoint.md).
