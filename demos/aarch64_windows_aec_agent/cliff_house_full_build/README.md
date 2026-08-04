# Cliff House full build — Windows ARM64

The original phase-driven NVIDIA AEC workflow for Hermes Desktop, Rhino 8, Blender, and ComfyUI
on Windows ARM64. It is isolated from the quick-modification demo and begins with an empty Rhino
document rather than a protected master.

```text
User-selected inference <-> Hermes Desktop (after OOBE)
                            |-> Rhino MCP <-> Rhino 8
                            |-> Blender MCP <-> Blender
                            \-> ComfyUI on NVIDIA CUDA
```

## Start here

1. Follow the numbered [INSTALL GUIDE](INSTALL%20GUIDE/README.md).
2. Complete normal Hermes OOBE and select the inference provider yourself.
3. Register this directory as `cliff-house-full-build-windows` in a dedicated profile/project.
4. Start Rhino, Blender, ComfyUI, and their loopback MCP bridges.
5. Tell Hermes: `Start the cliff house build.`

Hermes reads `AGENTS.md`, the project brief, phase state, skills, and the original active prompt
under `system_prompts/`. Generated geometry, scenes, renders, receipts, and logs belong under
ignored `work/` or `outputs/` directories.

No provider, model, endpoint, credential, profile, or MCP registration is baked into this package.
DML and CMA are intentionally excluded.
