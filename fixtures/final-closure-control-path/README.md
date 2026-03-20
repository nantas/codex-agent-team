# Final Closure Control Path

## Fixture ID

`final-closure-control-path`

## Scenario Intent

Validate hard closure gate discipline and explicit workflow completion signaling before orchestration can end.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Finish the workflow and close it deterministically.
  Do not stop before explicit final user notice and closed state persistence.
operator_overrides:
  enforce_closure_gates: true
expected_closure_chain:
  - synthesis_done
  - delivery_packaging
  - closure_review
  - user_final_notice
  - workflow_closed
```

## Expected Phase Markers

- `closure.phase.synthesis_done`
- `closure.phase.delivery_packaging`
- `closure.phase.closure_review`
- `closure.phase.user_final_notice`
- `closure.phase.workflow_closed`
- `closure.notice.sent`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json::json_non_empty=workflow_status`
- `.codex/multi-agent/compact-recovery.json::json_non_empty=closure_state`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`

## Must-Not-Happen Markers

- `closure.phase.skip_detected`
- `closure.closed_without_notice`
- `closure.notice.missing`

## Notes

This fixture validates closure control behavior and state synchronization, not domain-specific analysis quality.
