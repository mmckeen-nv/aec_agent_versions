# Demo scripts

## Blender scene helper

Load `blender_cliff_quick.py` through Blender MCP or Blender's scripting workspace. Call
`open_verified_quick(<repository-root>)` to create and open a verified working copy.

## ComfyUI reference-image client

Create an isolated environment, install the small client dependencies, then inspect help:

```powershell
uv venv .venv --python 3.11
uv pip install --python .\.venv\Scripts\python.exe -r .\scripts\requirements.txt
.\.venv\Scripts\python.exe .\scripts\comfyui_flux2_direct.py --help
```

The helper expects the FLUX.2 model, text encoder, and VAE named by its command-line options
to already exist in ComfyUI. The repository does not download or redistribute weights.

## Rhino to FreeCAD migration

Export the Rhino document to STEP from Windows, import it into a native FreeCAD document on
Linux, and audit the converted solid geometry with:

- `export_rhino_to_step.py`
- `import_step_to_freecad.py`
- `audit_freecad_geometry.py`
- `prepare_freecad_view.py` (run with the GUI-capable `freecad` launcher)
- `export_rhino_pool_mesh.py` and `add_rhino_pool_to_freecad.py` preserve the
  pool shell and water meshes that STEP cannot carry.

`installer/Export-RhinoToStep.ps1` drives the Rhino export through COM. Run the import and
audit scripts with `freecadcmd` on the DGX Spark.
