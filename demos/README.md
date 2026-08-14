# AEC demo packages

These packages adapt the reference [2026 AEC CPTX demo](https://github.com/stwagstaff/2026_aec_cptx_demo)
for Hermes-managed deployments. Each package must preserve the upstream project assets and phase
prompts while limiting platform differences to installers, MCP endpoints, and inference settings.

| Platform | Full reconstruction | Existing-model modifications |
|---|---|---|
| Windows ARM64 | [`aarch64_windows_aec_agent/cliff_house_full_build`](aarch64_windows_aec_agent/cliff_house_full_build/) | [`aarch64_windows_aec_agent/cliff_house_modifications`](aarch64_windows_aec_agent/cliff_house_modifications/) |
| Ubuntu ARM64 | [`aarch64_ubuntu_aec_agent/cliff_house_full_build`](aarch64_ubuntu_aec_agent/cliff_house_full_build/) | [`aarch64_ubuntu_aec_agent/cliff_house_modifications`](aarch64_ubuntu_aec_agent/cliff_house_modifications/) |

## Package contract

Every deployable demo should provide:

- one obvious README entrypoint;
- a credential-free Hermes configuration template;
- an idempotent installer or profile deployment command;
- the exact source assets required by its workflow;
- a smoke test that checks inference, MCP discovery, document reads, and reversible writes;
- provenance identifying the upstream repository and revision;
- no generated sessions, logs, credentials, outputs, or machine-specific paths.

Both platforms consume the independent `mmckeen-nv/hermes-aec-runtime` release pinned in
[`hermes-aec-runtime.version`](hermes-aec-runtime.version). Windows keeps Rhino MCP as its geometry
authority; Linux keeps FreeCAD MCP. The shared sidecar owns the host-neutral execution contract.

## Do not mix the workflows

| Workflow | Windows/Rhino input | Linux/FreeCAD input | Completed master allowed? |
|---|---|---|---|
| Quick modifications | Timestamped copy of `cliff_house_HERO_RHINO_MODEL.3dm` | Timestamped copy of `cliff_house_FREECAD_MASTER.FCStd` | Yes—working copy only |
| Full build | `base_model.3dm` source curves | `source_curves.json` reconstructed guides | No—comparison only |

The full build is reference-driven construction, not an empty-document improvisation and not a
completed-model import. The quick demo deliberately starts from completed geometry and must never
write to the checked-in master.
