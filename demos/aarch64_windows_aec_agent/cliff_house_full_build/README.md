# Cliff House full-build demo — Windows on ARM

This is the phase-driven construction demo adapted from the original Wagstaff workflow. It begins
with the supplied source curves and builds the house in Rhino; it never substitutes the completed
modification-demo model.

## Start

Install from the parent directory by following [../DEPLOY.md](../DEPLOY.md), then:

1. close other Rhino demo sessions;
2. double-click **AEC Full Build**;
3. run `AECMCPStart` in Rhino if the launcher reports that port `1999` is offline; and
4. tell Hermes: `Start the cliff house full build.`

The shortcut selects the isolated `cliff-house-full-build-windows` profile and opens Hermes
Desktop. The workflow reads:

- `projects/cliff_house_02/rhino_assets/base_model.3dm` — required source curves;
- `projects/cliff_house_02/user_prompts/project_prompt.md` — original design program;
- `projects/cliff_house_02/golden_build_contract.json` — machine-checkable target contract; and
- `system_prompts/` and `PLAYBOOK.md` — phase gates and execution rules.

Generated files belong under ignored `work/` or `outputs/` directories. The completed golden
master in the modification package is comparison-only and must never be used as full-build input.

The typed operation catalog is preferred. This profile alone retains a bounded transactional
Python escape hatch for construction operations that the typed catalog cannot express; every such
mutation still requires checkpointing and independent verification.

For requirements, deployment verification, and repair, use the parent
[deployment guide](../DEPLOY.md).
