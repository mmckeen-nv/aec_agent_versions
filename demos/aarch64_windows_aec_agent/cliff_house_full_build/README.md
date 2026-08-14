# Cliff House full build — Windows ARM64

An easy-to-deploy Hermes adaptation of the original phase-driven NVIDIA AEC workflow for Rhino 8,
Blender, and ComfyUI on Windows ARM64. It is isolated from the quick-modification demo and begins
from Wagstaff's source-curve `base_model.3dm`; it never substitutes a completed hero model.

```text
User-selected inference <-> Hermes Desktop (after OOBE)
                            |-> Rhino MCP <-> Rhino 8
                            |-> Blender MCP <-> Blender
                            \-> ComfyUI on NVIDIA CUDA
```

## Start here

1. Complete Hermes OOBE and create a dedicated profile.
2. Deploy this package into it:

   ```powershell
   .\installer\Deploy-HermesProfile.ps1 -Profile cliff-house-full-build-windows -RhinoPort 1999
   ```

3. Start Rhino, Blender, ComfyUI, and their loopback MCP bridges.
4. Run `.\installer\Test-LocalAEC.ps1 -Profile cliff-house-full-build-windows`.
5. Tell Hermes: `Start the cliff house build.`

Hermes reads `AGENTS.md`, `projects/cliff_house_02/user_prompts/project_prompt.md`, phase state,
skills, and the active prompt under `system_prompts/`. The Rhino source file is
`projects/cliff_house_02/rhino_assets/base_model.3dm`. Generated files belong under ignored
`work/` or `outputs/` directories.

The repository contains a credential-free NVIDIA Responses API template. Deployment never writes
an API key: set `NVIDIA_API_KEY` in the profile environment or through Hermes' secret UI. Provider,
model, endpoint, context length, and Rhino port remain command-line parameters.
