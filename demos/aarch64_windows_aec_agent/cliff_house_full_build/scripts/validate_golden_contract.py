"""Validate a full-build Rhino document against the golden semantic contract."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path

import rhino3dm

ROOTS = ("building_site_v3", "massing_v3", "AEC_HOUSE", "FLOORPLAN")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("document", type=Path)
    parser.add_argument("--contract", type=Path, default=Path(__file__).parents[1] / "projects" / "cliff_house_02" / "golden_build_contract.json")
    args = parser.parse_args()
    contract = json.loads(args.contract.read_text(encoding="utf-8"))
    model = rhino3dm.File3dm.Read(str(args.document))
    if model is None:
        raise SystemExit(f"could not read {args.document}")

    layer_paths = {i: model.Layers[i].FullPath for i in range(len(model.Layers))}
    authored = []
    root_counts: Counter[str] = Counter()
    for obj in model.Objects:
        root = layer_paths[obj.Attributes.LayerIndex].split("::", 1)[0]
        if root in ROOTS:
            authored.append(obj)
            root_counts[root] += 1

    names = [obj.Attributes.Name for obj in authored]
    failures = []
    checks = {"total_objects": len(model.Objects), "authored_objects": len(authored), "total_layers": len(model.Layers), "units": str(model.Settings.ModelUnitSystem).split(".")[-1]}
    for key, actual in checks.items():
        expected = contract[key]
        if actual != expected:
            failures.append(f"{key}: expected {expected!r}, got {actual!r}")
    if any(not name for name in names):
        failures.append("one or more authored objects are unnamed")
    if len(names) != len(set(names)):
        failures.append("authored object names are not unique")
    for root, expected in contract["root_counts"].items():
        if root_counts[root] != expected:
            failures.append(f"{root}: expected {expected} objects, got {root_counts[root]}")
    missing = sorted(set(contract["required_names"]) - set(names))
    if missing:
        failures.append("missing required names: " + ", ".join(missing))
    for key, expected in contract["document_strings"].items():
        actual = model.Strings[key]
        if actual != expected:
            failures.append(f"document string {key}: expected {expected!r}, got {actual!r}")

    result = {"schema": contract["schema"], "document": str(args.document.resolve()), "status": "pass" if not failures else "fail", "counts": checks, "root_counts": dict(root_counts), "failures": failures}
    print(json.dumps(result, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
