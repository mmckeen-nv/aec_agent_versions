# Step 6 — Acceptance checks and rollback

## Validate the clean deployment

```bash
cd ~/aec_agent_versions/demos/aarch64_ubuntu_aec_agent/cliff_house_modifications
bash platform/linux-dgx-spark/scripts/verify-platform.sh
python3 platform/linux-dgx-spark/scripts/smoke-comfyui.py
curl -fsS http://127.0.0.1:8000/health
```

Acceptance requires:

- Hermes is installed at the pinned revision.
- A bare Hermes launch enters first-run provider/model selection.
- No provider, model, API key, profile, MCP server, or memory provider is preselected.
- vLLM responds but remains only a selectable endpoint.
- FreeCAD, Blender MCP, and ComfyUI are installed independently.
- ComfyUI completes the checked-in CUDA smoke workflow and prints
  `COMFYUI_CUDA_SMOKE_PASS`.
- vLLM remains healthy after the ComfyUI workflow.

`PENDING` is acceptable for a FreeCAD or Blender GUI handshake when that application is
closed. It is not acceptable for architecture, GPU, vLLM, Hermes pin/OOBE, or an installed
core runtime. The verifier must finish with `LOCAL_AEC_DGX_CORE_PASS`.

## Restore the pre-test Hermes installation

The clean installer moves the previous tree to:

```text
~/.local/share/local-aec-agent/deployment-backups/hermes-before-clean-install-TIMESTAMP
```

Stop all Hermes processes, move the new `~/.hermes` aside, and restore only a reviewed backup.
Backups can contain credentials and must remain mode `0700`; never publish them.

The clean install receipt is stored at:

```text
~/.local/share/local-aec-agent/receipts/hermes-oobe.json
```

It records the pinned version and commit and confirms that no provider or model was selected.

## Remove the clean Hermes installation

```bash
rm -rf ~/.hermes
rm -f ~/.local/bin/hermes
```

This does not remove vLLM, FreeCAD, Blender, or ComfyUI.
