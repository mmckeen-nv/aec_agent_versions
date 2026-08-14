# AEC Agent Versions

This repository collects independently deployable AEC agent demonstrations and reference
implementations. Each demo lives under `demos/` with its own installation guide, platform
assets, validation instructions, and third-party notices.

## Demos

| Demo | Platforms | AEC applications | Status |
|---|---|---|---|
| [`aarch64_ubuntu_aec_agent`](demos/aarch64_ubuntu_aec_agent/) | NVIDIA DGX Spark / Ubuntu ARM64 | FreeCAD, Blender, ComfyUI | DGX Spark deployment validated |
| [`aarch64_windows_aec_agent`](demos/aarch64_windows_aec_agent/) | Windows on ARM64 | Rhino 8, Blender, ComfyUI | OOBE-safe package validated locally |

## Repository conventions

- Keep each demo self-contained under `demos/<demo-name>/`.
- Do not commit API keys, tokens, model credentials, generated user state, or machine backups.
- Preserve source and master geometry; perform demonstrations on working copies.
- Document platform-specific setup and acceptance checks inside each demo's `INSTALL GUIDE/`.
- Pin third-party revisions used by deployment scripts and record their licenses.

Start here:

- [Windows requirements, deployment, and test checklist](demos/aarch64_windows_aec_agent/DEPLOY.md)
- [Linux/DGX requirements and deployment](demos/aarch64_ubuntu_aec_agent/DEPLOY.md)
