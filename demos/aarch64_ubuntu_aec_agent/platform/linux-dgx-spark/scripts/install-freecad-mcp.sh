#!/usr/bin/env bash
set -euo pipefail

MCP_VERSION="0.1.21"
MCP_COMMIT="6de952ae923e68af236f40570ae06b1a37994592"
SOURCE_DIR="${HOME}/.local/src/freecad-mcp"
FREECAD_USER_DIR="${HOME}/.local/share/FreeCAD/v1-1"
ADDON_DIR="${FREECAD_USER_DIR}/Mod/FreeCADMCP"
SETTINGS_FILE="${FREECAD_USER_DIR}/freecad_mcp_settings.json"

if ! command -v uv >/dev/null 2>&1; then
  curl --fail --location https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi

uv tool install --force "freecad-mcp==${MCP_VERSION}"
mkdir -p "$(dirname "${SOURCE_DIR}")" "$(dirname "${ADDON_DIR}")"

if [[ ! -d "${SOURCE_DIR}/.git" ]]; then
  git clone https://github.com/neka-nat/freecad-mcp.git "${SOURCE_DIR}"
fi
git -C "${SOURCE_DIR}" fetch --depth 1 origin "${MCP_COMMIT}"
git -C "${SOURCE_DIR}" checkout --detach "${MCP_COMMIT}"

rm -rf "${ADDON_DIR}"
cp -a "${SOURCE_DIR}/addon/FreeCADMCP" "${ADDON_DIR}"

cat >"${SETTINGS_FILE}" <<'JSON'
{
  "remote_enabled": false,
  "allowed_ips": "127.0.0.1",
  "auto_start_rpc": true
}
JSON

freecad-mcp --help >/dev/null
echo "FREECAD_MCP_INSTALL_PASS version=${MCP_VERSION} commit=${MCP_COMMIT:0:12} loopback_auto_start=true"
