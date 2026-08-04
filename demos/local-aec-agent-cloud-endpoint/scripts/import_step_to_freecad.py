"""Import the checked-in STEP handoff and save the FreeCAD demo master."""

from pathlib import Path

import FreeCAD as App
import Import


repo = Path(__file__).resolve().parents[1]
source = repo / "demo" / "cliff-house" / "cliff_house_FREECAD_SOURCE.step"
target = repo / "demo" / "cliff-house" / "cliff_house_FREECAD_MASTER.FCStd"

doc = App.newDocument("CliffHouseFreeCAD")
Import.insert(str(source), doc.Name)
doc.recompute()
shape_objects = [
    obj
    for obj in doc.Objects
    if hasattr(obj, "Shape") and not obj.Shape.isNull()
]
if not shape_objects:
    raise RuntimeError("STEP import produced no valid shapes")

doc.saveAs(str(target))
print(
    "FREECAD_STEP_IMPORT_PASS objects={} shapes={} target={}".format(
        len(doc.Objects), len(shape_objects), target
    )
)
