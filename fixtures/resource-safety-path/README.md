# Resource Safety Path

## Fixture ID

`resource-safety-path`

## Scenario Intent

Validate specialist lifecycle discipline for resource safety: explicit `close_agent` cleanup, suspended-state persistence, and deterministic `resume_agent` sequencing from checkpoint evidence.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team with explicit suspend/resume handling.
  After specialist handoff, close specialists, persist suspended state,
  then resume in deterministic order from checkpoint evidence.
operator_overrides:
  enforce_resource_cleanup: true
  enforce_deterministic_resume: true
expected_lifecycle:
  - wait_then_checkpoint_then_close
  - resume_then_scoped_send_input
```

## Expected Phase Markers

- `panel.confirmed`
- `team.formed`
- `tasks.assigned`
- `checkpoint.recorded`
- `resource.budget.persisted`
- `resource.close_agent.cleanup`
- `recovery.suspended_agents.refreshed`
- `resource.resume_agent.rehydrated`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json::json_key=resource_budget.max_concurrent_specialists`
- `.codex/multi-agent/compact-recovery.json::json_array_non_empty=suspendedAgents`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/handoffs.jsonl::jsonl_non_empty=true`

## Must-Not-Happen Markers

- `resource.close_agent.skipped`
- `resource.resume_without_checkpoint_handoff`
- `resource.suspended_agents_stale`
- `resource.resume_order_nondeterministic`

## Notes

This fixture enforces suspend/resume evidence in shared state instead of relying on conversational text only.
