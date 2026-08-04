# Step 4 — Deploy ComfyUI for GB10

**Status: Installed and validated on NVIDIA GB10**

Use the NVIDIA DGX Spark CUDA 13 route rather than an x86 portable package.

## Review before installation

The current vLLM process uses a significant share of unified memory. Capture a baseline:

```bash
nvidia-smi
free -h
ss -ltn | grep ':8188' || true
```

## Install the NVIDIA-compatible service

```bash
cd ~/Local-AEC-Agent-Cloud-Endpoint
sed -n '1,260p' platform/linux-dgx-spark/scripts/install-comfyui.sh
bash platform/linux-dgx-spark/scripts/install-comfyui.sh
```

The installer uses the pinned NVIDIA DGX Spark playbook, verifies the resulting ComfyUI
revision, installs CUDA 13 PyTorch in an isolated environment, and creates a loopback-only
systemd user service. A 48 GiB reserve prevents ComfyUI from consuming memory assigned to
vLLM and the desktop applications.

```bash
systemctl --user status local-aec-comfyui.service
curl -fsS http://127.0.0.1:8188/system_stats | python3 -m json.tool
python3 platform/linux-dgx-spark/scripts/smoke-comfyui.py
```

Acceptance requires a successful GB10 CUDA workflow while vLLM remains healthy. Do not bind
to `0.0.0.0` unless firewall rules and trusted-client requirements are documented.

Next: [Connect Blender MCP](05-blender-status.md).
