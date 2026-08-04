# cliff_house_full_build

The end-to-end Cliff House workflow for ARM64 Ubuntu on NVIDIA DGX Spark. This package is
being separated from the validated modifications demo so the complete FreeCAD → Blender →
ComfyUI build can evolve and be tested independently.

Start with [WORKFLOW.md](WORKFLOW.md), which records the extracted stages, receipts, and the
two handoffs that require a source refresh before this workflow can be called fully contained.

```text
Cloud endpoint <-> Hermes Agent for Windows <-> Rhino MCP <-> Rhino 8
                                         \-> Blender MCP <-> Blender
                                         \-> local ComfyUI (NVIDIA CUDA)
```

The Windows and DGX Spark playbooks exclude DML/CMA memory. Both platforms exclude Mission Control,
DirectML, application installers, model weights, logs, caches, and credentials.

## Quick start

1. Open PowerShell in this repository.
2. Run the bootstrap:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\installer\Install-LocalAEC.ps1
   ```

3. Copy `config/hermes/config.template.yaml` to the profile path printed by the installer,
   then replace the endpoint URL and model identifier.
4. Put `AEC_ENDPOINT_API_KEY=...` in `%LOCALAPPDATA%\hermes\.env`.
5. Run `.\installer\Test-LocalAEC.ps1`, start Rhino and Blender, and launch Hermes with
   `.\installer\Start-LocalAEC.ps1`.

Choose a playbook:

- [Windows with Rhino, Blender, and a cloud endpoint](INSTALL%20GUIDE/README.md)
- [DGX Spark with FreeCAD and local vLLM](INSTALL%20GUIDE/LINUX%20DGX%20SPARK/README.md)

## Repository layout

- `INSTALL GUIDE/` — numbered, copy-ready setup and rollback guides.
- `config/hermes/` — secret-free Hermes profile template.
- `demo/cliff-house/` — source masters and the migrated FreeCAD model.
- `installer/` — idempotent bootstrap, health check, and launcher scripts.
- `scripts/` — deterministic demo and ComfyUI helper scripts.

## Security model

MCP servers execute local application actions. Use this demo on a trusted workstation,
review requested mutations before approval, and never commit `%LOCALAPPDATA%\hermes\.env`
or a populated profile. The default MCP hosts bind only to loopback.
