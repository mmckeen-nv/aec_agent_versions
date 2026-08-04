# AEC Agent Versions

This repository collects independently deployable AEC agent demonstrations and reference
implementations. Each demo lives under `demos/` with its own installation guide, platform
assets, validation instructions, and third-party notices.

## Demos

| Demo | Platforms | AEC applications | Status |
|---|---|---|---|
| [Local AEC Agent Cloud Endpoint](demos/local-aec-agent-cloud-endpoint/) | Windows, NVIDIA DGX Spark | Rhino 3D, FreeCAD, Blender, ComfyUI | DGX Spark deployment validated |

## Repository conventions

- Keep each demo self-contained under `demos/<demo-name>/`.
- Do not commit API keys, tokens, model credentials, generated user state, or machine backups.
- Preserve source and master geometry; perform demonstrations on working copies.
- Document platform-specific setup and acceptance checks inside each demo's `INSTALL GUIDE/`.
- Pin third-party revisions used by deployment scripts and record their licenses.

See the individual demo README before installation.
