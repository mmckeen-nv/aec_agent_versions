# Procedural memory runtime

`Install-AECDml.ps1` installs the pinned Daystrom DML runtime used by both Windows demos. Each
Hermes profile receives its own store and seeds only the Markdown records in that demo's `memory/`
directory. The configuration deliberately needs no local embedding or inference model because
each curated seed set fits within one bounded retrieval.

Run the platform-level `Deploy-AECDemos.ps1`; do not run this component separately during normal
deployment. Runtime stores live under `%LOCALAPPDATA%\hermes\integrations\daystrom-dml\stores` and
must not be committed.
