#!/usr/bin/env bash
set -euo pipefail

demo="${1:-}"
PLATFORM_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HERMES_DESKTOP_BIN="${HERMES_DESKTOP_BIN:-$(command -v hermes-desktop || true)}"
if [[ -z "$HERMES_DESKTOP_BIN" ]]; then
  for candidate in "$HOME/.local/bin/hermes-desktop" /usr/local/bin/hermes-desktop /usr/bin/hermes-desktop; do
    [[ -x "$candidate" ]] && HERMES_DESKTOP_BIN="$candidate" && break
  done
fi
[[ -n "$HERMES_DESKTOP_BIN" && -x "$HERMES_DESKTOP_BIN" ]] || exit 1

FREECAD_BIN="${FREECAD_BIN:-$HOME/.local/bin/local-aec-freecad}"
[[ -x "$FREECAD_BIN" ]] || FREECAD_BIN="$(command -v freecad || true)"
[[ -n "$FREECAD_BIN" ]] || { echo 'FreeCAD launcher is not installed.' >&2; exit 1; }

case "$demo" in
  full)
    workspace="$PLATFORM_ROOT/cliff_house_full_build"
    profile='cliff-house-full-build-linux'
    "$FREECAD_BIN" >/dev/null 2>&1 &
    ;;
  modification)
    workspace="$PLATFORM_ROOT/cliff_house_modifications"
    profile='cliff-house-modifications-linux'
    receipt="$(bash "$workspace/platform/linux-dgx-spark/scripts/prepare-working-copy.sh")"
    working="${receipt##*path=}"
    "$FREECAD_BIN" "$working" >/dev/null 2>&1 &
    ;;
  *)
    echo 'Usage: launch-aec-demo.sh full|modification' >&2
    exit 2
    ;;
esac

cd -- "$workspace"
exec "$HERMES_DESKTOP_BIN" --profile "$profile"
