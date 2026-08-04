# Troubleshooting

- If project registration says the profile is missing, finish Hermes OOBE first and pass its exact
  profile name to `Register-HermesProject.ps1`.
- If Hermes selects the wrong application, verify only this project's Rhino and Blender MCP entries
  are attached to the active profile.
- If Rhino MCP is unavailable, confirm Rhino 8 is open and the MCP platform/router is running.
- If Blender MCP is unavailable, enable its add-on and start the server inside Blender.
- Never repair a demo by copying another profile or committing `%LOCALAPPDATA%\hermes`.
