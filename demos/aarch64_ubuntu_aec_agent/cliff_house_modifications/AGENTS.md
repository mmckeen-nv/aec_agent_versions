# Cliff House quick-modification agent context — Linux

This package is the quick modification demo. It is isolated from `cliff_house_full_build`.

## Required workflow

1. Create a timestamped working copy of
   `demo/cliff-house/cliff_house_FREECAD_MASTER.FCStd` with
   `platform/linux-dgx-spark/scripts/prepare-working-copy.sh`.
2. Open only the generated working copy through FreeCAD MCP.
3. Route the request with the host-neutral sidecar when available, then audit the narrowest useful
   set of FreeCAD objects, including counts, validity, bounds, and semantic properties.
4. Apply only the operator-requested bounded change through FreeCAD MCP. Prefer typed operations;
   use one reviewed `execute_code` transaction only when the bridge has no typed equivalent.
5. Recompute, re-audit request-specific invariants, save the working copy, and report exact changed
   objects. A viewport is supporting evidence, not geometry proof.

Never mutate the checked-in `.FCStd`, STEP, Rhino, OBJ, or Blender masters. Never reconstruct the
whole house in this workflow. Do not read or update the full-build profile, project, phase state,
sessions, working files, or outputs.

Inference configuration is deployment-owned. Never expose credentials or change the selected
provider/model unless explicitly asked.

The `hermes_aec` sidecar provides host-neutral routing, contracts, proof/receipt, memory,
recorder, and Blender tools. It does not replace FreeCAD MCP. Never call a `rhino_*` sidecar tool
on Linux; execute and verify geometry changes through the `freecad` MCP server.

The profile's isolated Daystrom DML store supplies compact procedural recall. Retrieve it
automatically, but persist only sanitized, validated workflow outcomes. Never store raw
transcripts, secrets, or unverified claims. CMA is out of scope.
