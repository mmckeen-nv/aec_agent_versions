"""Audit finite Part geometry in the checked-in FreeCAD demo master."""

import math
from pathlib import Path

import FreeCAD as App


repo = Path(__file__).resolve().parents[1]
path = repo / "demo" / "cliff-house" / "cliff_house_FREECAD_MASTER.FCStd"
doc = App.openDocument(str(path))
features = [
    obj
    for obj in doc.Objects
    if obj.TypeId == "Part::Feature"
    and hasattr(obj, "Shape")
    and not obj.Shape.isNull()
]
valid = [obj for obj in features if obj.Shape.isValid()]
invalid = [obj for obj in features if not obj.Shape.isValid()]
finite = []
for obj in features:
    box = obj.Shape.BoundBox
    values = [box.XMin, box.YMin, box.ZMin, box.XMax, box.YMax, box.ZMax]
    if all(math.isfinite(value) and abs(value) < 1e9 for value in values):
        finite.append(obj)

if not finite:
    raise RuntimeError("FreeCAD master contains no finite Part geometry")
box = finite[0].Shape.BoundBox
for obj in finite[1:]:
    box.add(obj.Shape.BoundBox)

solids = sum(len(obj.Shape.Solids) for obj in features)
shells = sum(len(obj.Shape.Shells) for obj in features)
faces = sum(len(obj.Shape.Faces) for obj in features)
edges = sum(len(obj.Shape.Edges) for obj in features)
pool_meshes = [doc.getObject("PoolShell"), doc.getObject("PoolWater")]
if any(obj is None or obj.Mesh.CountFacets == 0 for obj in pool_meshes):
    raise RuntimeError("FreeCAD master is missing the Rhino pool shell or water mesh")
pool_facets = sum(obj.Mesh.CountFacets for obj in pool_meshes)
print(
    "FREECAD_GEOMETRY_AUDIT_PASS features={} valid={} invalid={} finite={} "
    "solids={} shells={} faces={} edges={} pool_meshes=2 pool_facets={}".format(
        len(features),
        len(valid),
        len(invalid),
        len(finite),
        solids,
        shells,
        faces,
        edges,
        pool_facets,
    )
)
print(
    "FREECAD_FINITE_BOUNDS size=({:.3f},{:.3f},{:.3f})".format(
        box.XLength, box.YLength, box.ZLength
    )
)
if invalid:
    raise RuntimeError("FreeCAD master contains invalid shapes")
