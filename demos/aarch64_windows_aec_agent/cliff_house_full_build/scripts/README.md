# Full-build helpers

The phase-driven build is orchestrated by Hermes using `system_prompts/` and Rhino/Blender MCP.
The deterministic Python helpers in this directory support validation, export, Blender rendering,
and ComfyUI processing; they do not configure Hermes or replace the prompt review gates.

Run helpers only against ignored working documents and outputs. Never open a protected master as
the starting point for the full build.
