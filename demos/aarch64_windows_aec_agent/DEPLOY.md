# Windows on ARM deployment and test guide

This is the operator guide for the two Cliff House demos. A successful installation ends with two
desktop shortcuts and two real Hermes profile directories—one for each workflow.

## Requirements

Required for both demos:

- Windows 11 on ARM64.
- Rhino 8, activated and able to open a `.3dm` document.
- Hermes Desktop installed and opened at least once.
- Python 3.11 or newer and Git available on `PATH`.
- Internet access for first installation and inference.
- An NVIDIA inference API key with access to `switchyard/openai/gpt-5.6-sol`.

See [INFERENCE_ENDPOINT.md](INFERENCE_ENDPOINT.md) for the exact endpoint, model, API mode,
credential behavior, independent connectivity test, and error guide.

Blender, Blender MCP, ComfyUI, and NVIDIA GPU drivers are optional for the initial Rhino test. They
are required only for later visualization and rendering phases.

The installer supplies the hardened AEC RhinoMCP plug-in. Do **not** separately install or register
the upstream RhinoMCP server in Hermes. Hermes sees only the typed AEC sidecar tools.

## Install

1. Close Rhino and Hermes Desktop.
2. Open PowerShell in this directory.
3. Run:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Deploy-AECDemos.ps1
   ```

4. If prompted, paste the NVIDIA API key. It is written only to the two local demo profile
   environments and is never added to Git.
5. Wait for `AEC_DEMOS_DEPLOYED`.

The installer is safe to rerun. It installs the runtime version pinned in
`../hermes-aec-runtime.version`, installs the bundled Rhino plug-in, configures loopback port
`1999`, seeds separate workflow-memory stores, and creates:

- **AEC House Modification**
- **AEC Full Build**

Existing managed configurations and plug-ins are backed up before replacement.

Verify the inference provider separately before opening a demo:

```powershell
.\Test-InferenceEndpoint.ps1
```

## Verify

Run:

```powershell
.\Test-AECDeployment.ps1
```

The final line must be:

```text
AEC_DEPLOYMENT_PASS
```

When Rhino is closed, the test prints an expected warning that port `1999` is offline. That warning
does not fail deployment. During a demo, the listener is valid only when port `1999` is owned by
`Rhino.exe`.

## First test: house modification

1. Double-click **AEC House Modification**. Do not open Hermes separately.
2. Wait while the launcher creates a timestamped working copy, opens it in Rhino, starts
   `AECMCPStart`, verifies the listener, selects `cliff-house-modifications-windows`, and opens the
   Hermes UI.
3. Enter:

   ```text
   Inspect the active Rhino model. Find the swimming pool, report its bounds and nearby objects,
   and frame it in the viewport. Do not modify anything.
   ```

4. Then try a bounded change:

   ```text
   Add a 1.2-metre safety fence around the pool with a 1-metre gate on the house-facing side.
   Preserve all existing geometry, verify the transaction independently, and frame the result.
   ```

Success means Hermes uses `rhino_scene_query`, `rhino_apply_operations`, and
`rhino_verify_transaction`. The protected golden master must remain unchanged.

## Second test: full build

1. Close the modification run and Rhino.
2. Double-click **AEC Full Build**.
3. If Rhino opens without a listener, run `AECMCPStart` once in Rhino and click the shortcut again.
4. In Hermes, enter:

   ```text
   Start the cliff house full build.
   ```

The workflow starts from `projects/cliff_house_02/rhino_assets/base_model.3dm`, follows the phase
gates and golden-build contract, and never uses the completed modification master as construction
input.

## Refresh or repair

Close Rhino and Hermes, then run:

```powershell
.\Deploy-AECDemos.ps1 -RhinoPort 1999 -Force
.\Test-AECDeployment.ps1
```

Do not change ports merely because a listener failed. First close duplicate Rhino processes and
rerun on `1999`. Never expose raw Rhino scripting tools to the modification profile.

## Expected installed state

- Hermes profiles: `cliff-house-full-build-windows` and
  `cliff-house-modifications-windows`. Hermes also displays its undeletable built-in `default`
  shell, which is not a demo profile.
- Rhino transport: hardened AEC RhinoMCP on `127.0.0.1:1999`.
- Legacy Rhino fallback: disabled.
- Desktop: exactly the two AEC shortcuts listed above.
- Runtime and memory stores: `%LOCALAPPDATA%\hermes\integrations`.
