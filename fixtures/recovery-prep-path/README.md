# Recovery Prep Path

## Fixture ID

`recovery-prep-path`

## Scenario Intent

Validate compact/recovery preparation behavior: before handoff or finish, a fresh `compact-recovery.json` exists with resume-critical fields and current blockers/next actions.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team and prepare for potential compact/handoff.
  Ensure recovery data is current before final status.
operator_overrides:
  compact_risk_simulation: true
expected_recovery_read_order:
  - compact-recovery.json
  - session.json
  - tasks.json
  - checkpoints.json
```

## Expected Phase Markers

- `panel.confirmed`
- `team.formed`
- `tasks.assigned`
- `checkpoint.recorded`
- `recovery.prep_started`
- `recovery.snapshot_refreshed`
- `recovery.resume_point_declared`

## Expected Filesystem Artifacts

- `.codex/multi-agent/compact-recovery.json::json_non_empty=session_id`
- `.codex/multi-agent/compact-recovery.json::json_non_empty=next_actions`
- `.codex/multi-agent/compact-recovery.json::json_non_empty=last_checkpoint_id`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`
- `.codex/multi-agent/last-breaths.jsonl`

## Must-Not-Happen Markers

- `recovery.snapshot_missing_before_finish`
- `recovery.resume_point_missing`
- `recovery.read_order_violated`
- `compact.invoked_without_fresh_checkpoint`

## Notes

`last-breaths.jsonl` is optional in healthy runs but remains part of the expected artifact surface for interruption-capable scenarios.
