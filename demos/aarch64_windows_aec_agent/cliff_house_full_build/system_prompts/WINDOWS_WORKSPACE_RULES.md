# Windows workspace overrides

Apply these rules before every active phase prompt. They override machine-specific paths and
preconfigured-service assumptions in the preserved source prompts.

- Resolve every project, output, receipt, script, and asset path relative to this repository root.
- Write generated data only under ignored `work/<run-id>/` or `outputs/<run-id>/` directories.
- Begin construction from empty Rhino and Blender documents; completed masters are not inputs.
- Treat named reference layers in source prompts as design constraints when present, not as a
  requirement to load a hidden or completed model.
- Use only MCP servers attached by the operator after Hermes OOBE.
- Never select or change an inference provider, model, endpoint, credential, profile, or project.
- OBS and recording integration are optional and must not block the architectural workflow.
