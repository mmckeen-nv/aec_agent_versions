"""Add the Rhino pool mesh sidecars to the audited FreeCAD master."""

from pathlib import Path

import FreeCAD as App
import Mesh


repo = Path(__file__).resolve().parents[1]
asset_dir = repo / "demo" / "cliff-house"
model = asset_dir / "cliff_house_FREECAD_MASTER.FCStd"
pool_parts = {
    "PoolShell": asset_dir / "cliff_house_POOL_SHELL.obj",
    "PoolWater": asset_dir / "cliff_house_POOL_WATER.obj",
}

doc = App.openDocument(str(model))
for name, source in pool_parts.items():
    existing = doc.getObject(name)
    if existing is not None:
        doc.removeObject(name)
    obj = doc.addObject("Mesh::Feature", name)
    obj.Label = name
    obj.Mesh = Mesh.Mesh(str(source))
    if obj.Mesh.CountFacets == 0:
        raise RuntimeError(f"Pool mesh is empty: {source}")

doc.recompute()
doc.save()
print("FREECAD_POOL_IMPORT_PASS shell=PoolShell water=PoolWater")
