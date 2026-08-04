# Deterministic FreeCAD-to-Blender handoff

Phase 07 must export visible, audited FreeCAD objects in stable-ID order to a generated bundle:

```text
work/freecad_blender_bundle/
  geometry/<stable_id>.obj
  scene_manifest.json
  SHA256SUMS.txt
```

The manifest records names, hierarchy, roles, source constraints, transforms, units, bounds,
mesh counts, and hashes. Blender reconstructs collections and custom properties from this
manifest and verifies counts, bounds, and hashes. Loading the checked-in quick master is not a
valid handoff.

If the deterministic exporter/importer is not implemented, Phase 07 must stop at its gate.

