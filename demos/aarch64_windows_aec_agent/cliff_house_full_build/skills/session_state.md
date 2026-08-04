# Session state

The checked-in initial state is `hermes/phase_state.json`. Each live run copies that state into
ignored `work/<run-id>/phase_state.json` and updates only the copy. All paths resolve from the
active `cliff_house_full_build` workspace; no machine-specific user directory is assumed.

The full build begins at Phase 00 with empty Rhino and Blender documents. A phase may be resumed
only when the preceding receipt exists in the same run directory.
