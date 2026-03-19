# Shared State Model

## Purpose

This document defines the first-version `shared state` layout and write discipline under:

```text
.codex/multi-agent/
```

The design is snapshot-plus-log: small authoritative JSON snapshots plus append-only operational logs.

## Required Layout

- `session.json`
- `panel.json`
- `team.json`
- `tasks.json`
- `checkpoints.json`
- `reports.jsonl`
- `handoffs.jsonl`
- `last-breaths.jsonl`
- `compact-recovery.json`

## Ownership Rules

Lead-owned authoritative snapshots:

- `session.json`
- `panel.json`
- `team.json`
- `tasks.json`
- `checkpoints.json`
- `compact-recovery.json`

Specialist-writable surfaces:

- Append to `reports.jsonl` for progress/observations tied to `task_id`.
- Append to `handoffs.jsonl` for explicit task transfer and dependency output.
- Append to `last-breaths.jsonl` when interrupted, failing, or exiting unexpectedly.

Specialists must not directly overwrite lead-owned snapshots.
If specialist work changes contract truth, the lead applies updates during a `checkpoint`.

## Update Triggers

- `session.json`: initialize at session start; update on mode/phase transitions and user-interaction stage transitions.
- `panel.json`: write draft at intake; rewrite when `approved_contract` changes.
- `team.json`: refresh after team formation or role roster changes.
- `tasks.json`: refresh after assignment wave, status transitions, blocker resolution, or acceptance updates.
- `checkpoints.json`: append at every mandatory `checkpoint`.
- `reports.jsonl`: append on specialist status emission and key observations.
- `handoffs.jsonl`: append on dependency handoff or completed sub-scope transfer.
- `last-breaths.jsonl`: append immediately on abnormal agent exit/interruption.
- `compact-recovery.json`: refresh at each `checkpoint`, before likely compact, and before integration/acceptance review.

## Interaction State Keys

For every active clarification stage, lead-owned snapshots must include:

- `execution_mode`: `parallel | serial`
- `awaiting_user_reply`: `true | false`
- `awaiting_mode`: `interactive_ask | message_ask`
- `question_stage_id`
- `question_batch_index`
- `question_ids`
- `reply_route` (question id to task/owner mapping)
- `last_sync_turn_id`

Canonical behavior and constraints are defined in:

- `references/parallel-user-interaction.md`

## Minimal JSON Examples

### `panel.json`

```json
{
  "task_understanding": {
    "goal": "Ship codex-agent-team skill package",
    "deliverable": "SKILL.md and sidecar references"
  },
  "recommended_defaults": {
    "phase_strategy": "panel-first"
  },
  "needs_confirmation": [
    "acceptance_criteria"
  ],
  "approved_contract": {
    "acceptance_criteria": [
      "panel before orchestration",
      "compact recovery maintained"
    ]
  }
}
```

### `tasks.json`

```json
{
  "tasks": [
    {
      "task_id": "T4",
      "owner_role": "implementation",
      "status": "in_progress",
      "depends_on": []
    },
    {
      "task_id": "T5",
      "owner_role": "verification",
      "status": "pending",
      "depends_on": ["T4"]
    }
  ]
}
```

### `compact-recovery.json`

```json
{
  "checkpoint_id": "cp-004",
  "approved_contract_digest": "goal fixed, acceptance fixed, scope unchanged",
  "active_tasks": ["T4"],
  "open_blockers": [],
  "awaiting_user_reply": false,
  "next_safe_resume_point": "assign integration review after T4 complete"
}
```
