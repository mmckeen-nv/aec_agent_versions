"""Export the active Rhino 8 document to STEP without opening exporter dialogs."""

import os
import pathlib

import Rhino


target = os.environ.get("LOCAL_AEC_STEP_TARGET")
receipt = os.environ.get("LOCAL_AEC_STEP_RECEIPT")
if not target or not receipt:
    raise RuntimeError("LOCAL_AEC_STEP_TARGET and LOCAL_AEC_STEP_RECEIPT are required")

doc = Rhino.RhinoDoc.ActiveDoc
if doc is None or doc.Objects.Count == 0:
    raise RuntimeError("Rhino has no active populated document")

options = Rhino.FileIO.FileStpWriteOptions()
options.Export2dCurves = False
options.SplitClosedSurfaces = False
success = doc.Export(target, options.ToDictionary())
if not success:
    raise RuntimeError("Rhino STEP export returned false")

path = pathlib.Path(target)
if not path.is_file() or path.stat().st_size < 10_000:
    raise RuntimeError("Rhino STEP export is missing or undersized")

pathlib.Path(receipt).write_text(
    "RHINO_STEP_EXPORT_PASS objects={} bytes={}\n".format(
        doc.Objects.Count, path.stat().st_size
    ),
    encoding="utf-8",
)
Rhino.RhinoApp.Exit(False)
