# Step 5 — Blender ARM64 compatibility gate

**Status: Blender 4.0.2 and Blender MCP installed; Blender 5.2 asset remains gated**

The checked-in Cliff House Blender master was authored in Blender 5.2. Ubuntu 24.04 ARM64
offers Blender 4.0.2, which cannot safely open a file from a newer major release.

The installer pins BlenderMCP 1.6.4, its matching add-on revision, and MCP runtime 1.29.0.
It installs the Blender-side bridge but does not preconfigure Hermes before OOBE.

```bash
cd ~/aec_agent_versions/demos/aarch64_ubuntu_aec_agent/cliff_house_full_build
bash platform/linux-dgx-spark/scripts/install-blender-mcp.sh
```

Open Blender, press `N`, select **BlenderMCP**, and click **Connect to Claude**. The bridge
listens only on `127.0.0.1:9876`; telemetry is disabled when it is later attached to Hermes.

The Cliff House Blender master remains disabled until a reviewed native ARM64 Blender 5.x
build passes a smoke render and loopback MCP test. Do not downgrade or resave the master with
Blender 4.0.2.

Next: [Run acceptance checks](06-validation-and-rollback.md).
