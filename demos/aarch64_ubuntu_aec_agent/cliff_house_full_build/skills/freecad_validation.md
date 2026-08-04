# FreeCAD validation

After each construction step, report the created object's name, type, group, finite bounds, and
shape validity. Solids must have positive volume unless the phase explicitly calls for curves,
sketches, annotations, or surfaces.

At a phase gate:

1. Recompute the document and report errors.
2. Confirm required groups and stable IDs are unique.
3. Confirm all bounds and placements are finite.
4. Check `Shape.isValid()` for shape-bearing objects.
5. Check duplicates, zero-volume solids, and unintended intersections relevant to the phase.
6. Compare results to the approved brief, not to imported master geometry.
7. Save a timestamped checkpoint only after approval.

