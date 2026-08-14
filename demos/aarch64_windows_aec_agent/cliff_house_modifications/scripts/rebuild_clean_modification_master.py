"""Build a clean, semantically addressable Rhino modification master.

The authored reconstruction and the legacy mesh reference occupy the same
source file.  The reference is exactly the unnamed geometry on ``Default``;
the authored house is named and assigned to semantic layers.  This script
removes only that reference overlay and makes repeated plan annotations unique
by level.  It never overwrites its input.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from collections import defaultdict
from pathlib import Path

import rhino3dm


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()

    source = args.source.resolve()
    output = args.output.resolve()
    manifest_path = args.manifest.resolve()
    if source == output:
        raise SystemExit("refusing to overwrite the source master")

    model = rhino3dm.File3dm.Read(str(source))
    if model is None:
        raise SystemExit(f"could not read {source}")

    layer_paths = {
        index: (getattr(layer, "FullPath", None) or layer.Name)
        for index, layer in enumerate(model.Layers)
    }
    legacy_ids = [
        obj.Attributes.Id
        for obj in model.Objects
        if layer_paths[obj.Attributes.LayerIndex] == "Default"
        and not obj.Attributes.Name
    ]
    unexpected_default = [
        str(obj.Attributes.Id)
        for obj in model.Objects
        if layer_paths[obj.Attributes.LayerIndex] == "Default"
        and obj.Attributes.Name
    ]
    if unexpected_default:
        raise SystemExit(f"named objects unexpectedly occupy Default: {unexpected_default}")
    if len(legacy_ids) != 86:
        raise SystemExit(f"expected 86 legacy reference objects, found {len(legacy_ids)}")
    # The binding returns None even when deletion succeeds; the postcondition
    # below is the authoritative check.
    for object_id in legacy_ids:
        model.Objects.Delete(object_id)

    duplicate_groups: dict[str, list] = defaultdict(list)
    for obj in model.Objects:
        duplicate_groups[obj.Attributes.Name].append(obj)
    renamed: dict[str, list[str]] = {}
    for name, objects in sorted(duplicate_groups.items()):
        if not name or len(objects) == 1:
            continue
        # The repeated names are the three separately laid-out floor-plan
        # annotations. Their insertion positions order consistently by level.
        ordered = sorted(
            objects,
            key=lambda obj: (
                obj.Geometry.GetBoundingBox().Min.X,
                obj.Geometry.GetBoundingBox().Min.Y,
                str(obj.Attributes.Id),
            ),
        )
        renamed[name] = []
        for level, obj in enumerate(ordered, start=1):
            unique_name = f"L{level}_{name}"
            obj.Attributes.Name = unique_name
            renamed[name].append(unique_name)

    names = [obj.Attributes.Name for obj in model.Objects]
    if len(model.Objects) != 473:
        raise SystemExit(f"expected 473 authored objects, found {len(model.Objects)}")
    if any(not name for name in names):
        raise SystemExit("clean master contains unnamed objects")
    if len(names) != len(set(names)):
        raise SystemExit("clean master contains duplicate object names")

    output.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    if not model.Write(str(output), 8):
        raise SystemExit(f"could not write {output}")

    digest = hashlib.sha256(output.read_bytes()).hexdigest().upper()
    manifest = {
        "schema": "aec-clean-rhino-master/1.0",
        "source": str(source),
        "output": str(output),
        "sha256": digest,
        "units": str(model.Settings.ModelUnitSystem).split(".")[-1],
        "object_count": len(model.Objects),
        "layer_count": len(model.Layers),
        "named_object_count": len(names),
        "unique_name_count": len(set(names)),
        "removed_legacy_default_objects": len(legacy_ids),
        "renamed_duplicate_families": renamed,
    }
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
