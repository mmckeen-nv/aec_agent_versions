# Cliff House modifications workflow

This workflow starts from the checked-in, audited Cliff House masters and demonstrates quick,
reversible changes through Hermes and the local application MCP bridges.

```text
Checked-in master
  → create working copy
  → inspect through FreeCAD or Blender MCP
  → apply an operator-approved modification
  → validate geometry and scene invariants
  → optionally render and process through ComfyUI
```

The source masters remain immutable. Generated working copies, renders, logs, credentials,
and Hermes user state are intentionally excluded from version control.

Use the numbered guides under [`INSTALL GUIDE/`](INSTALL%20GUIDE/) for deployment and
validation.
