# Cliff House full-build workflow — Windows ARM64

## Pipeline

```text
Hermes OOBE
  → Phase 00 preflight
  → Rhino MCP: phases 01–06 architecture from an empty document
  → Phase 07 audited Rhino-to-Blender export
  → Blender MCP: phases 08–10 camera, lighting, materials, and test render
  → ComfyUI: phase 11 geometry-locked visualization
  → optional phase 12 layer reveal and phase 13 sun study
```

The active `system_prompts/` and `skills/` are the original Rhino/Windows workflow imported from
NVIDIA's [`stwagstaff/2026_aec_cptx_demo`](https://github.com/stwagstaff/2026_aec_cptx_demo).
The vendored copy under `upstream/` records provenance.

## Isolation contract

- Begin the full build from an empty Rhino document.
- Never use the hero Rhino file or quick Blender master as a construction shortcut.
- Never read or activate the `cliff_house_modifications` Hermes project or profile.
- Create timestamped work under ignored `work/` or `outputs/` directories.
- Preserve units, axes, layer paths, semantic names, stable identifiers, and materials at handoff.
- Require operator approval at the review gates defined by the active phase prompts.
- Treat ComfyUI output as visualization rather than verified geometry.

## Acceptance

A complete run records the phase receipts required by the prompt suite, source and output hashes,
the working Rhino and Blender documents, the Blender test render, and the final ComfyUI output.
Hermes inference selection and credentials remain user-owned OOBE state and are never included in
receipts or repository files.
