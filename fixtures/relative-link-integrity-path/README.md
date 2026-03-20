# Relative Link Integrity Path

## Fixture ID

`relative-link-integrity-path`

## Scenario Intent

Validate that the final entry document references sidecar deliverables using relative Markdown links only and that each target exists.

## Prompt/Input Shape

```yaml
mode: with-codex-agent-team
user_request: |
  Package final deliverables and build an entry index.
  Link every sidecar document via relative markdown paths only.
operator_overrides:
  link_policy: relative-markdown-links-only
expected_checks:
  - links_are_relative
  - link_targets_exist
```

## Expected Phase Markers

- `delivery.entry.index_generated`
- `delivery.links.relative_enforced`
- `delivery.links.integrity_checked`

## Expected Filesystem Artifacts

- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links/DELIVERABLE_INDEX.md`
- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links/issue-01.md`
- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links/issue-02.md`
- `.codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links/delivery-manifest.json::json_array_non_empty=files`

## Must-Not-Happen Markers

- `delivery.links.absolute_path_detected`
- `delivery.links.broken_reference`

## Notes

The assertion layer checks markdown link style and target resolvability under the same deliverables directory.
