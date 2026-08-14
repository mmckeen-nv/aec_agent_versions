#!/usr/bin/env bash
set -euo pipefail

PROFILE_NAME="${HERMES_PROFILE_NAME:-cliff-house-modifications-linux}"
MODEL_ID="${MODEL_ID:-}"
VLLM_BASE_URL="${VLLM_BASE_URL:-http://127.0.0.1:8000/v1}"
CONTEXT_LENGTH="${CONTEXT_LENGTH:-262144}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
FORCE="${FORCE:-0}"
AEC_RUNTIME_SERVER="${AEC_RUNTIME_SERVER:-}"

[[ -n "$MODEL_ID" ]] || { echo 'MODEL_ID is required (the vLLM served model ID).' >&2; exit 2; }
[[ -x "$AEC_RUNTIME_SERVER" ]] || { echo 'AEC_RUNTIME_SERVER must point to the installed hermes-aec-mcp executable.' >&2; exit 2; }
[[ "$CONTEXT_LENGTH" =~ ^[0-9]+$ ]] || { echo 'CONTEXT_LENGTH must be an integer.' >&2; exit 2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
TEMPLATE="$WORKSPACE/config/hermes/config.template.yaml"
PROFILE_ROOT="$HERMES_HOME/profiles/$PROFILE_NAME"
CONFIG="$PROFILE_ROOT/config.yaml"
DML_ROOT="$HERMES_HOME/integrations/daystrom-dml"
DML_STORE="$DML_ROOT/stores/cliff-house-modifications-linux"

[[ -f "$TEMPLATE" ]] || { echo "Missing template: $TEMPLATE" >&2; exit 1; }
if [[ -f "$CONFIG" && "$FORCE" != 1 ]]; then
  echo "Refusing to overwrite $CONFIG. Set FORCE=1 after reviewing the existing profile." >&2
  exit 1
fi

mkdir -p -- "$PROFILE_ROOT"
if [[ -f "$CONFIG" ]]; then
  cp -- "$CONFIG" "$CONFIG.$(date -u +%Y%m%dT%H%M%SZ).bak"
fi

escape_sed() { printf '%s' "$1" | sed -e 's/[|&]/\\&/g'; }
sed \
  -e "s|__MODEL_ID__|$(escape_sed "$MODEL_ID")|g" \
  -e "s|__VLLM_BASE_URL__|$(escape_sed "${VLLM_BASE_URL%/}")|g" \
  -e "s|__CONTEXT_LENGTH__|$CONTEXT_LENGTH|g" \
  -e "s|__WORKSPACE__|$(escape_sed "$WORKSPACE")|g" \
  -e "s|__HOME__|$(escape_sed "$HOME")|g" \
  -e "s|__DML_ROOT__|$(escape_sed "$DML_ROOT")|g" \
  -e "s|__DML_STORE__|$(escape_sed "$DML_STORE")|g" \
  -e "s|__AEC_RUNTIME_SERVER__|$(escape_sed "$AEC_RUNTIME_SERVER")|g" \
  "$TEMPLATE" >"$CONFIG"
chmod 0600 "$CONFIG"

cp -- "$WORKSPACE/AGENTS.md" "$PROFILE_ROOT/AGENTS.md"
[[ -x "$DML_ROOT/.venv-dml/bin/python" ]] || { echo 'Daystrom DML is not installed. Run deploy-aec-demos.sh.' >&2; exit 1; }
mkdir -p "$PROFILE_ROOT/plugins"
mkdir -p "$PROFILE_ROOT/plugins/daystrom_dml"
cp -a -- "$DML_ROOT/source/integrations/hermes/plugins/daystrom_dml/." "$PROFILE_ROOT/plugins/daystrom_dml/"
"$DML_ROOT/.venv-dml/bin/python" "$WORKSPACE/../memory/seed_dml.py" \
  --config "$DML_ROOT/config/aec-demo.yaml" --storage "$DML_STORE" \
  --knowledge "$WORKSPACE/memory" --project-id project:cliff-house-modifications-linux

echo "HERMES_PROFILE_DEPLOYED profile=$PROFILE_NAME model=$MODEL_ID context=$CONTEXT_LENGTH"
echo "Validate with: hermes -p $PROFILE_NAME mcp test freecad"
