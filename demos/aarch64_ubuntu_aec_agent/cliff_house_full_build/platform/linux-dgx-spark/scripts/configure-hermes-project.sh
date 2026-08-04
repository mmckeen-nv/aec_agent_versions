#!/usr/bin/env bash
set -euo pipefail

PROFILE_NAME="${HERMES_PROFILE_NAME:-cliff-house-full-build}"
PROJECT_SLUG="cliff-house-full-build"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
HERMES_BIN="${HERMES_BIN:-$HOME/.local/bin/hermes}"
LAUNCHER="$HOME/.local/bin/cliff-house-full-build"
PROFILE_CONFIG="$HOME/.hermes/profiles/$PROFILE_NAME/config.yaml"

[[ -x "$HERMES_BIN" ]] || { echo "Hermes is not installed at $HERMES_BIN" >&2; exit 1; }
[[ -f "$WORKSPACE/AGENTS.md" ]] || { echo "Missing $WORKSPACE/AGENTS.md" >&2; exit 1; }
[[ -f "$WORKSPACE/PLAYBOOK.md" ]] || { echo "Missing $WORKSPACE/PLAYBOOK.md" >&2; exit 1; }

if ! "$HERMES_BIN" profile list | grep -Fq "$PROFILE_NAME"; then
  "$HERMES_BIN" profile create "$PROFILE_NAME" --no-skills \
    --description "Isolated agent for the FreeCAD-to-Blender-to-ComfyUI Cliff House full-build workflow."
fi

if "$HERMES_BIN" --profile "$PROFILE_NAME" project show "$PROJECT_SLUG" >/dev/null 2>&1; then
  "$HERMES_BIN" --profile "$PROFILE_NAME" project set-primary "$PROJECT_SLUG" "$WORKSPACE" >/dev/null
  "$HERMES_BIN" --profile "$PROFILE_NAME" project use "$PROJECT_SLUG" >/dev/null
else
  "$HERMES_BIN" --profile "$PROFILE_NAME" project create "Cliff House Full Build" "$WORKSPACE" \
    --slug "$PROJECT_SLUG" \
    --primary "$WORKSPACE" \
    --description "End-to-end FreeCAD, Blender, and ComfyUI Cliff House build." \
    --icon building \
    --color '#76b900' >/dev/null
fi

# Do not print a success receipt unless Hermes can resolve the project from this profile.
"$HERMES_BIN" --profile "$PROFILE_NAME" project show "$PROJECT_SLUG" >/dev/null
"$HERMES_BIN" --profile "$PROFILE_NAME" project use "$PROJECT_SLUG" >/dev/null

# Attach already-installed local MCP clients without probing or starting the GUI applications.
# Hermes's config CLI YAML-coerces bare ports and booleans, but MCP environment values must be
# strings. Quote those two values after setting the nested keys.
if [[ -x "$HOME/.local/bin/blender-mcp" ]]; then
  "$HERMES_BIN" --profile "$PROFILE_NAME" config set \
    mcp_servers.blender.command "$HOME/.local/bin/blender-mcp" >/dev/null
  "$HERMES_BIN" --profile "$PROFILE_NAME" config set \
    mcp_servers.blender.env.BLENDER_HOST 127.0.0.1 >/dev/null
  "$HERMES_BIN" --profile "$PROFILE_NAME" config set \
    mcp_servers.blender.env.BLENDER_PORT 9876 >/dev/null
  "$HERMES_BIN" --profile "$PROFILE_NAME" config set \
    mcp_servers.blender.env.DISABLE_TELEMETRY true >/dev/null
  sed -i -E \
    -e "s/^([[:space:]]+BLENDER_PORT:).*/\1 '9876'/" \
    -e "s/^([[:space:]]+DISABLE_TELEMETRY:).*/\1 'true'/" \
    "$PROFILE_CONFIG"
fi

if [[ -x "$HOME/.local/bin/freecad-mcp" ]]; then
  "$HERMES_BIN" --profile "$PROFILE_NAME" config set \
    mcp_servers.freecad.command "$HOME/.local/bin/freecad-mcp" >/dev/null
fi

install -d -m 0755 "$HOME/.local/bin"
cat >"$LAUNCHER" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd -- "$WORKSPACE"
exec "$HERMES_BIN" --profile "$PROFILE_NAME" "\$@"
EOF
chmod 0755 "$LAUNCHER"

echo "CLIFF_HOUSE_HERMES_CONTEXT_PASS profile=$PROFILE_NAME project=$PROJECT_SLUG workspace=$WORKSPACE"
echo "Launch with: cliff-house-full-build"
echo 'Then say: start the cliff house build'
