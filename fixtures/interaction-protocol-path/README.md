# Interaction Protocol Path

## Fixture ID

`interaction-protocol-path`

## Scenario Intent

Validate unified user interaction protocol for both `parallel` and `serial` execution, including lead-side preflight checks for `request_user_input` capability/config, stage-based batching (`3+2`), and structured answer routing to task owners.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team and run a clarification-heavy stage.
  Confirm interaction preflight first, then batch 5 questions as 3+2,
  and route answers by question_id to relevant owners only.
operator_overrides:
  interaction_stage_size: 5
  expected_batching: [3, 2]
  execution_mode: parallel
expected_behavior:
  - lead_only_request_user_input
  - no_direct_user_subagent_chat
  - structured_reply_route
```

## Expected Phase Markers

- `interaction.preflight.started`
- `interaction.preflight.config_checked`
- `interaction.preflight.passed`
- `interaction.boundary.announced`
- `interaction.stage.collected`
- `interaction.batch.1.sent`
- `interaction.batch.1.received`
- `interaction.batch.2.sent`
- `interaction.batch.2.received`
- `interaction.routing.applied`
- `interaction.state.synced`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json::json_key=execution_mode`
- `.codex/multi-agent/session.json::json_key=awaiting_user_reply`
- `.codex/multi-agent/session.json::json_key=awaiting_mode`
- `.codex/multi-agent/session.json::json_key=question_stage_id`
- `.codex/multi-agent/session.json::json_key=question_batch_index`
- `.codex/multi-agent/session.json::json_array_non_empty=question_ids`
- `.codex/multi-agent/session.json::json_non_empty=reply_route`
- `.codex/multi-agent/session.json::json_non_empty=last_sync_turn_id`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`

## Must-Not-Happen Markers

- `interaction.preflight.skipped`
- `interaction.subagent.direct_user_input`
- `interaction.unstructured_large_relay`
- `interaction.unbatched_stage_questions`

## Notes

This fixture focuses on interaction correctness and routing discipline. It does not score implementation quality beyond interaction preflight/batching/routing guarantees.
