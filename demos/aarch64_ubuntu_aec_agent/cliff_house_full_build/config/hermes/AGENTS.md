# Legacy copy of Cliff House full-build operating rules

The authoritative runtime context is the repository-root `AGENTS.md`. Installers must launch
Hermes from the repository root so it is loaded automatically.

- Treat FreeCAD and Blender documents as user data. Inspect before mutating.
- Ask for confirmation before deleting geometry, replacing a document, or overwriting a master.
- Work from copies. Files containing `MASTER` or `HERO` in their names are read-only sources.
- Prefer deterministic, named operations and report object counts after geometry changes.
- Keep FreeCAD and Blender coordinates, units, cameras, and object names aligned.
- FreeCAD replaces Rhino in this workflow; do not invoke Rhino or Rhino MCP.
- Use ComfyUI only for image generation; do not present generated pixels as verified geometry.
- Never expose API keys, tokens, local secrets, or unrelated user files.
- DML and CMA are outside this demo and must not be installed or invoked.
