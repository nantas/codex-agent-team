# EMFILE Downgrade Path

## Fixture ID

`emfile-downgrade-path`

## Scenario Intent

Validate FD exhaustion guardrails: when `EMFILE` (`Too many open files` / `os error 24`) appears, execution auto-downgrades to `serial`, pauses new spawn waves, and records downgrade evidence in checkpoint state.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team and simulate FD pressure.
  If EMFILE appears, downgrade to serial and pause new spawn waves
  until stabilization evidence is recorded.
operator_overrides:
  simulate_fd_exhaustion: true
  enforce_serial_downgrade: true
expected_guardrail:
  - emfile_detected
  - mode_downgraded_parallel_to_serial
  - spawn_waves_paused_until_stable
```

## Expected Phase Markers

- `panel.confirmed`
- `team.formed`
- `tasks.assigned`
- `resource.fd_budget.persisted`
- `resource.fd.emfile_detected`
- `execution.mode.serial_downgraded`
- `execution.spawn_waves.paused`
- `checkpoint.recorded`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json::json_non_empty=fd_downgrade.trigger`
- `.codex/multi-agent/session.json::json_key=fd_downgrade.mode_before`
- `.codex/multi-agent/session.json::json_key=fd_downgrade.mode_after`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/compact-recovery.json::json_key=suspendedAgents`

## Must-Not-Happen Markers

- `resource.emfile_spawn_wave_continued`
- `resource.emfile_downgrade_undocumented`
- `resource.emfile_parallel_before_stable`
- `resource.emfile_guardrail_omitted`

## Notes

This fixture checks downgrade control flow and checkpoint evidence, not performance characteristics.
