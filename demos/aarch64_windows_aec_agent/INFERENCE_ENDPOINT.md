# Hermes inference configuration

Both Windows demos support custom OpenAI-compatible inference servers. Configure the API base
URL, served model ID, API mode, context length, and API key. The model must support tool calls for
the AEC tools, and image inputs if you need visual reasoning.

## Change an installed deployment

Close Hermes, then double-click `Configure-Inference.cmd`. It asks for the base URL, model ID,
and a hidden API key and updates both demo profiles. Interactive defaults are Chat Completions and
32,768 context tokens. For a server that does not require authentication, enter a nonempty
placeholder key such as `local`.

To supply the non-secret settings explicitly:

```bat
.\Configure-Inference.cmd -BaseUrl "http://localhost:8000/v1" -Model "my-served-model" -ContextLength 32768
```

For a Responses-compatible endpoint, add `-ApiMode codex_responses`. The default is
`-ApiMode chat_completions`. Set context length to a value supported by the server and model.
The script prompts for the key securely; do not put a plaintext key on the command line.
PowerShell automation can pass a `SecureString` via `-ApiKey`.

Use the API **base URL**, usually ending in `/v1`, including any required proxy prefix. Do not
append `/chat/completions` or `/responses`. URLs with embedded credentials, query strings,
fragments, or unsupported schemes are rejected. A trailing slash is normalized.

## Configure during deployment

```bat
.\Deploy-AECDemos.cmd -BaseUrl "http://localhost:8000/v1" -Model "my-served-model" -ContextLength 32768
```

Both `-BaseUrl` and `-Model` are required together. Custom deployment defaults to Chat Completions
and 32,768 context tokens. `-ApiMode codex_responses` selects Responses. Credentials use
`AEC_INFERENCE_API_KEY` by default; `-KeyEnvironmentVariable` selects another environment variable.
The installer prompts when a credential is missing or the saved endpoint changes and persists it in the local profile `.env`.
An environment-provided key is also persisted so Desktop launches work outside that shell.

A normal redeploy without `-BaseUrl`/`-Model` preserves each existing profile's inference settings
and credentials while refreshing the managed AEC configuration. Use `Configure-Inference.cmd`
to change inference without reinstalling DML, geometry tools, or the visualization stack.

## NVIDIA default

A fresh installation without custom settings retains the original NVIDIA configuration:

| Setting | Default |
|---|---|
| Provider | `custom:nvidia-switchyard` |
| Base URL | `https://inference-api.nvidia.com/v1` |
| Model | `switchyard/openai/gpt-5.6-sol` |
| API mode | `codex_responses` |
| Key variable | `NVIDIA_API_KEY` |
| Context length | `1000000` |

Custom configuration uses `custom:aec-inference` and removes the NVIDIA-specific `fast` service
tier. API keys remain in local `.env` files; `config.yaml` contains an environment-variable
reference, never the supplied key. Existing config files are backed up before replacement.
The helper uses PyYAML and python-dotenv from Hermes' managed Python environment.

## Rotate or erase the key

Run `Change_API_Key.cmd` to set, replace, or erase the active key for each demo profile. It follows
the configured key-variable name, including legacy `NVIDIA_API_KEY`, and preserves unrelated `.env`
entries. Restart Hermes after changes. If you also set the key in your shell or Windows environment,
remove it there to fully erase it: an environment credential remains a valid fallback.

## Verify

```bat
.\Test-InferenceEndpoint.cmd
```

The test reads the selected profile's current endpoint, model, API mode, and credential. It posts
a small request to `/chat/completions` or `/responses` and requires generated text before printing
`INFERENCE_ENDPOINT_PASS`. An ID-only response, empty result, or error payload does not pass.
The endpoint test rejects redirects instead of forwarding credentials.

For the other profile:

```powershell
.\Test-InferenceEndpoint.ps1 -Profile cliff-house-full-build-windows
```

`Test-AECDeployment.cmd` and the launchers validate Hermes' resolved provider and model against
the profile configuration. They do not require NVIDIA-specific values.

| Failure | Check |
|---|---|
| HTTP 401/403 | Key and access to the selected model |
| HTTP 404 | API base URL, model ID, and API mode |
| HTTP 400 | Supported API mode, model, and request parameters |
| No generated text | Model output, token budget, and server API compatibility |
| Connection/timeout | Server availability, address, port, and firewall |
| Configuration/dependency error | Complete Hermes installation; check `config.yaml` and its provider entry |

This feature configures inference only. CAD, Blender, and ComfyUI still require their normal
platform-specific installations. Linux already accepts its endpoint via `VLLM_BASE_URL`; this
Windows guide replaces the former NVIDIA-only setup.
