# Inference endpoint configuration

Use the top-level `Deploy-AECDemos.ps1`; do not deploy this profile manually. The supported
endpoint is `https://inference-api.nvidia.com/v1/responses`, using
`switchyard/openai/gpt-5.6-sol` in `codex_responses` mode with a 1,000,000-token context window.

Follow [../../INFERENCE_ENDPOINT.md](../../INFERENCE_ENDPOINT.md) for secure API-key entry,
independent verification, replacement, and troubleshooting.
