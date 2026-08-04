# Step 2 — Install FreeCAD, MCP, and the migrated model

**Status: Installed; live MCP handshake pending**

Install the pinned FreeCAD 1.1.3 ARM64 runtime, FreeCAD MCP server, versioned workbench,
and loopback RPC configuration from the repository.

```bash
cd ~/aec_agent_versions/demos/aarch64_ubuntu_aec_agent/cliff_house_full_build
bash platform/linux-dgx-spark/scripts/install-freecad.sh
bash platform/linux-dgx-spark/scripts/install-freecad-mcp.sh
```

## Validate the installation

```bash
test -x ~/.local/opt/freecad-1.1.3/FreeCAD_1.1.3-Linux-aarch64-py311.AppImage
test -x ~/.local/bin/freecadcmd
test -d ~/.local/src/freecad-mcp
test -f ~/.local/share/FreeCAD/v1-1/freecad_mcp_settings.json
~/.local/bin/freecadcmd --version
```

The installers are idempotent. Run them again if a validation check fails:

```bash
cd ~/aec_agent_versions/demos/aarch64_ubuntu_aec_agent/cliff_house_full_build
bash platform/linux-dgx-spark/scripts/install-freecad.sh
bash platform/linux-dgx-spark/scripts/install-freecad-mcp.sh
```

## Start FreeCAD and its RPC bridge

Run this from a terminal inside the GNOME graphical session:

```bash
~/.local/bin/local-aec-freecad
```

The MCP workbench should start its RPC bridge on `127.0.0.1:9875`. Keep it loopback-only.
From a second terminal, confirm the listener. Test Hermes discovery only after completing
Hermes OOBE and attaching the MCP entry to the selected profile:

```bash
ss -ltn | grep ':9875'
~/.local/bin/hermes --profile YOUR_PROFILE mcp test freecad
```

Expected result after onboarding: Hermes connects and discovers the FreeCAD tool set.

## Open and verify the Cliff House model

Open:

```text
~/aec_agent_versions/demos/aarch64_ubuntu_aec_agent/cliff_house_full_build/demo/cliff-house/cliff_house_FREECAD_MASTER.FCStd
```

The deployment also preserves:

- `cliff_house_FREECAD_SOURCE.step`
- `cliff_house_HERO_RHINO_MODEL.3dm`
- `cliff_house_POOL_SHELL.obj`
- `cliff_house_POOL_WATER.obj`
- `cliff_house_FREECAD_PREVIEW.png`

Use the existing FCStd master for inspection and create a working copy before mutation. STEP
does not preserve every Rhino material, annotation, layer, block, or camera semantic.

Next: [Validate Hermes and vLLM](03-hermes-and-vllm.md).
