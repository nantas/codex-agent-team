# Deliverable Packaging Path

## Fixture ID

`deliverable-packaging-path`

## Scenario Intent

Validate that final workflow outputs are packaged into a themed deliverables directory with a clear entry document and required machine-readable sidecar files.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Complete synthesis and package final deliverables.
  Keep runtime evidence in artifacts and produce a final handoff package.
operator_overrides:
  require_delivery_package: true
  require_entry_doc: true
expected_outputs:
  - deliverables_root
  - entry_doc
  - delivery_manifest
  - closure_summary
```

## Expected Phase Markers

- `delivery.packaging.started`
- `delivery.packaging.completed`
- `delivery.entry.index_generated`
- `delivery.manifest.generated`
- `closure.summary.generated`

## Expected Filesystem Artifacts

- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable/DELIVERABLE_INDEX.md`
- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable/delivery-manifest.json::json_array_non_empty=files`
- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable/closure-summary.json::json_non_empty=objective_attainment`
- `.codex/multi-agent/session.json::json_non_empty=delivery_root`

## Must-Not-Happen Markers

- `delivery.packaging.skipped`
- `delivery.entry.missing`
- `delivery.manifest.missing`

## Notes

This fixture focuses on packaging semantics, not quality scoring of synthesis content.
