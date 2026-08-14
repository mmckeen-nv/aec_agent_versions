#!/usr/bin/env bash
set -euo pipefail

PLATFORM_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DEMOS_ROOT="$(cd -- "$PLATFORM_ROOT/.." && pwd)"
VERSION="${HERMES_AEC_RUNTIME_VERSION:-$(tr -d '[:space:]' <"$DEMOS_ROOT/hermes-aec-runtime.version")}"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
INTEGRATION_ROOT="$HERMES_HOME/integrations/hermes-aec-runtime"
TARGET="$INTEGRATION_ROOT/$VERSION"

[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid Hermes AEC runtime pin: $VERSION" >&2; exit 2; }
mkdir -p -- "$INTEGRATION_ROOT"
if [[ "${FORCE:-0}" == 1 && -d "$TARGET" ]]; then
  mv -- "$TARGET" "$TARGET.backup.$(date -u +%Y%m%dT%H%M%SZ)"
fi
if [[ ! -x "$TARGET/install.sh" ]]; then
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  curl --fail --location --silent --show-error \
    "https://github.com/mmckeen-nv/hermes-aec-runtime/archive/refs/tags/$VERSION.tar.gz" \
    --output "$temporary/runtime.tar.gz"
  mkdir -p -- "$TARGET"
  tar -xzf "$temporary/runtime.tar.gz" --strip-components=1 -C "$TARGET"
fi

HERMES_AEC_RHINO_URL="${HERMES_AEC_RHINO_URL:-http://127.0.0.1:10500/}" bash "$TARGET/install.sh"
printf '{"version":"%s","root":"%s"}\n' "$VERSION" "$TARGET" >"$INTEGRATION_ROOT/active.json"
printf '%s\n' "$TARGET/.venv/bin/hermes-aec-mcp"
