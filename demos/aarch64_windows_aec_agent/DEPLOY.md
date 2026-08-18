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

Blender and ComfyUI are independent opt-in deployment features. The installer asks about each.
Answering No skips that component without failing the Rhino deployment. If Blender is selected,
install Blender before deployment so the installer can add and auto-start pinned BlenderMCP 1.8.3.
If ComfyUI is selected, deployment downloads the pinned NVIDIA build and approximately
13 GB of FLUX.2 Klein model files; use a fast, stable connection because tradeshow internet may fail.

The installer supplies the hardened AEC RhinoMCP plug-in. Do **not** separately install or register
the upstream RhinoMCP server in Hermes. Hermes sees only the typed AEC sidecar tools.

Python is not a separate prerequisite. Deployment uses the Python bundled with Hermes Desktop or
automatically installs an isolated Python 3.12 runtime through Hermes' bundled `uv`. The installer
checks Rhino, Hermes/OOBE, its managed Python bootstrap, and Git before changing the machine.

## Install

1. Close Rhino and Hermes Desktop.
2. Open PowerShell or Command Prompt in this directory.
3. Run the policy-safe launcher:

   ```bat
   .\Deploy-AECDemos.cmd
   ```

   The launcher bypasses PowerShell execution policy only for its child installer process; it does
   not change the user or machine policy. If deployment fails, it keeps the window open until
   Enter is pressed. Correct the displayed problem and rerun the same command.

   Operators running the PowerShell script directly must first use
   `Set-ExecutionPolicy -Scope Process Bypass`. `-NoPauseOnError` is reserved for automation.

4. If prompted, paste the NVIDIA API key. It is written only to the two local demo profile
   environments and is never added to Git.
5. Answer the independent Blender and ComfyUI questions. Both default to No.

On Windows ARM64, ComfyUI is installed natively inside WSL2 Ubuntu 24.04 with the CUDA 13
PyTorch build. Install WSL2 first with `wsl --install -d Ubuntu-24.04` and restart Windows if
requested. The installer copies the model weights into WSL's Linux filesystem and manages a
systemd service on port 8188; it does not run the incompatible x64 Windows portable build under
emulation. On x64 Windows, the pinned NVIDIA portable build remains the supported backend.
6. Wait for `AEC_DEMOS_DEPLOYED`; its final line records both selections.

The installer is safe to rerun. It installs the runtime version pinned in
`../hermes-aec-runtime.version`, installs the bundled Rhino plug-in, configures loopback port
`1999`, seeds separate workflow-memory stores, and creates:

- **AEC House Modification**
- **AEC Full Build**

Existing managed configurations and plug-ins are backed up before replacement.

Verify the inference provider separately before opening a demo:

```bat
.\Test-InferenceEndpoint.cmd
```

## Verify

Run:

```bat
.\Test-AECDeployment.cmd
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

```bat
.\Deploy-AECDemos.cmd -RhinoPort 1999 -Force
.\Test-AECDeployment.cmd
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

## Uninstall

Close Hermes Desktop and every Rhino window, then run:

```bat
.\Uninstall-AECDemos.cmd
```

Type `UNINSTALL` at the confirmation prompt. The uninstaller removes only the two managed profiles,
their credential files, the two shortcuts, Daystrom DML, Hermes AEC runtime versions, demo state,
and the managed AEC RhinoMCP plug-in and registration. It then asks whether to uninstall Rhino 8.
Answer `y` to invoke Rhino's registered McNeel uninstaller; a Windows elevation prompt may appear.
The repository and generated project/work files are preserved.
