# Upstream provenance

- Repository: <https://github.com/stwagstaff/2026_aec_cptx_demo>
- Imported revision: `09b15e6c9a74b4a018587420eaaa2f5e273fd447`
- Source workflow: `aa_demo_versions/cliff_house_02`
- Rhino source-model SHA-256: `DDACAC2BA0CEA8DF75A1B02B9214C64BBCBF4B5D214E60C67DAC94A32E7272D0`

Linux does not use the Rhino `.3dm` directly. `scripts/extract_rhino_reference.py` produces
`projects/cliff_house_02/freecad_reference/source_curves.json`, containing all ten source curves
and six labels, their upstream IDs and layers, exact polyline vertices, NURBS control data, and a
64-segment evaluation used to reconstruct smooth FreeCAD guide splines. Coordinates are converted
from the upstream file's millimetres to the FreeCAD workflow's metres.

Completed `.FCStd`, STEP, Rhino, OBJ, and Blender assets under `demo/cliff-house/` are protected
comparison/migration references. They are not construction inputs for the full-build workflow.
