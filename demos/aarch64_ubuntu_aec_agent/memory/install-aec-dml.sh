#!/usr/bin/env bash
set -euo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
root="$HERMES_HOME/integrations/daystrom-dml"; source_dir="$root/source"; venv="$root/.venv-dml"
revision=98c0d116d706f3f1db4e60076400518d56ab6b9c
command -v git >/dev/null || { echo 'Git is required to install Daystrom DML.' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'Python 3.10+ is required to install Daystrom DML.' >&2; exit 1; }
mkdir -p "$root"
[[ -f "$source_dir/pyproject.toml" ]] || git clone https://github.com/mmckeen-nv/DML.git "$source_dir"
git -C "$source_dir" fetch --quiet origin "$revision"
git -C "$source_dir" checkout --quiet "$revision"
[[ -x "$venv/bin/python" ]] || python3 -m venv "$venv"
"$venv/bin/python" -m pip install --disable-pip-version-check --quiet --upgrade pip
DML_BUILD_CUDA=0 "$venv/bin/python" -m pip install --disable-pip-version-check --quiet -e "$source_dir[mcp]"
"$venv/bin/python" -m pip install --disable-pip-version-check --quiet 'mcp==1.29.0'
"$venv/bin/python" -c 'from mcp.server.fastmcp import FastMCP'
mkdir -p "$root/config" "$root/bin" "$root/stores"
cp "$(dirname "$0")/dml.yaml" "$root/config/aec-demo.yaml"
cat >"$root/bin/hermes-dml-memory" <<EOF
#!/usr/bin/env bash
exec "$venv/bin/python" "$source_dir/openclaw-wrapper/scripts/dml_memory.py" "\$@"
EOF
chmod 0755 "$root/bin/hermes-dml-memory"
echo "DML_INSTALLED revision=$revision root=$root"
