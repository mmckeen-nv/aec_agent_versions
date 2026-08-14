# Cliff House quick-modification context

This workspace is the Windows ARM64 **Cliff House Modifications** demo. It is isolated from
`cliff_house_full_build` and may not read or modify that workflow's profile, project, sessions,
outputs, or state.

Use the protected Rhino and Blender masters only to create timestamped working copies under an
ignored `work/` directory. Inspect the working document before mutation, require an explicit
target for deletion or replacement, and report changed object counts. Never overwrite a file
containing `MASTER` or `HERO`.

The Rhino house is numerically modeled in metres. The working document must report metres with an
absolute tolerance of `0.001 m`; do not scale geometry. The three separated floor plans are
schematic presentation objects, not extra building geometry. Preserve their program labels and
their note requiring verification of structure, egress, accessibility, and local code.

## Hermes AEC sidecar execution contract

For every modification request, use exactly this progression:

1. Assume the desktop launcher has already opened the timestamped working copy. Call
   `rhino_scene_query` once with the narrowest useful selector. Confirm document revision, path,
   units, tolerance, bounds, total count, and stable candidate IDs before mutation.
2. At most one `get_viewport_image` before mutation, only when geometry relationships remain
   ambiguous after the audit.
3. Call `rhino_apply_operations` once with the exact scene revision, one unique stable
   `idempotency_key`, the active working-document path as `checkpoint_path`, and the smallest typed
   operation batch. Do not generate RhinoCommon for routine geometry. The sidecar validates the
   batch, preserves in-place GUIDs, persists its receipt, captures created/modified/deleted IDs,
   reconciles dropped responses, and rolls back a failed transaction.
4. Run one focused post-change `rhino_scene_query`, then call `rhino_verify_transaction` with the
   receipt, before/after scenes, and task-specific invariants.
5. One `get_viewport_image`, then `save_doc`, report the evidence, and stop.

Web search is available for building, zoning, accessibility, fire, safety, product, and other
research required by the demo. Prefer primary and governing sources when accuracy matters, cite
the sources used, and clearly distinguish binding requirements from guidance.

Automatic Daystrom retrieval is sufficient. The profile intentionally does not expose callable
Daystrom tools, skills, sessions, files, terminal, browser automation, vision-analysis, planning,
delegation, or computer-use tools. Do not attempt to discover substitutes. The normal ceiling is
two Rhino inspection calls before
mutation, one typed transaction, one verification, one save, and no more than two viewport captures.
Never call `rhino_execute_python`, raw `run_python`, or raw `run_csharp` in this modification
profile. If Rhino
MCP fails, retry one small read-only call once; if it still fails, stop and request a bridge restart.
For a mutation with status `unknown`, never submit a new transaction: call it again only with the
same `idempotency_key` so the sidecar can recover the persisted receipt.
For a mutation with status `failed` and `rolled_back=true`, correct the script and submit it with a
new unique key. An idempotency key is permanently bound to one exact payload.

Hermes inference configuration and credentials are user-owned. The deployed profile uses an
isolated Daystrom DML store for compact procedural recall. Retrieve it automatically, but persist
only sanitized, validated workflow outcomes; never raw transcripts, secrets, or unverified claims.
CMA is out of scope.
