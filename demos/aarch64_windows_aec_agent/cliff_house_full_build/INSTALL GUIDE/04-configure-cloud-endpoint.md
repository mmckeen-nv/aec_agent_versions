# Step 3 — Deploy Hermes and connect Rhino MCP

1. Install Hermes and complete its normal first-run flow.
2. Start the Rhino MCP listener and note its loopback port.
3. Deploy an isolated full-build profile:

```powershell
.\installer\Deploy-HermesProfile.ps1 `
  -Profile cliff-house-full-build-windows `
  -RhinoPort 1999
```

4. Store `NVIDIA_API_KEY` through Hermes' secret UI or in the profile environment; never put it in
   this repository or `config.yaml`.
5. If using another Responses-compatible provider, pass `-Provider`, `-Model`, `-BaseUrl`, and
   `-ContextLength` explicitly.
6. Verify the deployment:

```powershell
.\installer\Test-LocalAEC.ps1 -Profile cliff-house-full-build-windows -RhinoPort 1999
```

The deployer refuses to overwrite an existing profile unless `-Force` is supplied and creates a
timestamped configuration backup when forced.
