# aarch64_ubuntu_aec_agent

AEC agent workflows validated for ARM64 Ubuntu on NVIDIA DGX Spark.

## Install once

See [DEPLOY.md](DEPLOY.md), or run:

```bash
bash ./deploy-aec-demos.sh
```

This creates **AEC Full Build** and **AEC House Modification** launchers on the Desktop.

## Workflows

| Workflow | Purpose | State |
|---|---|---|
| [`cliff_house_modifications`](cliff_house_modifications/) | Make controlled, reversible changes to the migrated Cliff House model | Validated baseline |
| [`cliff_house_full_build`](cliff_house_full_build/) | Build the complete FreeCAD → Blender → ComfyUI pipeline | [Porting playbook defined](cliff_house_full_build/PLAYBOOK.md) |

Each workflow is self-contained. Enter the workflow directory before running its installers,
scripts, or guides so relative paths resolve within that workflow.

The agent-level directory is an index only. Shared machine state, model weights, credentials,
Hermes profiles, generated renders, and deployment backups are not committed here.
