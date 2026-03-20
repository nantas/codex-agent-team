# Fixture Schema (V1)

This document defines the machine-readable markdown contract for scenario fixtures used by the V1 harness.

## Required Sections

Each fixture README must include these headings in this exact order:

## Fixture ID
## Scenario Intent
## Prompt/Input Shape
## Expected Phase Markers
## Expected Filesystem Artifacts
## Must-Not-Happen Markers
## Notes

## Parsing Rules

- `Fixture ID` must be a single backticked identifier matching the fixture directory name.
- `Prompt/Input Shape` must be a fenced `yaml` block.
- `Expected Phase Markers` must be a flat bullet list of backticked marker tokens.
- `Expected Filesystem Artifacts` must be a flat bullet list of backticked relative paths or path-plus-condition tokens.
- `Must-Not-Happen Markers` must be a flat bullet list of backticked marker tokens.
- `Notes` is free text and may include implementation assumptions.

## Marker Conventions

Use dot-delimited marker names. Recommended families:

- `panel.*`
- `team.*`
- `tasks.*`
- `checkpoint.*`
- `recovery.*`
- `execution.*`
- `delivery.*`
- `closure.*`

Markers represent normalized evidence extracted from session logs and/or artifact summaries. They are assertion targets, not required source log strings.

## Artifact Conventions

- Paths are repository-relative workflow artifacts under `.codex/multi-agent/` (including `deliverables/` subdirectories).
- Final handoff package artifacts may live under `.codex/multi-agent/deliverables/<topic>-<YYYYMMDD>-<session_id>/`.
- Path-plus-condition tokens are allowed using `::` separator.
- Condition grammar is intentionally simple and string-based for V1:
  - `path::json_key=<key>`
  - `path::json_non_empty=<key>`
  - `path::json_array_non_empty=<key>`
  - `path::jsonl_non_empty=true`

Examples:

- `.codex/multi-agent/panel.json::json_non_empty=approved_contract`
- `.codex/multi-agent/checkpoints.json::json_array_non_empty=checkpoints`
- `.codex/multi-agent/reports.jsonl::jsonl_non_empty=true`

## V1 Scope Limits

- Fixtures validate workflow correctness only.
- Fixtures do not score output intelligence quality.
- Fixtures do not attempt exhaustive failure-chaos matrices.
