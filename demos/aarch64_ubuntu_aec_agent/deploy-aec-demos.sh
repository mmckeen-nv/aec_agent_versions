#!/usr/bin/env bash
set -euo pipefail

PLATFORM_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODEL_ID="${MODEL_ID:-}"
CONTEXT_LENGTH="${CONTEXT_LENGTH:-262144}"

bash "$PLATFORM_ROOT/memory/install-aec-dml.sh"

if [[ -z "$MODEL_ID" ]]; then
  read -r -p 'vLLM served model ID: ' MODEL_ID
fi
[[ -n "$MODEL_ID" ]] || { echo 'A model ID is required.' >&2; exit 2; }

MODEL_ID="$MODEL_ID" CONTEXT_LENGTH="$CONTEXT_LENGTH" \
  HERMES_PROFILE_NAME=cliff-house-full-build-linux \
  bash "$PLATFORM_ROOT/cliff_house_full_build/platform/linux-dgx-spark/scripts/deploy-hermes-profile.sh"

MODEL_ID="$MODEL_ID" CONTEXT_LENGTH="$CONTEXT_LENGTH" \
  HERMES_PROFILE_NAME=cliff-house-modifications-linux \
  bash "$PLATFORM_ROOT/cliff_house_modifications/platform/linux-dgx-spark/scripts/deploy-hermes-profile.sh"

desktop="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
desktop="${desktop:-$HOME/Desktop}"
mkdir -p -- "$desktop"

create_shortcut() {
  local filename="$1" name="$2" demo="$3"
  cat >"$desktop/$filename" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$name
Exec=env bash "$PLATFORM_ROOT/launch-aec-demo.sh" $demo
Terminal=false
Categories=Graphics;Development;
EOF
  chmod 0755 "$desktop/$filename"
}

create_shortcut 'AEC Full Build.desktop' 'AEC Full Build' full
create_shortcut 'AEC House Modification.desktop' 'AEC House Modification' modification

echo "AEC_DEMOS_DEPLOYED model=$MODEL_ID context=$CONTEXT_LENGTH"
echo 'Use the two new Desktop launchers: AEC Full Build and AEC House Modification.'
