# Cliff House quick modifications — Linux ARM64

This is the short live demo: Hermes opens a generated working copy of the completed, audited
FreeCAD house and makes bounded operator-requested changes through FreeCAD MCP. It does not build
the house from source guides; that is the separate `cliff_house_full_build` workflow.

## Deploy

```bash
MODEL_ID='your-vllm-served-model-id' \
CONTEXT_LENGTH=262144 \
platform/linux-dgx-spark/scripts/deploy-hermes-profile.sh

platform/linux-dgx-spark/scripts/prepare-working-copy.sh
```

Then start FreeCAD and its MCP bridge, open the emitted working-copy path, and launch Hermes with
profile `cliff-house-modifications-linux`.

In the Hermes UI, request the outcome directly. For example: `Audit the working copy, move the
selected canopy 300 mm east, preserve everything else, validate the result, and report exactly
what changed.` The same concise pattern works for any bounded edit: target, desired result,
constraints, and required evidence. FreeCAD remains authoritative for geometry.

## Safety contract

- `cliff_house_FREECAD_MASTER.FCStd` is the completed quick-demo source and is immutable.
- STEP, Rhino, OBJ, and Blender masters are also immutable.
- Every run uses a new ignored `work/quick-<timestamp>/` directory.
- Hermes audits before and after each modification and reports changed object counts.
- The full-build source manifest, phase state, and outputs are out of scope.
- Credentials, model weights, application state, and generated work are never committed.
