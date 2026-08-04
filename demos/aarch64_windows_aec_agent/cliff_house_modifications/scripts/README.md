# Quick-demo helpers

- `blender_cliff_quick.py` validates and renders a working copy of the quick Blender scene.
- `export_rhino_pool_mesh.py` and `export_rhino_to_step.py` are optional migration utilities;
  they are not part of Hermes OOBE or the normal quick-edit path.
- `comfyui_flux2_direct.py` is a downstream visualization helper and requires its documented
  external workflow/model dependencies.

Run helpers only against ignored working copies. Never overwrite checked-in masters.
