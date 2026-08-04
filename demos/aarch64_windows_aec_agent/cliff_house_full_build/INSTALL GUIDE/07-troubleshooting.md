# Troubleshooting

- If project registration says the profile is missing, finish Hermes OOBE first and pass its exact
  profile name to `Register-HermesProject.ps1`.
- If Hermes loads the quick demo or a completed model, stop and verify the isolated full-build
  profile/project and empty Rhino/Blender documents.
- If Rhino MCP is unavailable, confirm Rhino 8 is open and the MCP platform/router is running.
- If Blender MCP is unavailable, enable its add-on and start the server inside Blender.
- Never repair a demo by copying another profile or committing `%LOCALAPPDATA%\hermes`.
