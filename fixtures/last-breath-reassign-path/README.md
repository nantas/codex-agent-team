# Last Breath Reassign Path

## Fixture ID

`last-breath-reassign-path`

## Scenario Intent

Validate that an unexpected specialist exit is captured in `last-breaths.jsonl`, followed by immediate checkpoint and deterministic reassign/recovery actions by lead.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  A specialist failed unexpectedly.
  Capture last-breath details, checkpoint the decision, and continue via reassigned ownership.
operator_overrides:
  enforce_last_breath_capture: true
  enforce_reassign_after_exit: true
expected_behavior:
  - capture_last_breath
  - checkpoint_after_exit
  - reassign_or_retry_decision
  - refresh_recovery_snapshot
```

## Expected Phase Markers

- `specialist.exit.unexpected`
- `last_breath.captured`
- `checkpoint.recorded`
- `tasks.reassigned`
- `recovery.snapshot_refreshed`

## Expected Filesystem Artifacts

- `.codex/multi-agent/last-breaths.jsonl::jsonl_non_empty=true`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/compact-recovery.json::json_array_non_empty=next_actions`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`

## Must-Not-Happen Markers

- `last_breath.missing`
- `specialist.exit.ignored`
- `reassign.skipped_after_exit`

## Notes

This fixture validates recovery discipline after abnormal exit, not feature-level implementation quality.
