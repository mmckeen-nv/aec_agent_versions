# Protected quick-demo masters

- `cliff_house_HERO_RHINO_MODEL.3dm` is the Rhino source master.
- `cliff_house_QUICK_MASTER.blend` is the Blender quick-render master.

The Rhino master is numerically modeled in metres and its document unit system is deliberately
set to metres. Do not change it to millimetres and do not scale its geometry. The intended
absolute tolerance is `0.001 m` (1 mm). Its separated floor plans are schematic and retain the
note requiring verification of structure, egress, accessibility, and local code.

Never edit these files in place. Copy them into ignored `work/<run-id>/` storage, remove
`HERO`/`MASTER` from the working filename, and operate only on the copy.
