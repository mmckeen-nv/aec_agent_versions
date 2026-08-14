"""Idempotently seed compact demo procedures into an isolated Daystrom store."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from daystrom_dml.dml_adapter import DMLAdapter


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--storage", type=Path, required=True)
    parser.add_argument("--knowledge", type=Path, required=True)
    parser.add_argument("--project-id", required=True)
    args = parser.parse_args()
    files = sorted(args.knowledge.glob("*.md"))
    hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in files}
    marker = args.storage / ".aec-seed.json"
    if marker.exists() and json.loads(marker.read_text(encoding="utf-8")) == hashes:
        print(f"DML_SEED_CURRENT files={len(files)} store={args.storage}")
        return 0
    args.storage.mkdir(parents=True, exist_ok=True)
    adapter = DMLAdapter(config_path=str(args.config), config_overrides={"storage_dir": str(args.storage)}, start_aging_loop=False)
    try:
        for path in files:
            adapter.ingest(path.read_text(encoding="utf-8"), meta={
                "tenant_id": "aec-demo", "client_id": "hermes-aec",
                "project_id": args.project_id, "kind": "action",
                "source": "aec-demo-seed", "memory_state": "active",
                "doc_path": str(path.resolve()), "no_merge": True,
            })
    finally:
        adapter.close()
    marker.write_text(json.dumps(hashes, indent=2, sort_keys=True), encoding="utf-8")
    print(f"DML_SEEDED files={len(files)} store={args.storage}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
