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
   `rhino_scene_query` first with `mode=summary`; it returns compact document metadata, bounds,
   layer counts, and type counts without dumping every object. Then make at most one
   `mode=objects` query with a name/layer/type/ID selector and `limit<=25`. Confirm revision,
   units, bounds, and stable target IDs before mutation.
   If Rhino restarted into an empty document, call `rhino_open_working_document` with the exact
   existing timestamped working-copy path from this run, then repeat the summary query. Never ask
   the operator to reopen it and never open a MASTER or HERO file.
2. For visual inspection, call `rhino_viewport_zoom_extents`, then use
   `rhino_viewport_set_target` and bounded `rhino_viewport_orbit` moves followed by
   `rhino_viewport_capture`. These tools visibly change the active Rhino viewport and prove each
   inspected area. Do not substitute computer use. Keep inspection to the minimum useful views.
3. Call `rhino_apply_operations` once with the exact scene revision, one unique stable
   `idempotency_key`, the active working-document path as `checkpoint_path`, and the smallest typed
   operation batch. Do not generate RhinoCommon for routine geometry. The sidecar validates the
   batch, preserves in-place GUIDs, persists its receipt, captures created/modified/deleted IDs,
   reconciles dropped responses, and rolls back a failed transaction.
4. Require `receipt.verification.status=verified`; the sidecar automatically performs the
   independent before/after scene-delta proof. Make one focused post-change object query only when
   a task-specific spatial or naming assertion is not already present in the receipt.
5. One final `rhino_viewport_capture`, then `save_doc`, report the evidence, and stop.

For a Rhino-to-Blender request, do not ask the operator to export and do not pass `.3dm` to
Blender. After the Rhino verification and save, call `rhino_export_scene` once with a new absolute
`.glb` path inside the active timestamped `work/` directory and `expected_units=\"Meters\"`.
Require a completed receipt with a non-zero byte count. Pass that path to
`blender_validate_handoff`, then call `blender_import_handoff` with a new absolute working `.blend`
path in the same timestamped run, `unit_scale=1.0`, and one stable idempotency key. That single
transaction imports, saves, frames, and foregrounds the exact MCP-connected Blender instance; do
not substitute a bare `import_scene` operation. GLB is required because Rhino's dedicated glTF
writer is deterministic; do not fall back to the interactive FBX exporter. Re-query Blender before materials, camera, rendering,
or ComfyUI submission. Never retry an uncertain import with a new idempotency key.

For Blender-to-ComfyUI, render a new PNG inside the active run, verify that the Blender receipt is
completed and the file is non-empty, then call `comfyui_health` and exactly one
`comfyui_stylize_image` transaction. Supply a new absolute PNG output path, an architecture prompt
that explicitly preserves geometry and camera, and one stable idempotency key. Require a completed
receipt with `bytes`, `sha256`, and `output_path`; return that exact path. Never claim ComfyUI ran
from a Blender render alone, never invent an output path, and never route ComfyUI through
`blender_apply_operations`.

Web search is available for building, zoning, accessibility, fire, safety, product, and other
research required by the demo. Prefer primary and governing sources when accuracy matters, cite
the sources used, and clearly distinguish binding requirements from guidance.

Automatic Daystrom retrieval is sufficient. The profile intentionally does not expose callable
Daystrom tools, skills, sessions, files, terminal, browser automation, vision-analysis, planning,
or computer-use tools. Delegation is available only for parallel read-only analysis: give delegates
compact scene subsets, never Rhino/MCP access, and require them to return findings or proposed typed
operations. The coordinator alone may call Rhino tools, and all mutations must remain serial. The normal ceiling is
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
