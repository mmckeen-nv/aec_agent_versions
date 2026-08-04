"""Persist visible objects and a fitted axonometric camera in the FreeCAD demo."""

from pathlib import Path

import FreeCAD as App
import FreeCADGui as Gui


repo = Path(__file__).resolve().parents[1]
model = repo / "demo" / "cliff-house" / "cliff_house_FREECAD_MASTER.FCStd"
preview = repo / "demo" / "cliff-house" / "cliff_house_FREECAD_PREVIEW.png"

doc = App.openDocument(str(model))
gui_doc = Gui.activeDocument()
visible = 0
for obj in doc.Objects:
    has_shape = hasattr(obj, "Shape") and not obj.Shape.isNull()
    has_mesh = hasattr(obj, "Mesh") and obj.Mesh.CountFacets > 0
    if has_shape or has_mesh:
        obj.ViewObject.Visibility = True
        visible += 1

shell = doc.getObject("PoolShell")
if shell is not None:
    shell.ViewObject.ShapeColor = (0.72, 0.68, 0.59)
water = doc.getObject("PoolWater")
if water is not None:
    water.ViewObject.ShapeColor = (0.01, 0.12, 0.17)
    water.ViewObject.Transparency = 20

doc.recompute()
view = gui_doc.activeView()
view.viewAxonometric()
view.fitAll()
view.saveImage(str(preview), 1600, 1000, "Current")
doc.save()

print(
    "FREECAD_VIEW_PREP_PASS visible={} model={} preview={}".format(
        visible, model, preview
    )
)
Gui.getMainWindow().close()
