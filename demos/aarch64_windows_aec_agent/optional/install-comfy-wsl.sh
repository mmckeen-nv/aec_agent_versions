#!/usr/bin/env bash
set -euo pipefail

target_user="$1"
models_root="$2"
version="v0.33.1"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
install_root="$target_home/.local/share/hermes-aec/comfyui"

test -n "$target_home"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl git python3.12-venv python3.12-dev build-essential

if [ ! -d "$install_root/ComfyUI/.git" ]; then
  install -d -o "$target_user" -g "$target_user" "$install_root"
  runuser -u "$target_user" -- git clone --branch "$version" --depth 1 https://github.com/Comfy-Org/ComfyUI.git "$install_root/ComfyUI"
fi
if [ ! -x "$install_root/venv/bin/python" ]; then
  runuser -u "$target_user" -- python3.12 -m venv "$install_root/venv"
fi
runuser -u "$target_user" -- "$install_root/venv/bin/python" -m pip install --upgrade pip
runuser -u "$target_user" -- "$install_root/venv/bin/python" -m pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130
runuser -u "$target_user" -- "$install_root/venv/bin/python" -m pip install -r "$install_root/ComfyUI/requirements.txt"

for mapping in \
  "diffusion_models/flux-2-klein-base-4b-fp8.safetensors" \
  "text_encoders/qwen_3_4b.safetensors" \
  "vae/flux2-vae.safetensors"; do
  destination="$install_root/ComfyUI/models/$mapping"
  mkdir -p "$(dirname "$destination")"
  if [ ! -f "$destination" ] || [ "$(stat -c %s "$destination")" != "$(stat -c %s "$models_root/$mapping")" ]; then
    rm -f "$destination"
    cp "$models_root/$mapping" "$destination.partial"
    mv "$destination.partial" "$destination"
  fi
done
chown -R "$target_user:$target_user" "$install_root"

cat >"$install_root/start-comfyui.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "$install_root"
exec > >(tee "$install_root/comfyui.log") 2>&1
echo "COMFY_PROCESS_START user=\$(id -un) root=\$(pwd)"
exec venv/bin/python ComfyUI/main.py --listen 0.0.0.0 --port 8188 --disable-auto-launch
EOF
chmod 0755 "$install_root/start-comfyui.sh"
chown "$target_user:$target_user" "$install_root/start-comfyui.sh"
runuser -u "$target_user" -- "$install_root/venv/bin/python" -c 'import torch; assert torch.cuda.is_available(); print("WSL_CUDA_PASS", torch.__version__, torch.version.cuda, torch.cuda.get_device_name(0))'
echo "COMFY_WSL_INSTALL_READY root=$install_root startup=attached-launcher"
