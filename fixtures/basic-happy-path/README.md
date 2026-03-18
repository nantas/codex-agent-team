# Basic Happy Path

## Fixture ID

`basic-happy-path`

## Scenario Intent

Validate baseline end-to-end workflow correctness for `codex-agent-team`: panel confirmation before orchestration, shared-state initialization, team formation, and at least one checkpoint plus recovery snapshot refresh.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team to plan and execute a small multi-agent task in this repository.
  Keep scope tight and finish with a verification pass.
operator_overrides: []
expected_roles:
  - lead
  - implementation
  - verification
```

## Expected Phase Markers

- `panel.drafted`
- `panel.confirmed`
- `execution.orchestration_started`
- `team.formed`
- `tasks.assigned`
- `checkpoint.recorded`
- `recovery.snapshot_refreshed`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json`
- `.codex/multi-agent/panel.json::json_non_empty=approved_contract`
- `.codex/multi-agent/team.json`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/compact-recovery.json::json_non_empty=next_actions`
- `.codex/multi-agent/reports.jsonl::jsonl_non_empty=true`

## Must-Not-Happen Markers

- `execution.started_before_panel_confirmation`
- `team.formation_without_approved_contract`
- `checkpoint.missing_before_finish`
- `recovery.snapshot_missing_before_finish`

## Notes

This fixture is the baseline contract for all other scenarios. Assertions should fail fast if either filesystem evidence or session-log-derived markers are missing.
