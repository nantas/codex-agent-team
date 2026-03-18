# Role Override Path

## Fixture ID

`role-override-path`

## Scenario Intent

Validate that explicit user role overrides are accepted into the approved contract and carried into team/task artifacts without silent fallback to default role templates.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team, but enforce these roles:
  lead, planner, implementer, verifier.
  Do not use default role labels if they conflict with my override.
operator_overrides:
  roles:
    - lead
    - planner
    - implementer
    - verifier
expected_roles:
  - lead
  - planner
  - implementer
  - verifier
```

## Expected Phase Markers

- `panel.drafted`
- `panel.confirmed`
- `panel.override_roles_received`
- `panel.override_roles_applied`
- `team.formed`
- `tasks.assigned`
- `checkpoint.recorded`

## Expected Filesystem Artifacts

- `.codex/multi-agent/panel.json::json_non_empty=approved_contract`
- `.codex/multi-agent/team.json::json_array_non_empty=roles`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/handoffs.jsonl::jsonl_non_empty=true`

## Must-Not-Happen Markers

- `panel.override_ignored`
- `team.default_roles_used_after_override`
- `tasks.assigned_to_unapproved_role`
- `execution.started_before_panel_confirmation`

## Notes

The assertion focus is contract fidelity: once overrides are confirmed, role identity in `team.json` and task ownership in `tasks.json` must reflect the override set.
