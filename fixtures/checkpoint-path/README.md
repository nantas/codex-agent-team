# Checkpoint Path

## Fixture ID

`checkpoint-path`

## Scenario Intent

Validate mandatory checkpoint discipline: checkpoint creation at required execution boundaries with persisted checkpoint state and decision/rationale capture.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team and force at least one explicit phase transition
  (assignment to integration to verification). Keep checkpoint records complete.
operator_overrides:
  require_checkpoint_boundaries: true
expected_checkpoint_boundaries:
  - after_panel_confirmation
  - before_integration
```

## Expected Phase Markers

- `panel.confirmed`
- `team.formed`
- `tasks.assigned`
- `checkpoint.after_panel_confirmation`
- `checkpoint.before_integration`
- `execution.integration_started`
- `checkpoint.recorded`

## Expected Filesystem Artifacts

- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`
- `.codex/multi-agent/team.json::json_array_non_empty=roles`
- `.codex/multi-agent/compact-recovery.json::json_non_empty=last_checkpoint_id`
- `.codex/multi-agent/reports.jsonl::jsonl_non_empty=true`

## Must-Not-Happen Markers

- `checkpoint.skipped_required_boundary`
- `checkpoint.incomplete_actions`
- `execution.phase_transition_without_checkpoint`
- `compact.invoked_with_stale_recovery_snapshot`

## Notes

This fixture targets correctness of `checkpoints.json` persistence and boundary ordering, not the quality of integration output.
