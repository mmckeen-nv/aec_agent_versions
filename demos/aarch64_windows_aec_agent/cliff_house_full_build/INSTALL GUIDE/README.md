# Install guide — Cliff House full build on Windows ARM64

## Outcome

The package deploys a dedicated, credential-free Hermes profile containing the Wagstaff source
model, project brief, phase prompts, skills, NVIDIA Responses endpoint template, and configurable
Rhino MCP registration. Rhino, Blender, and ComfyUI remain local GUI apps.

## Order

1. [Check system requirements](01-system-requirements.md).
2. [Install applications](02-install-applications.md).
3. [Deploy the Hermes profile and connect MCP](04-configure-cloud-endpoint.md).
4. [Run the full build](05-run-cliff-house-demo.md).
5. [Verify](06-verify-stack.md) or [roll back](08-cleanup-and-rollback.md).

The repository never stores credentials. Supply `NVIDIA_API_KEY` through Hermes secrets or the
deployed profile environment.
