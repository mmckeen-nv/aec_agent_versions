# Step 3 — Install Hermes in OOBE state and validate vLLM

**Status: Clean-install path validated on 2026-08-04**

## OOBE-first policy

The distributable Spark image must not preselect local vLLM, a cloud provider, or an API key.
Leave Hermes in its normal first-run state and let the user select a provider and model through
the setup wizard. The running vLLM endpoint is an available local option, not the default.

## Perform the clean installation

Stop Hermes Desktop, gateway, serve, and chat processes first. Review the installer, then run:

```bash
cd ~/Local-AEC-Agent-Cloud-Endpoint
sed -n '1,240p' platform/linux-dgx-spark/scripts/install-hermes-oobe.sh
bash platform/linux-dgx-spark/scripts/install-hermes-oobe.sh
```

The installer pins Hermes `0.17.0` at commit `9be292f1e678`, moves an existing `~/.hermes`
tree into a mode-0700 deployment backup, creates a fresh virtual environment, and installs
`~/.local/bin/hermes`. It does not copy profiles, credentials, providers, models, memory
providers, or MCP entries into the new installation. vLLM, FreeCAD, Blender, and ComfyUI are
outside its replacement scope.

## Validate the endpoint

```bash
curl -fsS http://127.0.0.1:8000/health
curl -fsS http://127.0.0.1:8000/v1/models | python3 -m json.tool
```

## Validate OOBE without exposing credentials

```bash
test ! -f ~/.hermes/config.yaml
test ! -d ~/.hermes/profiles
test ! -f ~/.hermes/.env
test ! -f ~/.hermes/auth.json
timeout 30 ~/.local/bin/hermes </dev/null || test $? -eq 1
```

Do not print `.env`, authentication files, or API keys into logs. A local vLLM deployment may
use a non-secret placeholder when the endpoint does not enforce authentication.

Expected result: Hermes reports that it is not configured and directs an interactive user to
`hermes setup`. Local vLLM is one available custom OpenAI-compatible endpoint at
`http://127.0.0.1:8000/v1`; it is not selected automatically and does not require Ollama.

Do not attach FreeCAD or Blender MCP until the user has completed setup and selected the
profile that should own those tools.

Next: [Deploy ComfyUI](04-comfyui.md).
