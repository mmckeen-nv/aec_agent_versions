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
  backup="$TARGET.backup.$(date -u +%Y%m%dT%H%M%S%N)"
  mv -- "$TARGET" "$backup"
fi
if [[ ! -x "$TARGET/install.sh" ]]; then
  temporary="$(mktemp -d)"
  trap 'rm -rf -- "$temporary"' EXIT
  curl --fail --location --silent --show-error \
    "https://github.com/mmckeen-nv/hermes-aec-runtime/archive/refs/tags/$VERSION.tar.gz" \
    --output "$temporary/runtime.tar.gz"
  mkdir -p -- "$TARGET"
  if ! tar -xzf "$temporary/runtime.tar.gz" --strip-components=1 -C "$TARGET"; then
    rm -rf -- "$TARGET"
    if [[ -n "${backup:-}" && -d "$backup" ]]; then mv -- "$backup" "$TARGET"; fi
    echo "Could not extract Hermes AEC runtime $VERSION." >&2
    exit 1
  fi
  [[ -x "$TARGET/install.sh" && -f "$TARGET/pyproject.toml" ]] || {
    rm -rf -- "$TARGET"
    if [[ -n "${backup:-}" && -d "$backup" ]]; then mv -- "$backup" "$TARGET"; fi
    echo "Downloaded $VERSION but its source layout is invalid." >&2
    exit 1
  }
fi

if ! HERMES_AEC_RHINO_URL="${HERMES_AEC_RHINO_URL:-http://127.0.0.1:10500/}" bash "$TARGET/install.sh"; then
  if [[ -n "${backup:-}" && -d "$backup" ]]; then
    rm -rf -- "$TARGET"
    mv -- "$backup" "$TARGET"
  fi
  exit 1
fi
active_tmp="$(mktemp "$INTEGRATION_ROOT/.active.json.XXXXXX")"
printf '{"schema_version":1,"version":"%s","root":"%s"}\n' "$VERSION" "$TARGET" >"$active_tmp"
chmod 0600 "$active_tmp"
mv -f -- "$active_tmp" "$INTEGRATION_ROOT/active.json"
printf '%s\n' "$TARGET/.venv/bin/hermes-aec-mcp"
