# Step 4 — Run the full-build demo

1. Start Rhino 8 with a new empty document and start Rhino MCP.
2. Start Blender with a new empty scene and start BlenderMCP.
3. Start ComfyUI and confirm its loopback UI is available.
4. Open the `cliff-house-full-build-windows` project in its dedicated Hermes profile.
5. Tell Hermes: `Start the cliff house build.`

Hermes reads `AGENTS.md`, the project brief, phase state, skills, and Phase 00 prompt. It must report
the selected phase and complete a read-only preflight before any mutation. Continue through the
review gates in `system_prompts/`; save working documents and receipts only under ignored
`work/<run-id>/` or `outputs/<run-id>/` paths.

Do not open the hero Rhino file or quick Blender master during the full build.
