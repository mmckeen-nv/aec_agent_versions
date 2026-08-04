# Install guide — Cliff House full build on Windows ARM64

## Outcome

Hermes Desktop completes its normal OOBE, then this full-build workspace is registered in a
dedicated operator-selected profile. Rhino, Blender, and ComfyUI remain local GUI apps; their MCP
bridges bind to loopback.

## Order

1. [Check system requirements](01-system-requirements.md).
2. [Install applications](02-install-applications.md).
3. [Complete Hermes OOBE and connect MCP](04-configure-cloud-endpoint.md).
4. [Run the full build](05-run-cliff-house-demo.md).
5. [Verify](06-verify-stack.md) or [roll back](08-cleanup-and-rollback.md).

The repository does not provide a populated Hermes configuration or credential file.
