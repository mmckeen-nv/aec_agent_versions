# Configure the NVIDIA inference endpoint

Both Windows demos use the same Responses-compatible endpoint:

| Setting | Required value |
|---|---|
| Provider | `custom:nvidia-switchyard` |
| Base URL | `https://inference-api.nvidia.com/v1` |
| Responses URL | `https://inference-api.nvidia.com/v1/responses` |
| Model | `switchyard/openai/gpt-5.6-sol` |
| API mode | `codex_responses` |
| Context window | `1000000` |
| Key variable | `NVIDIA_API_KEY` |
| Authentication | `Authorization: Bearer <NVIDIA_API_KEY>` |
| Request content type | `application/json` |
| Hermes service tier | `fast` |
| Hermes reasoning effort | `medium` |

Do not paste the API key into `config.yaml`, a prompt, a log, or this repository.

## Complete Hermes configuration

The installer generates this inference section in **both** demo profiles:

```yaml
model:
  provider: custom:nvidia-switchyard
  default: switchyard/openai/gpt-5.6-sol
  base_url: https://inference-api.nvidia.com/v1
  api_key: ${NVIDIA_API_KEY}
  context_length: 1000000

providers:
  nvidia-switchyard:
    name: nvidia-switchyard
    base_url: https://inference-api.nvidia.com/v1
    key_env: NVIDIA_API_KEY
    default_model: switchyard/openai/gpt-5.6-sol
    api_mode: codex_responses
    context_length: 1000000

agent:
  service_tier: fast
  reasoning_effort: medium
```

The profile `.env` file contains exactly the secret binding:

```dotenv
NVIDIA_API_KEY=<key issued for this endpoint>
```

Important details:

- `model.provider` includes the `custom:` prefix; the provider definition beneath `providers` does
  not.
- `base_url` ends at `/v1`. Do not put `/responses` in `base_url`; Hermes appends the Responses
  route because `api_mode` is `codex_responses`.
- This endpoint uses the OpenAI **Responses** request shape, not Chat Completions.
- The one-million-token value declares the model context available to Hermes. It is not
  `max_output_tokens` and does not force every request to contain one million tokens.
- There is no endpoint autodetection or fallback model in these demo profiles. These values are
  deliberate and must remain together.

## Known-good HTTP request

The provider must accept this contract:

```http
POST /v1/responses HTTP/1.1
Host: inference-api.nvidia.com
Authorization: Bearer <NVIDIA_API_KEY>
Content-Type: application/json
```

```json
{
  "model": "switchyard/openai/gpt-5.6-sol",
  "input": "Reply with the single word READY.",
  "max_output_tokens": 16
}
```

An HTTP success with a Responses payload containing an `id` or `output` proves the endpoint,
credential, model route, and request protocol are compatible. It does not prove RhinoMCP is
running; that is a separate local check.

## Recommended setup

1. Obtain an NVIDIA inference API key that is authorized for
   `switchyard/openai/gpt-5.6-sol`.
2. Close Hermes Desktop and Rhino.
3. Open PowerShell in `demos\aarch64_windows_aec_agent`.
4. Run:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   .\Deploy-AECDemos.ps1
   ```

5. When `NVIDIA API key` appears, paste the key and press Enter. PowerShell does not display the
   pasted characters.
6. Wait for `AEC_DEMOS_DEPLOYED`.

The installer writes `NVIDIA_API_KEY` only to the local `.env` files for:

- `%LOCALAPPDATA%\hermes\profiles\cliff-house-full-build-windows\.env`
- `%LOCALAPPDATA%\hermes\profiles\cliff-house-modifications-windows\.env`

The generated `config.yaml` files contain `${NVIDIA_API_KEY}`, not the secret itself.

If `NVIDIA_API_KEY` already exists in the PowerShell environment, the installer uses it without
prompting. On a repair run it reuses the key already stored in either demo profile.

## Verify inference independently

With Hermes closed, run:

```powershell
.\Test-InferenceEndpoint.ps1
```

Expected result:

```text
INFERENCE_ENDPOINT_PASS model=switchyard/openai/gpt-5.6-sol ...
```

This sends one tiny request directly to the Responses endpoint. It does not start Rhino, modify a
model, print the key, or print generated response text.

To test the other profile explicitly:

```powershell
.\Test-InferenceEndpoint.ps1 -Profile cliff-house-full-build-windows
```

## Replace an expired or incorrect key

Close Hermes and Rhino. Remove only the `NVIDIA_API_KEY=` line from each demo profile `.env`, then
force a managed refresh:

```powershell
.\Deploy-AECDemos.ps1 -RhinoPort 1999 -Force
.\Test-InferenceEndpoint.ps1
```

Because no old key remains, the installer prompts securely and hides the pasted characters. It
then writes the replacement to both profiles. Do not use a permanent machine-wide environment
variable for a demo credential.

## Manual Hermes UI mapping

The managed installer is the supported path. If an operator must compare the generated profile to
Hermes UI fields, the mapping is:

| Hermes field | Value |
|---|---|
| Provider type | Custom / OpenAI-compatible |
| Provider name | `nvidia-switchyard` |
| API base URL | `https://inference-api.nvidia.com/v1` |
| API protocol | Responses / `codex_responses` |
| Default model | `switchyard/openai/gpt-5.6-sol` |
| Context length | `1000000` |
| API key source | Environment variable `NVIDIA_API_KEY` |

Do not use the UI to attach RhinoMCP directly. The inference provider and the typed Rhino sidecar
are separate sections of the profile.

## Troubleshooting

| Result | Meaning | Action |
|---|---|---|
| `401` or `403` | Missing, expired, or unauthorized key | Replace the key and rerun the forced deployment |
| `404` | Wrong base URL, API mode, or model route | Restore the exact values in the table by rerunning the installer |
| Model-access error | Key lacks Switchyard model entitlement | Request access to `switchyard/openai/gpt-5.6-sol` |
| Connection or TLS failure | Network, proxy, DNS, or certificate issue | Verify HTTPS access to `inference-api.nvidia.com` |
| Test passes but Hermes fails | Hermes has stale configuration in memory | Close all Hermes processes and relaunch from an AEC shortcut |

The inference endpoint is unrelated to RhinoMCP. Inference uses NVIDIA HTTPS; Rhino geometry tools
use the local typed sidecar and Rhino-owned loopback listener on port `1999`.
