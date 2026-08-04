#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HERMES_BIN="${HERMES_BIN:-$HOME/.hermes/hermes-agent/venv/bin/hermes}"
HERMES_COMMIT="9be292f1e678437644396b47b3410b433ba3433f"
FREECAD_LAUNCHER="${FREECAD_LAUNCHER:-$HOME/.local/bin/local-aec-freecad}"
FREECADCMD="${FREECADCMD:-$HOME/.local/bin/freecadcmd}"
failures=0

pass() { printf 'PASS     %-20s %s\n' "$1" "$2"; }
fail() { printf 'FAIL     %-20s %s\n' "$1" "$2"; failures=$((failures + 1)); }
pending() { printf 'PENDING  %-20s %s\n' "$1" "$2"; }
blocked() { printf 'BLOCKED  %-20s %s\n' "$1" "$2"; }

[[ "$(uname -m)" == "aarch64" ]] && pass architecture aarch64 || fail architecture "expected aarch64"
nvidia-smi >/dev/null 2>&1 && pass "NVIDIA GPU" available || fail "NVIDIA GPU" unavailable
curl -fsS --max-time 5 http://127.0.0.1:8000/health >/dev/null && pass vLLM healthy || fail vLLM "port 8000 unhealthy"
if [[ -x "$HERMES_BIN" ]] && [[ "$(git -C "$HOME/.hermes/hermes-agent" rev-parse HEAD 2>/dev/null)" == "$HERMES_COMMIT" ]]; then
  pass Hermes "0.17.0 at ${HERMES_COMMIT:0:12}"
else
  fail Hermes "missing or not at the playbook pin"
fi
AEC_PROFILE="$HOME/.hermes/profiles/local-aec-freecad/config.yaml"
if [[ ! -f "$HOME/.hermes/config.yaml" && ! -d "$HOME/.hermes/profiles" ]]; then
  pass "Hermes OOBE" "provider/model selection pending"
  hermes_oobe=true
else
  hermes_oobe=false
  [[ -f "$AEC_PROFILE" ]] && pass "Hermes profile" local-aec-freecad || pending "Hermes AEC profile" "attach after user completes OOBE"
fi
[[ -x "$FREECAD_LAUNCHER" ]] && pass FreeCAD "$FREECAD_LAUNCHER" || fail FreeCAD "launcher missing"
[[ -x "$FREECADCMD" ]] && pass FreeCADCmd "$FREECADCMD" || fail FreeCADCmd missing

if [[ "$hermes_oobe" == true ]]; then
  pending "FreeCAD MCP" "installed; attach after Hermes OOBE"
elif ss -ltn 2>/dev/null | grep -q ':9875'; then
  if "$HERMES_BIN" --profile local-aec-freecad mcp test freecad 2>&1 | grep -q 'Tools discovered: 14'; then
    pass "FreeCAD MCP" "14 tools"
  else
    fail "FreeCAD MCP" "RPC listener present but Hermes test failed"
  fi
else
  pending "FreeCAD MCP" "start FreeCAD GUI to validate 127.0.0.1:9875"
fi

if curl -fsS --max-time 5 http://127.0.0.1:8188/system_stats >/dev/null 2>&1; then
  pass ComfyUI healthy
else
  pending ComfyUI "not deployed"
fi
if command -v blender >/dev/null 2>&1; then
  blender_version="$(blender --background --version 2>/dev/null | awk 'NR==1 {print $2}')"
  pass Blender "$blender_version aarch64 (Cliff House 5.2 master remains gated)"
else
  pending Blender "not installed"
fi

if [[ "$hermes_oobe" == true && -x "$HOME/.local/bin/blender-mcp" ]]; then
  pass "Blender MCP" "installed; Hermes attachment deferred until after OOBE"
elif [[ -x "$HOME/.local/bin/blender-mcp" ]]; then
  if ss -ltn 2>/dev/null | grep -q ':9876'; then
    if "$HERMES_BIN" --profile local-aec-freecad mcp test blender 2>&1 | grep -q 'Tools discovered:'; then
      pass "Blender MCP" "Hermes handshake passed"
    else
      fail "Blender MCP" "port 9876 present but Hermes test failed"
    fi
  else
    pending "Blender MCP" "in Blender: N > BlenderMCP > Connect to Claude"
  fi
else
  pending "Blender MCP" "run install-blender-mcp.sh"
fi

if (( failures > 0 )); then
  echo "LOCAL_AEC_DGX_CORE_FAIL count=${failures}"
  exit 1
fi
echo "LOCAL_AEC_DGX_CORE_PASS"
