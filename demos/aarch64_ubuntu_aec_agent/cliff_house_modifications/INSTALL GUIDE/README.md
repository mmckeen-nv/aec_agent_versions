# aarch64_ubuntu_aec_agent installation guide

This page covers the Windows/Rhino deployment. For NVIDIA DGX Spark and FreeCAD, use the
[Linux DGX Spark playbook](LINUX%20DGX%20SPARK/README.md).

Deploy a Windows AEC agent that reasons through a cloud inference endpoint and operates
Rhino, Blender, and ComfyUI on the local workstation.

## What you will build

| Layer | Component | Location |
|---|---|---|
| Agent | Hermes Desktop / CLI | Local Windows workstation |
| Reasoning | OpenAI-compatible model endpoint | Cloud |
| CAD | Rhino 8 + Rhino MCP Platform 0.1.5 | Local |
| DCC | Blender + Blender MCP | Local |
| Imaging | ComfyUI + PyTorch CUDA | Local NVIDIA GPU |

No DML, CMA, Ollama, Mission Control, or DirectML runtime is part of this guide.

## Guide sequence

1. [System requirements](01-system-requirements.md)
2. [Install applications](02-install-applications.md)
3. [Configure MCP servers](03-configure-mcp-servers.md)
4. [Configure the cloud endpoint](04-configure-cloud-endpoint.md)
5. [Run the Cliff House demo](05-run-cliff-house-demo.md)
6. [Verify the stack](06-verify-stack.md)
7. [Troubleshoot](07-troubleshooting.md)
8. [Cleanup and rollback](08-cleanup-and-rollback.md)

Each step includes a goal, copy-ready commands, a success check, and a recovery path.
