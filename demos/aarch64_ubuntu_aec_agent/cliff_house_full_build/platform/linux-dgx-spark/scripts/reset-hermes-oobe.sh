#!/usr/bin/env bash
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
BACKUP_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/local-aec-agent/hermes-oobe-backups"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$BACKUP_ROOT/$STAMP"

[[ -d "$HERMES_HOME/hermes-agent" ]]
[[ -x "$HERMES_HOME/hermes-agent/venv/bin/hermes" ]]
if pgrep -u "$(id -u)" -f 'hermes (serve|gateway|desktop|chat)' >/dev/null 2>&1; then
  echo "Refusing OOBE reset while a Hermes runtime is active." >&2
  exit 1
fi

install -d -m 0700 "$BACKUP_DIR"
shopt -s dotglob nullglob
for path in "$HERMES_HOME"/*; do
  name="$(basename "$path")"
  case "$name" in
    hermes-agent|bin) continue ;;
  esac
  mv -- "$path" "$BACKUP_DIR/"
done
shopt -u dotglob nullglob

cat >"$BACKUP_DIR/reset-receipt.json" <<EOF
{
  "status": "PASS",
  "reset_at_utc": "${STAMP}",
  "hermes_home": "${HERMES_HOME}",
  "preserved_install": true,
  "preserved_bin": true,
  "secrets_included_in_backup": true,
  "backup_permissions": "0700"
}
EOF
chmod 0600 "$BACKUP_DIR/reset-receipt.json"

echo "HERMES_OOBE_RESET_PASS backup=$BACKUP_DIR"
echo "Next interactive launch: $HERMES_HOME/hermes-agent/venv/bin/hermes"
