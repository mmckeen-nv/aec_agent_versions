#!/usr/bin/env python3
"""Extract Wagstaff's source-only Rhino model into a FreeCAD-friendly JSON manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import rhino3dm


def xyz(point: object) -> list[float]:
    return [float(point.X), float(point.Y), float(point.Z)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    model = rhino3dm.File3dm.Read(str(args.source))
    if model is None:
        raise SystemExit(f"Could not read {args.source}")

    entries: list[dict[str, object]] = []
    for index, item in enumerate(model.Objects):
        geometry = item.Geometry
        layer = model.Layers[item.Attributes.LayerIndex].FullPath
        entry: dict[str, object] = {
            "index": index,
            "id": str(item.Attributes.Id),
            "name": item.Attributes.Name or f"source_{index:02d}",
            "layer": layer,
            "type": type(geometry).__name__,
        }
        if isinstance(geometry, rhino3dm.PolylineCurve):
            entry["points"] = [xyz(geometry.Point(i)) for i in range(geometry.PointCount)]
        elif isinstance(geometry, rhino3dm.NurbsCurve):
            domain = geometry.Domain
            entry["degree"] = geometry.Degree
            entry["control_points"] = [
                [float(point.X), float(point.Y), float(point.Z), float(point.W)]
                for point in geometry.Points
            ]
            entry["knots"] = [float(knot) for knot in geometry.Knots]
            entry["samples"] = [
                xyz(geometry.PointAt(domain.T0 + (domain.T1 - domain.T0) * step / 64.0))
                for step in range(65)
            ]
        elif isinstance(geometry, rhino3dm.TextDot):
            entry["text"] = geometry.Text
            entry["point"] = xyz(geometry.Point)
        else:
            raise SystemExit(f"Unsupported source geometry at index {index}: {type(geometry).__name__}")
        entries.append(entry)

    digest = hashlib.sha256(args.source.read_bytes()).hexdigest().upper()
    payload = {
        "schema_version": 1,
        "source_repository": "https://github.com/stwagstaff/2026_aec_cptx_demo",
        "source_revision": "09b15e6c9a74b4a018587420eaaa2f5e273fd447",
        "source_path": "aa_demo_versions/cliff_house_02/rhino_assets/base_model.3dm",
        "source_sha256": digest,
        "source_units": "millimeters",
        "target_units": "meters",
        "scale": 0.001,
        "objects": entries,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"REFERENCE_MANIFEST_PASS objects={len(entries)} sha256={digest}")


if __name__ == "__main__":
    main()
