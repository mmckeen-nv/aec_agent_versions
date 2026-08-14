# Step 3 — Install the typed application bridge

Run the top-level `Deploy-AECDemos.ps1`. It installs the pinned RhinoMCP plug-in and the Hermes AEC
sidecar. Restart Rhino and run `AECMCPStart` on loopback port `1999`,
and leave Rhino open.

Do not add RhinoMCP directly to Hermes. The modification profile exposes only the sidecar's typed,
transactional allowlist.

Continue to [complete Hermes OOBE](04-configure-cloud-endpoint.md).
