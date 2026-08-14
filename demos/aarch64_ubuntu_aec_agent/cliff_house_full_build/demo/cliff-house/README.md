# Cliff House demo assets

- `cliff_house_HERO_RHINO_MODEL.3dm` is the Rhino source master.
- `cliff_house_QUICK_MASTER.blend` is the optimized Blender source master.
- `cliff_house_FREECAD_SOURCE.step` is the neutral Rhino 8 export for Linux migration.
- `cliff_house_FREECAD_MASTER.FCStd` is the audited FreeCAD 1.1.3 import.
- `cliff_house_FREECAD_PREVIEW.png` verifies its persisted visible, fitted GUI view.
- `cliff_house_POOL_SHELL.obj` and `cliff_house_POOL_WATER.obj` preserve the two
  Rhino meshes omitted by STEP.

Treat these completed-model assets as read-only. They are comparison and migration references,
not full-build construction inputs. The full build instead reconstructs the upstream source
guides from `projects/cliff_house_02/freecad_reference/source_curves.json`. The companion
`scripts/blender_cliff_quick.py` helper validates the Blender master hash, object counts,
materials, and cameras before opening a generated working copy.

These assets are project-owner material and are not covered by the repository's MIT license.
Confirm redistribution permission before publishing the repository or a fork.

The FreeCAD master was generated from the STEP source on the DGX Spark. Its audit receipt is:

```text
features=303 valid=303 invalid=0 finite=303
solids=303 shells=303 faces=1840 edges=3690
bounds_size=(18.340,32.340,13.900)
pool_meshes=2
```

Rhino exported 559 source document objects. STEP/FreeCAD consolidated that structure into
303 solids. The pool shell and water were migrated as two audited mesh sidecars;
Rhino-specific layers, blocks, remaining materials, annotations, and cameras are not
guaranteed to survive the neutral exchange and must be checked visually.
