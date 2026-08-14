# Deploy the AEC demos on Linux/DGX Spark

Run one command from this folder:

```bash
bash ./deploy-aec-demos.sh
```

Requirements: Hermes Desktop for Linux must be installed as `hermes-desktop` (or its path supplied
as `HERMES_DESKTOP_BIN`), along with Git, Python 3.10+, FreeCAD, FreeCAD MCP, local vLLM, and an
NVIDIA GPU runtime. Internet access is required for the first Daystrom DML installation. DML does
not require Ollama, an embedding model, CMA, or another inference model in this package.

The installer asks for the model ID served by local vLLM, installs the pinned Daystrom DML runtime,
seeds separate compact procedural-memory stores, deploys two isolated Hermes profiles, and creates
two launchers on the desktop:

- **AEC Full Build** — builds the complete house in FreeCAD from the pinned source guides.
- **AEC House Modification** — creates and opens a working copy of the completed FreeCAD house.

Start the FreeCAD MCP bridge if the application does not start it automatically. To refresh an
existing deployment after pulling changes, run `FORCE=1 bash ./deploy-aec-demos.sh`.

Both launchers open the Hermes graphical desktop UI. They do not expose a terminal or Hermes TUI.
Memory retrieval is automatic; the operator does not need to mention DML.
