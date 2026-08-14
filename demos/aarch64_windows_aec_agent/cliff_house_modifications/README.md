# Cliff House modification demo — Windows on ARM

This is the fast live demo. Hermes opens a disposable copy of the completed golden-master Rhino
house and performs bounded operator-requested changes. It does not rebuild the house.

## Start

Install from the parent directory by following [../DEPLOY.md](../DEPLOY.md), then double-click
**AEC House Modification** on the desktop. The shortcut performs the entire bring-up:

1. creates a timestamped working copy;
2. opens that copy in Rhino 8;
3. starts and verifies AEC RhinoMCP on loopback port `1999`;
4. selects the `cliff-house-modifications-windows` Hermes profile; and
5. opens Hermes Desktop in this workspace.

Do not open or edit `cliff_house_GOLDEN_MASTER.3dm` directly. Generated working copies are local
and ignored by Git.

## Request pattern

Give Hermes four things: the target, desired result, constraints, and required evidence. Example:

```text
Audit the active working copy. Move the selected canopy 300 mm east. Preserve every other object,
verify the transaction independently, and report exactly what changed.
```

The modification profile uses the typed scene-query, operation, verification, recovery, and
viewport tools. Raw Rhino scripting and computer-use automation are not part of this workflow.

For installation checks and recovery, use the parent [deployment guide](../DEPLOY.md).
