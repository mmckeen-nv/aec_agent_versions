# Step 1 — Validate the DGX Spark baseline

**Status: Validated on 2026-08-04**

Confirm the platform before installing or repairing applications.

## Expected baseline

| Item | Validated value |
|---|---|
| Host | `spark-1ce2` |
| OS | Ubuntu 24.04, ARM64 |
| GPU | NVIDIA GB10 |
| Kernel | NVIDIA 6.17 series |
| Driver / CUDA | 580.159.03 / 13.0 |
| Memory | Approximately 121 GiB usable unified memory |
| Containers | Docker and NVIDIA Container Toolkit |
| Inference | vLLM on `127.0.0.1:8000` |
| Available local model | `nvidia/Qwen3.6-35B-A3B-NVFP4` |

## Run the preflight

```bash
uname -m
cat /etc/os-release
nvidia-smi
free -h
df -h /
curl -fsS http://127.0.0.1:8000/health
curl -fsS http://127.0.0.1:8000/v1/models | python3 -m json.tool
```

Expected results:

- `uname -m` returns `aarch64`.
- The vLLM health request succeeds.
- The model response includes the pinned Qwen model. This endpoint remains selectable and
  is not written into Hermes during deployment.

The active vLLM process reserves a substantial portion of unified memory. Do not stop it for
routine FreeCAD or Hermes validation. Revisit memory allocation only when enabling ComfyUI.

Next: [Install FreeCAD and FreeCAD MCP](02-freecad-and-mcp.md).
