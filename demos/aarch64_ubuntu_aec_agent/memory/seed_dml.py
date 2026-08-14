"""Idempotently seed compact demo procedures into an isolated Daystrom store."""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path
from daystrom_dml.dml_adapter import DMLAdapter

def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--config", type=Path, required=True); p.add_argument("--storage", type=Path, required=True)
    p.add_argument("--knowledge", type=Path, required=True); p.add_argument("--project-id", required=True)
    a = p.parse_args(); files = sorted(a.knowledge.glob("*.md"))
    hashes = {f.name: hashlib.sha256(f.read_bytes()).hexdigest() for f in files}; marker = a.storage / ".aec-seed.json"
    if marker.exists() and json.loads(marker.read_text(encoding="utf-8")) == hashes:
        print(f"DML_SEED_CURRENT files={len(files)} store={a.storage}"); return 0
    a.storage.mkdir(parents=True, exist_ok=True)
    adapter = DMLAdapter(config_path=str(a.config), config_overrides={"storage_dir": str(a.storage)}, start_aging_loop=False)
    try:
        for f in files:
            adapter.ingest(f.read_text(encoding="utf-8"), meta={"tenant_id":"aec-demo", "client_id":"hermes-aec", "project_id":a.project_id, "kind":"action", "source":"aec-demo-seed", "memory_state":"active", "doc_path":str(f.resolve()), "no_merge":True})
    finally: adapter.close()
    marker.write_text(json.dumps(hashes, indent=2, sort_keys=True), encoding="utf-8")
    print(f"DML_SEEDED files={len(files)} store={a.storage}"); return 0
if __name__ == "__main__": raise SystemExit(main())
