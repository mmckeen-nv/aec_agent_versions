#!/usr/bin/env bash
set -euo pipefail

HERMES_COMMIT="9be292f1e678437644396b47b3410b433ba3433f"
HERMES_VERSION="0.17.0"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
BACKUP_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/local-aec-agent/deployment-backups"
RECEIPT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/local-aec-agent/receipts"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

if pgrep -u "$(id -u)" -f 'hermes (serve|gateway|desktop|chat)' >/dev/null 2>&1; then
  echo "Refusing install while a Hermes runtime is active." >&2
  exit 1
fi

if [[ -e "$HERMES_HOME" ]]; then
  install -d -m 0700 "$BACKUP_ROOT"
  mv -- "$HERMES_HOME" "$BACKUP_ROOT/hermes-before-clean-install-$STAMP"
fi

install -d -m 0700 "$HERMES_HOME"
git clone --quiet https://github.com/NousResearch/hermes-agent.git "$HERMES_HOME/hermes-agent"
git -C "$HERMES_HOME/hermes-agent" checkout --quiet --detach "$HERMES_COMMIT"
[[ "$(git -C "$HERMES_HOME/hermes-agent" rev-parse HEAD)" == "$HERMES_COMMIT" ]]

python3 -m venv "$HERMES_HOME/hermes-agent/venv"
"$HERMES_HOME/hermes-agent/venv/bin/python" -m pip install --disable-pip-version-check --upgrade pip
"$HERMES_HOME/hermes-agent/venv/bin/python" -m pip install --disable-pip-version-check \
  --editable "$HERMES_HOME/hermes-agent"
install -d -m 0755 "$HOME/.local/bin"
ln -sfn "$HERMES_HOME/hermes-agent/venv/bin/hermes" "$HOME/.local/bin/hermes"

installed_version="$($HOME/.local/bin/hermes --version | sed -n 's/^Hermes Agent v\([^ ]*\).*/\1/p')"
[[ "$installed_version" == "$HERMES_VERSION" ]]
[[ ! -e "$HERMES_HOME/config.yaml" ]]
[[ ! -e "$HERMES_HOME/.env" ]]
[[ ! -e "$HERMES_HOME/auth.json" ]]
[[ ! -e "$HERMES_HOME/profiles" ]]

install -d -m 0700 "$RECEIPT_DIR"
cat >"$RECEIPT_DIR/hermes-oobe.json" <<EOF
{
  "status": "PASS",
  "version": "${HERMES_VERSION}",
  "commit": "${HERMES_COMMIT}",
  "oobe": true,
  "provider_selected": false,
  "model_selected": false,
  "secrets_included": false
}
EOF
chmod 0600 "$RECEIPT_DIR/hermes-oobe.json"

echo "HERMES_CLEAN_OOBE_INSTALL_PASS version=$HERMES_VERSION commit=${HERMES_COMMIT:0:12}"
