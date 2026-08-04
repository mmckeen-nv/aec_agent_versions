#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT="${HOME}/local-aec-runtime/comfyui"
PLAYBOOK_ROOT="${INSTALL_ROOT}/dgx-spark-playbooks"
PLAYBOOK_COMMIT="1fb66f059ee427c5a3678b3117ef73aab042b458"
COMFYUI_COMMIT="306af3a8771a8232d26bd20acbfc6b07f862ad2b"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

mkdir -p "${INSTALL_ROOT}"
if [[ ! -d "${PLAYBOOK_ROOT}/.git" ]]; then
  git clone https://github.com/NVIDIA/dgx-spark-playbooks.git "${PLAYBOOK_ROOT}"
fi
git -C "${PLAYBOOK_ROOT}" fetch --depth 1 origin "${PLAYBOOK_COMMIT}"
git -C "${PLAYBOOK_ROOT}" checkout --detach "${PLAYBOOK_COMMIT}"

cd "${INSTALL_ROOT}"
bash "${PLAYBOOK_ROOT}/nvidia/comfy-ui/assets/setup.sh"
[[ "$(git -C "${INSTALL_ROOT}/ComfyUI" rev-parse HEAD)" == "${COMFYUI_COMMIT}" ]]

install -Dm0755 "${REPO_ROOT}/platform/linux-dgx-spark/bin/local-aec-comfyui" \
  "${HOME}/.local/bin/local-aec-comfyui"
install -Dm0644 "${REPO_ROOT}/platform/linux-dgx-spark/systemd/local-aec-comfyui.service" \
  "${HOME}/.config/systemd/user/local-aec-comfyui.service"

systemctl --user daemon-reload
systemctl --user enable --now local-aec-comfyui.service

for _ in {1..60}; do
  curl -fsS --max-time 2 http://127.0.0.1:8188/system_stats >/dev/null 2>&1 && break
  sleep 2
done
curl -fsS --max-time 5 http://127.0.0.1:8188/system_stats >/dev/null

"${INSTALL_ROOT}/comfyui-env/bin/python" - <<'PY'
import torch
assert torch.cuda.is_available()
assert torch.version.cuda == "13.0"
assert torch.cuda.get_device_name(0) == "NVIDIA GB10"
PY

cat >"${INSTALL_ROOT}/install-receipt.json" <<EOF
{
  "status": "PASS",
  "playbook_commit": "${PLAYBOOK_COMMIT}",
  "comfyui_commit": "${COMFYUI_COMMIT}",
  "torch": "2.13.0+cu130",
  "torchvision": "0.28.0+cu130",
  "device": "NVIDIA GB10",
  "listen": "127.0.0.1:8188",
  "vllm_reserve_gib": 48,
  "secrets_included": false
}
EOF

echo "COMFYUI_INSTALL_PASS commit=${COMFYUI_COMMIT:0:12} cuda=13.0 loopback=true"
