#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
MASTER="$WORKSPACE/demo/cliff-house/cliff_house_FREECAD_MASTER.FCStd"
EXPECTED_SHA256='B34C82FF5C2772740E7BC257F7D8164BABBED679D048D6265C81793AD0C23D8A'
RUN_ID="${RUN_ID:-quick-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_DIR="$WORKSPACE/work/$RUN_ID"
WORKING="$RUN_DIR/freecad/cliff_house_quick_working.FCStd"

[[ -f "$MASTER" ]] || { echo "Missing protected FreeCAD master: $MASTER" >&2; exit 1; }
actual="$(sha256sum "$MASTER" | awk '{print toupper($1)}')"
[[ "$actual" == "$EXPECTED_SHA256" ]] || { echo 'Protected FreeCAD master hash mismatch.' >&2; exit 1; }
[[ ! -e "$RUN_DIR" ]] || { echo "Run directory already exists: $RUN_DIR" >&2; exit 1; }

mkdir -p -- "$(dirname -- "$WORKING")"
cp --no-clobber -- "$MASTER" "$WORKING"
chmod u+w -- "$WORKING"
printf 'QUICK_WORKING_COPY_PASS source_sha256=%s path=%s\n' "$actual" "$WORKING"
