# AEC demos — Windows deployment and test guide

## Requirements

- Windows 11 on ARM64.
- Rhino 8, activated and able to open a document.
- RhinoMCP is installed automatically through Rhino's Yak package manager. The hardened plug-in uses `AECMCPStart`; while the deployment is pinned to upstream 0.3.2, use `MCPStart`.
- Hermes Desktop installed. Both demo shortcuts open the graphical consumer UI; no terminal or
  Hermes TUI is part of the demo experience.
- Git and Python 3.11 or newer. The deployer installs the pinned Daystrom DML memory harness and
  the pinned `hermes-aec-runtime` typed Rhino sidecar into
  Hermes' local integration directory; no Ollama, embedding model, CMA, or extra inference model
  is required.
- NVIDIA inference API key with access to `switchyard/openai/gpt-5.6-sol`.
- Internet access for inference requests and the first Daystrom DML installation.

Blender, Blender MCP, ComfyUI, and NVIDIA GPU drivers are needed only for later rendering phases,
not for the first Rhino construction or modification test.

## Deploy once

1. Close Rhino for the initial install. The deployment script installs the plug-in and runtime.
2. Open PowerShell in this directory.
3. Run:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Deploy-AECDemos.ps1
   ```

The installer uses RhinoMCP's structured transport on loopback port `1999`, installs the pinned DML runtime and Hermes AEC runtime, seeds a small procedural-memory
pack into a separate store for each demo, deploys two isolated Hermes profiles, securely asks for
the API key only if necessary, and creates **AEC Full Build** and **AEC House Modification** on the Desktop.
Each shortcut runs its setup invisibly and opens the Hermes Desktop UI pinned to the correct profile.

After installation, restart Rhino once and run `AECMCPStart` with port `1999` (`MCPStart` on
upstream 0.3.2). Hermes only sees the typed sidecar tools; it cannot call RhinoMCP or raw Rhino
scripts directly.

Memory retrieval is automatic. The operator does not need to mention DML. The seed contains tested
application-command sequences and validation/recovery rules—not transcripts or a verbatim skill.

## Verify deployment

```powershell
.\Test-AECDeployment.ps1
```

The final line should be `AEC_DEPLOYMENT_PASS`. A stopped Rhino MCP listener is reported as a
warning; start it before launching a demo.

## Test 1 — quick house modification

Use this first.

1. Double-click **AEC House Modification**.
2. The launcher creates and opens a timestamped copy of the completed Rhino house. It never edits
   the checked-in hero model.
3. Ensure Rhino MCP is running.
4. Enter a concise outcome request in Hermes, for example:

   ```text
   Audit the open working copy. Move the selected canopy 300 mm east. Preserve every other object,
   validate the result, and report exactly what changed.
   ```

Success means Hermes recalls the Rhino execution recipe, audits the scene, performs the Rhino MCP
operation through `rhino_scene_query`, `rhino_apply_operations`, and
`rhino_verify_transaction`, and verifies that only the intended working-copy geometry changed.
For another task, use the same four-part request: target, desired result, constraints, and evidence.

## Test 2 — complete house build

1. Create a new empty, unmodified Rhino document.
2. Ensure Rhino MCP is running.
3. Double-click **AEC Full Build**.
4. Enter:

   ```text
   Start the cliff house full build.
   ```

Hermes imports the supplied `cliff_house_02` source curves once, follows the phase gates, and
constructs the house. It must not use the completed hero model.

Some Rhino MCP versions restart their listener after a document import. If the connection drops
immediately after the source model imports, restart Rhino MCP on a free port and run:

```powershell
.\Deploy-AECDemos.ps1 -RhinoPort 10501 -Force
```

Continue the same demo; do not import the source model twice.

## Workflow boundary

| Shortcut | Input | Safety behavior |
|---|---|---|
| AEC Full Build | Wagstaff source curves | Builds all target geometry; completed hero is comparison-only |
| AEC House Modification | Completed Rhino house | Creates a timestamped working copy before opening Rhino |

## Refresh after pulling updates

```powershell
.\Deploy-AECDemos.ps1 -Force
.\Test-AECDeployment.ps1
```

Existing profile configurations are backed up before replacement. Credentials and generated work
remain outside Git.

The sidecar release is pinned once in `../hermes-aec-runtime.version`. Maintainers update that
single file only after the corresponding GitHub release exists and passes both deployment tests.
