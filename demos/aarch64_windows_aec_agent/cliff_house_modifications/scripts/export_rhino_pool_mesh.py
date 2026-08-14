"""Extract the two pool meshes omitted by the Rhino-to-STEP handoff."""

from pathlib import Path

import rhino3dm


POOL_OBJECTS = {
    "faab4596-fe93-4883-a872-78f4f6d6ff5a": "cliff_house_POOL_SHELL.obj",
    "a188a6ed-6936-401f-b176-6411129a1229": "cliff_house_POOL_WATER.obj",
}

repo = Path(__file__).resolve().parents[1]
asset_dir = repo / "demo" / "cliff-house"
source = asset_dir / "cliff_house_GOLDEN_MASTER.3dm"
model = rhino3dm.File3dm.Read(str(source))

found = set()
for item in model.Objects:
    object_id = str(item.Attributes.Id)
    filename = POOL_OBJECTS.get(object_id)
    if filename is None:
        continue
    mesh = item.Geometry
    if not isinstance(mesh, rhino3dm.Mesh):
        raise RuntimeError(f"Pool object {object_id} is not a mesh")
    lines = [f"o {Path(filename).stem}"]
    lines.extend(f"v {v.X:.9g} {v.Y:.9g} {v.Z:.9g}" for v in mesh.Vertices)
    for face in mesh.Faces:
        indices = list(face)
        if len(indices) == 4 and indices[2] == indices[3]:
            indices.pop()
        lines.append("f " + " ".join(str(index + 1) for index in indices))
    (asset_dir / filename).write_text("\n".join(lines) + "\n", encoding="ascii")
    found.add(object_id)

missing = set(POOL_OBJECTS) - found
if missing:
    raise RuntimeError(f"Missing Rhino pool objects: {sorted(missing)}")
print("RHINO_POOL_EXPORT_PASS objects=2 files=" + ",".join(POOL_OBJECTS.values()))
