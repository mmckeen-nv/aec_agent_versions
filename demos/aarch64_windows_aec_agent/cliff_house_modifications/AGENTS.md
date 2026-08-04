# Cliff House quick-modification context

This workspace is the Windows ARM64 **Cliff House Modifications** demo. It is isolated from
`cliff_house_full_build` and may not read or modify that workflow's profile, project, sessions,
outputs, or state.

Use the protected Rhino and Blender masters only to create timestamped working copies under an
ignored `work/` directory. Inspect the working document before mutation, require an explicit
target for deletion or replacement, and report changed object counts. Never overwrite a file
containing `MASTER` or `HERO`.

Hermes configuration is user-owned. Do not select or change inference providers, models,
endpoints, credentials, or the active profile. DML and CMA are out of scope.
