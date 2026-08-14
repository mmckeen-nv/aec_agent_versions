"""Replace the pool-obscuring patio slab with four perimeter solids.

This is a deterministic, atomic repair for checked-in Rhino masters created by
an older build_swagstaff_master.py. It preserves every object except the named
PATIO_CONCRETE object and refuses inputs that are already repaired or ambiguous.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path

import rhino3dm


PATIO_PARTS = {
    "PATIO_CONCRETE_SOUTH": (-5.8, -16.8, -0.05, 4.8, -14.0, 0.15),
    "PATIO_CONCRETE_NORTH": (-5.8, 5.0, -0.05, 4.8, 13.8, 0.15),
    "PATIO_CONCRETE_WEST": (-5.8, -14.0, -0.05, -5.62, 5.0, 0.15),
    "PATIO_CONCRETE_EAST": (0.2, -14.0, -0.05, 4.8, 5.0, 0.15),
}


def make_box(bounds: tuple[float, ...]):
    x0, y0, z0, x1, y1, z1 = bounds
    return rhino3dm.Brep.CreateFromBoundingBox(
        rhino3dm.BoundingBox(
            rhino3dm.Point3d(x0, y0, z0),
            rhino3dm.Point3d(x1, y1, z1),
        )
    )


def repair(path: Path) -> None:
    model = rhino3dm.File3dm.Read(str(path))
    if model is None:
        raise SystemExit(f"could not read {path}")

    old = [obj for obj in model.Objects if obj.Attributes.Name == "PATIO_CONCRETE"]
    existing_parts = [obj.Attributes.Name for obj in model.Objects if obj.Attributes.Name in PATIO_PARTS]
    if len(old) != 1 or existing_parts:
        raise SystemExit(
            f"{path}: expected one legacy PATIO_CONCRETE and no repaired parts; "
            f"found legacy={len(old)} parts={existing_parts}"
        )

    source_attributes = old[0].Attributes
    source_count = len(model.Objects)
    model.Objects.Delete(source_attributes.Id)
    for name, bounds in PATIO_PARTS.items():
        attributes = rhino3dm.ObjectAttributes()
        attributes.Name = name
        attributes.LayerIndex = source_attributes.LayerIndex
        model.Objects.AddBrep(make_box(bounds), attributes)

    names = [obj.Attributes.Name for obj in model.Objects]
    if len(model.Objects) != source_count + 3:
        raise SystemExit(f"{path}: unexpected repaired object count")
    if any(names.count(name) != 1 for name in PATIO_PARTS):
        raise SystemExit(f"{path}: repaired patio names are not unique")

    water = next(obj for obj in model.Objects if obj.Attributes.Name == "INFINITY_POOL_WATER")
    water_box = water.Geometry.GetBoundingBox()
    for obj in model.Objects:
        if obj.Attributes.Name not in PATIO_PARTS:
            continue
        patio_box = obj.Geometry.GetBoundingBox()
        overlap_x = min(patio_box.Max.X, water_box.Max.X) - max(patio_box.Min.X, water_box.Min.X)
        overlap_y = min(patio_box.Max.Y, water_box.Max.Y) - max(patio_box.Min.Y, water_box.Min.Y)
        overlap_z = min(patio_box.Max.Z, water_box.Max.Z) - max(patio_box.Min.Z, water_box.Min.Z)
        if overlap_x > 1e-9 and overlap_y > 1e-9 and overlap_z > 1e-9:
            raise SystemExit(f"{path}: {obj.Attributes.Name} still intersects pool water")

    temporary = path.with_name(path.name + ".repairing")
    if not model.Write(str(temporary), 8):
        raise SystemExit(f"could not write {temporary}")
    os.replace(temporary, path)
    print(f"POOL_PATIO_REPAIR_PASS file={path} objects={len(model.Objects)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("models", nargs="+", type=Path)
    args = parser.parse_args()
    for model in args.models:
        repair(model.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
