#!/usr/bin/env bash
set -euo pipefail

PLATFORM_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEMOS_ROOT="$(cd -- "$PLATFORM_ROOT/.." && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
VERSION="$(tr -d '[:space:]' <"$DEMOS_ROOT/hermes-aec-runtime.version")"
failures=0
desktop="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
desktop="${desktop:-$HOME/Desktop}"

check() {
  local label="$1" path="$2"
  if [[ -e "$path" ]]; then printf 'PASS  %s\n' "$label"; else printf 'FAIL  %s\n' "$label"; failures=$((failures + 1)); fi
}

check 'Hermes Desktop UI' "${HERMES_DESKTOP_BIN:-$(command -v hermes-desktop || true)}"
check 'FreeCAD' "${FREECAD_BIN:-$(command -v freecad || true)}"
check "Hermes AEC runtime $VERSION" "$HERMES_HOME/integrations/hermes-aec-runtime/$VERSION/.venv/bin/hermes-aec-mcp"
check 'Full-build profile' "$HERMES_HOME/profiles/cliff-house-full-build-linux/config.yaml"
check 'Modification profile' "$HERMES_HOME/profiles/cliff-house-modifications-linux/config.yaml"
check 'AEC Full Build launcher' "$desktop/AEC Full Build.desktop"
check 'AEC House Modification launcher' "$desktop/AEC House Modification.desktop"

if command -v hermes >/dev/null; then
  for profile in cliff-house-full-build-linux cliff-house-modifications-linux; do
    if hermes -p "$profile" mcp test hermes_aec >/dev/null 2>&1; then printf 'PASS  Hermes AEC via %s\n' "$profile"
    else printf 'FAIL  Hermes AEC via %s\n' "$profile"; failures=$((failures + 1)); fi
  done
fi

if (( failures )); then printf 'AEC_DEPLOYMENT_FAIL count=%d\n' "$failures"; exit 1; fi
echo 'AEC_DEPLOYMENT_PASS'
