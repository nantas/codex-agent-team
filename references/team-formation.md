# Team Formation

## Purpose

Define how the lead coordinator forms a right-sized specialist team from the approved contract in `panel.json` and the current task graph in `tasks.json`.

## Team Skeleton

- Only one role is fixed: `lead-coordinator`.
- All specialist roles are derived from:
  - `approved_contract.task_type`
  - `approved_contract.acceptance_criteria`
  - current blockers, dependencies, and risk concentration in `tasks.json`
- Never spawn a specialist without a written role charter.

## Formation Inputs

Before creating specialists, the lead must confirm:

- `approved_contract` exists and is current.
- initial task decomposition exists in `tasks.json`.
- non-goals are explicit enough to prevent scope drift.
- ownership boundaries are clear enough to assign by role.

If any input is missing, pause team formation and repair `panel.json` or `tasks.json` first.

## Role Generation By Task Type

### Implementation-heavy

- Default specialists: `implementation`, `integration`, `verification`.
- Add temporary specialists only for high-risk interfaces or migrations.

### Debugging

- Default specialists: `reproduction`, `root-cause`, `implementation`, `verification`.
- Keep `reproduction` independent from `root-cause` until the repro is stable.

### Research

- Default specialists: `research`, `synthesis`.
- Add `verification` only if conclusions must be tested in code.

## Required Role Charter Fields

Every specialist role must include all fields below. If one is missing, the role is invalid and must not be spawned.

- `role_id`: unique identifier used in messages and task ownership.
- `mission`: single-sentence objective tied to acceptance criteria.
- `owned_scope`: explicit ownership boundary (files, subsystem, or question space).
- `non_goals`: out-of-scope items the role must not touch.
- `allowed_peer_queries`: what this role may ask other specialists.
- `expected_outputs`: concrete artifacts or decisions expected.
- `escalation_triggers`: conditions that require lead intervention.
- `state_write_permissions`: exact writable surfaces under `.codex/multi-agent/`.

## Permission Baseline

- Lead owns authoritative snapshots: `session.json`, `panel.json`, `team.json`, `tasks.json`, `checkpoints.json`, `compact-recovery.json`.
- Specialists may:
  - update fields in their own assigned task records (if allowed by lead policy).
  - append execution evidence to append-only streams (`reports.jsonl`, `handoffs.jsonl`, `last-breaths.jsonl`).
- Specialists must not rewrite the approved contract or acceptance criteria.

## Spawn Rules

Lead may spawn a specialist only when all are true:

- charter is written and persisted in `team.json`;
- at least one task in `tasks.json` maps to that charter;
- expected outputs are measurable against acceptance criteria.

Lead should avoid speculative specialist creation. Prefer small first wave, then expand after checkpoint evidence.

## Decommission Rules

Lead should retire a specialist when:

- its owned tasks are complete and handed off;
- blockers are resolved and no new dependent tasks are expected;
- its role no longer maps to active acceptance criteria.

On retire, require a final handoff or last-breath style summary in append logs.
