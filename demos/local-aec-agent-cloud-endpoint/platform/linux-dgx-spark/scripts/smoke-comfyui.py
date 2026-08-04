#!/usr/bin/env python3
"""Submit a tiny deterministic CUDA workflow to the local ComfyUI service."""

from __future__ import annotations

import json
import time
import urllib.request

BASE = "http://127.0.0.1:8188"
workflow = {
    "1": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "DreamShaper_8_pruned.safetensors"}},
    "2": {"class_type": "CLIPTextEncode", "inputs": {"text": "architectural material study, concrete and glass, neutral studio light", "clip": ["1", 1]}},
    "3": {"class_type": "CLIPTextEncode", "inputs": {"text": "text, watermark, low quality", "clip": ["1", 1]}},
    "4": {"class_type": "EmptyLatentImage", "inputs": {"width": 256, "height": 256, "batch_size": 1}},
    "5": {"class_type": "KSampler", "inputs": {"seed": 7319, "steps": 4, "cfg": 6.0, "sampler_name": "euler", "scheduler": "normal", "denoise": 1.0, "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0]}},
    "6": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["1", 2]}},
    "7": {"class_type": "SaveImage", "inputs": {"filename_prefix": "local_aec_smoke", "images": ["6", 0]}},
}


def request(path: str, payload: dict | None = None) -> dict:
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(BASE + path, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as response:
        return json.load(response)


result = request("/prompt", {"prompt": workflow})
prompt_id = result["prompt_id"]
for _ in range(180):
    history = request(f"/history/{prompt_id}")
    if prompt_id in history:
        images = history[prompt_id].get("outputs", {}).get("7", {}).get("images", [])
        if not images:
            raise SystemExit("workflow completed without an image")
        print(f"COMFYUI_CUDA_SMOKE_PASS prompt_id={prompt_id} file={images[0]['filename']}")
        break
    time.sleep(1)
else:
    raise SystemExit("workflow did not complete within 180 seconds")
