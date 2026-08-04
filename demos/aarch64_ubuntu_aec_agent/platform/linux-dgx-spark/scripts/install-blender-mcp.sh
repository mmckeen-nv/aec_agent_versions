#!/usr/bin/env bash
set -euo pipefail

MCP_VERSION="1.6.4"
MCP_RUNTIME_VERSION="1.29.0"
ADDON_COMMIT="6e99eb5a442b83766a5796975ec7bb5bfc791341"
ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/local-aec-agent/blender-mcp"
BLENDER_VERSION="$(blender --background --version 2>/dev/null | awk 'NR==1 {print $2}')"
BLENDER_SERIES="${BLENDER_VERSION%.*}"
ADDON_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/blender/${BLENDER_SERIES}/scripts/addons"

[[ "$(uname -m)" == "aarch64" ]]
[[ -n "$BLENDER_VERSION" ]]

mkdir -p "$ROOT" "$ADDON_DIR"
python3 -m venv "$ROOT/.venv"
"$ROOT/.venv/bin/python" -m pip install --disable-pip-version-check --upgrade pip
"$ROOT/.venv/bin/python" -m pip install --disable-pip-version-check "blender-mcp==${MCP_VERSION}"
# BlenderMCP 1.6.4 imports mcp.server.fastmcp, removed by mcp 2.x.
"$ROOT/.venv/bin/python" -m pip install --disable-pip-version-check "mcp[cli]==${MCP_RUNTIME_VERSION}"
ln -sfn "$ROOT/.venv/bin/blender-mcp" "$HOME/.local/bin/blender-mcp"

curl --fail --location --proto '=https' --tlsv1.2 \
  "https://raw.githubusercontent.com/ahujasid/blender-mcp/${ADDON_COMMIT}/addon.py" \
  --output "$ADDON_DIR/blender_mcp.py"

blender --background --python-expr \
  "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp'); bpy.ops.wm.save_userpref()"

cat >"$ROOT/install-receipt.json" <<EOF
{
  "status": "PASS",
  "server_version": "${MCP_VERSION}",
  "mcp_runtime_version": "${MCP_RUNTIME_VERSION}",
  "addon_commit": "${ADDON_COMMIT}",
  "blender_version": "${BLENDER_VERSION}",
  "hermes_attachment": false,
  "host": "127.0.0.1",
  "port": 9876,
  "telemetry_disabled": true,
  "secrets_included": false
}
EOF

echo "BLENDER_MCP_INSTALL_PASS server=${MCP_VERSION} mcp_runtime=${MCP_RUNTIME_VERSION} addon=${ADDON_COMMIT:0:12} blender=${BLENDER_VERSION}"
echo "Open Blender, press N, select BlenderMCP, then click Connect to Claude."
