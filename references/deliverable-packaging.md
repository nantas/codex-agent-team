# Deliverable Packaging

## Purpose

Define how final handoff artifacts are packaged so users can clearly identify deliverables instead of reading raw runtime evidence.

## Runtime Evidence vs Final Deliverables

- `.codex/multi-agent/artifacts/` remains the shared runtime evidence pool.
- `.codex/multi-agent/deliverables/` is the final handoff surface for user-facing outputs.
- Lead must not present runtime artifacts as final delivery without packaging.

## Final Deliverable Directory Contract

Lead must package final outputs under:

```text
.codex/multi-agent/deliverables/<topic>-<YYYYMMDD>-<session_id>/
```

Directory name must be deterministic and scoped to one workflow run.

## Mandatory Files

Each deliverable directory must include:

- `DELIVERABLE_INDEX.md` (single entry document for users and follow-up agents)
- `delivery-manifest.json` (packaged file inventory and source mapping)
- `closure-summary.json` (closure state and objective attainment summary)

## `DELIVERABLE_INDEX.md` Required Sections

Entry document must include all sections below:

1. objective and scope
2. macro synthesis (not only issue-by-issue notes)
3. acceptance criteria attainment matrix (`met | partial | unmet`)
4. key risks and unresolved items
5. artifact index with links
6. next-step recommendation
7. run metadata (`session_id`, `checkpoint_id`, generation time, owner)

## Link Policy

- Links from `DELIVERABLE_INDEX.md` to sidecar outputs must use relative markdown paths.
- Absolute filesystem paths, URI-style local paths, and environment-specific links are forbidden.
- Link integrity must be validated before declaring `workflow_closed`.

## Packaging Gate

Before `closure_review`, lead must verify:

- deliverable directory exists;
- mandatory files exist and are non-empty;
- entry links are relative and resolvable;
- packaged outputs are reflected in shared-state closure metadata.
