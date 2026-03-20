# Scope Drift Recovery Path

## Fixture ID

`scope-drift-recovery-path`

## Scenario Intent

Validate that when user scope changes mid-execution, the lead records scope drift, checkpoints the decision, replans tasks, and refreshes compact recovery with the updated contract.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Continue current workflow but update scope and constraints based on new findings.
  Detect drift, checkpoint the change, and resume with replanned tasks.
operator_overrides:
  enforce_scope_drift_checkpoint: true
  enforce_replan_after_scope_change: true
expected_behavior:
  - detect_scope_drift
  - update_approved_contract
  - checkpoint_after_scope_change
  - refresh_compact_recovery
```

## Expected Phase Markers

- `scope.drift.detected`
- `scope.contract.updated`
- `tasks.replanned`
- `checkpoint.recorded`
- `recovery.snapshot_refreshed`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json::json_key=scope_drift_state.detected`
- `.codex/multi-agent/panel.json::json_non_empty=approved_contract.scope_revision`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/compact-recovery.json::json_non_empty=open_blockers`

## Must-Not-Happen Markers

- `scope.drift.ignored`
- `scope.contract.updated_without_checkpoint`
- `scope.replan.skipped`

## Notes

This fixture targets drift-handling workflow correctness and deterministic recovery handoff after scope change.
