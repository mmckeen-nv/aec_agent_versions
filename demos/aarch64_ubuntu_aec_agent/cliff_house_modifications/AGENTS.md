# Cliff House quick-modification agent context — Linux

This package is the quick modification demo. It is isolated from `cliff_house_full_build`.

## Required workflow

1. Create a timestamped working copy of
   `demo/cliff-house/cliff_house_FREECAD_MASTER.FCStd` with
   `platform/linux-dgx-spark/scripts/prepare-working-copy.sh`.
2. Open only the generated working copy through FreeCAD MCP.
3. Audit object counts, validity, bounds, and semantic properties before modification.
4. Apply only the operator-requested bounded change.
5. Re-audit and report the exact changed objects and invariants.

Never mutate the checked-in `.FCStd`, STEP, Rhino, OBJ, or Blender masters. Never reconstruct the
whole house in this workflow. Do not read or update the full-build profile, project, phase state,
sessions, working files, or outputs.

Inference configuration is deployment-owned. Never expose credentials or change the selected
provider/model unless explicitly asked.

The profile's isolated Daystrom DML store supplies compact procedural recall. Retrieve it
automatically, but persist only sanitized, validated workflow outcomes. Never store raw
transcripts, secrets, or unverified claims. CMA is out of scope.
