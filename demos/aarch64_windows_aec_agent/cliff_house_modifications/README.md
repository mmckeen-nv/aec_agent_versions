# Cliff House modifications — Windows ARM64

The short live demo: Hermes opens a generated working copy of the completed Cliff House Rhino
master and makes bounded operator-requested changes. It does not rebuild the house; that is the
separate `cliff_house_full_build` workflow.

```text
User-selected inference <-> Hermes Desktop
                            |-> Rhino MCP <-> Rhino 8
                            |-> Blender MCP <-> Blender
                            \-> ComfyUI on NVIDIA CUDA
```

## Start here

1. Complete Hermes OOBE and deploy the isolated profile:

   ```powershell
   .\installer\Deploy-HermesProfile.ps1 -Profile cliff-house-modifications-windows -RhinoPort 1999
   ```

2. Create a verified timestamped working copy:

   ```powershell
   .\installer\New-WorkingCopy.ps1
   ```

3. Open only the emitted working-copy path in Rhino.
4. Start Rhino, Blender, ComfyUI, and the required loopback MCP bridges.

In the Hermes UI, request the outcome directly. For example: `Audit the working copy, move the
selected canopy 300 mm east, preserve everything else, validate the result, and report exactly
what changed.` The same pattern works for additions, removals, transforms, properties, materials,
or code-informed compliance changes: name the target, desired result, constraints, and evidence.

The deployer writes a credential-free inference/MCP profile and never stores an API key. The
checked-in `HERO` and `MASTER` assets remain immutable. Model weights, runtime state,
logs, caches, credentials, and generated working copies are excluded.
