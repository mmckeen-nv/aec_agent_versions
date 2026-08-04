# Windows ARM64 full-build playbook

## Objective

Run the original Cliff House workflow end to end through Hermes Desktop, Rhino MCP, Blender MCP,
and ComfyUI while preserving Hermes as a normal OOBE product and keeping this workflow isolated
from the quick-modification demo.

## Phases and gates

| Phase | Application | Gate |
|---|---|---|
| 00 startup | Hermes | Correct project/profile; Rhino, Blender, ComfyUI inspected read-only |
| 01 configuration | Rhino + Blender | Units, axes, file paths, and empty documents approved |
| 02 site | Rhino | Site and terrain reviewed |
| 03 massing | Rhino | Architectural masses reviewed |
| 04 plan 2D | Rhino | Plans and circulation reviewed |
| 05 plan 3D | Rhino | 3D plan elements reviewed |
| 06 detailing | Rhino | Openings, glazing, pool, and details reviewed |
| 07 export | Rhino → Blender | Geometry/layer audit and handoff approved |
| 08 camera/light | Blender | Framing and lighting approved |
| 09 materials | Blender | Semantic materials approved |
| 10 test render | Blender | Geometry-locked render reviewed |
| 11 final visualization | ComfyUI | Workflow/model availability and output reviewed |
| 12 layer reveal | Rhino/Blender | Optional sequence reviewed |
| 13 sun study | Rhino/Blender | Optional study reviewed |

The detailed instructions and receipts live in the corresponding `system_prompts/*.md` files.

## OOBE contract

Deployment may install or validate application binaries, but it may not write a Hermes provider,
model, endpoint, credential, profile, project, or MCP configuration. The operator completes OOBE,
then runs `installer/Register-HermesProject.ps1` with an explicit profile. Registration never
launches Hermes Desktop or changes inference configuration.

## Definition of done

- Full-build and quick-modification projects are isolated.
- The build begins from empty Rhino and Blender documents.
- Phase review gates and receipts are preserved.
- The Rhino-to-Blender handoff retains units, axes, names, layers, and material intent.
- The Blender test render is geometry-locked before ComfyUI.
- No secret, profile, session, log, cache, generated geometry, render, or model weight is committed.
