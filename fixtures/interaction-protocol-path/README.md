# Interaction Protocol Path

## Fixture ID

`interaction-protocol-path`

## Scenario Intent

Validate execution-time interaction display behavior for both `parallel` and `serial` modes: summary-first rendering, valid indentation depth, template-conformant event rows, and truncation of long field values in collapsed lines.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Use codex-agent-team and show execution interaction events.
  Keep logs summary-first, then show expanded details on demand.
  Ensure long message content is truncated in collapsed view.
operator_overrides:
  output_line_width: 100
  max_field_display_chars: 140
  execution_mode: parallel
expected_behavior:
  - collapsed_then_expanded
  - depth_max_two
  - display_template_compliance
  - truncation_with_ellipsis
```

## Expected Phase Markers

- `interaction.display.summary_first`
- `interaction.display.sent_input.collapsed`
- `interaction.display.sent_input.expanded`
- `interaction.display.finished_waiting.collapsed`
- `interaction.display.finished_waiting.expanded`
- `interaction.display.indentation.valid`
- `interaction.display.truncation.applied`

## Expected Filesystem Artifacts

- `.codex/multi-agent/session.json::json_key=execution_mode`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/tasks.json::json_array_non_empty=tasks`

## Must-Not-Happen Markers

- `interaction.display.expanded_before_collapsed`
- `interaction.display.indentation.depth_exceeded`
- `interaction.display.unbounded_field_value`
- `interaction.display.template_mismatch`

## Notes

This fixture targets rendering protocol correctness only. It does not validate decision quality or task planning quality.
