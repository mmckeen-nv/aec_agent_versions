# Cliff House modifications — Windows ARM64

The quick live-demo workflow for controlled, reversible edits to protected Cliff House Rhino and
Blender masters. Hermes Desktop completes normal OOBE before this workspace is attached to a
user-selected profile.

```text
User-selected inference <-> Hermes Desktop
                            |-> Rhino MCP <-> Rhino 8
                            |-> Blender MCP <-> Blender
                            \-> ComfyUI on NVIDIA CUDA
```

## Start here

1. Follow the numbered [INSTALL GUIDE](INSTALL%20GUIDE/README.md).
2. Complete Hermes OOBE without repository-provided settings.
3. Register this directory as `cliff-house-modifications-windows` in the profile you selected.
4. Create timestamped working copies from the protected masters.
5. Start Rhino, Blender, ComfyUI, and the required loopback MCP bridges.

No installer writes a Hermes provider, model, endpoint, API key, active profile, or desktop
configuration. DML/CMA, Mission Control, application binaries, model weights, runtime state,
logs, caches, and credentials are excluded.
