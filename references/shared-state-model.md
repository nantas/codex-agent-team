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

- `session.json`: initialize at session start; update on mode/phase transitions, closure transitions, delivery packaging completion, and user-interaction stage transitions.
- `panel.json`: write draft at intake; rewrite when `approved_contract` changes (including `delivery_contract`).
- `team.json`: refresh after team formation or role roster changes.
- `tasks.json`: refresh after assignment wave, status transitions, blocker resolution, or acceptance updates.
- `checkpoints.json`: append at every mandatory `checkpoint`.
- `reports.jsonl`: append on specialist status emission and key observations.
- `handoffs.jsonl`: append on dependency handoff or completed sub-scope transfer.
- `last-breaths.jsonl`: append immediately on abnormal agent exit/interruption.
- `compact-recovery.json`: refresh at each `checkpoint`, before likely compact, before integration/acceptance review, and after any closure-gate transition.

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

## Closure State Keys

For deterministic final-wrap-up and explicit workflow completion signaling:

- `session.json` MUST include:
  - `workflow_status`: `active | closing | closed`
  - `final_notice_sent`: `true | false`
  - `delivery_root`: finalized deliverable package path under `.codex/multi-agent/deliverables/`
  - `closed_at`: UTC timestamp when workflow reaches `closed`
- `panel.json.approved_contract` SHOULD include `delivery_contract` so output structure is approved before orchestration.
- `compact-recovery.json` MUST carry closure-resume-critical fields:
  - `current_phase`
  - `workflow_status`
  - `final_notice_sent`
  - `delivery_root`
  - `last_checkpoint_id`
  - `next_actions`
  - `resume_risks`

Canonical behavior and constraints are defined in:

- `references/parallel-user-interaction.md`

## Minimal JSON Examples

### `session.json`

```json
{
  "session_id": "sess-001",
  "current_phase": "closure_review",
  "execution_mode": "parallel",
  "workflow_status": "closing",
  "final_notice_sent": false,
  "delivery_root": ".codex/multi-agent/deliverables/harness-baseline-20260320-sess-001",
  "closed_at": null
}
```

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
    ],
    "delivery_contract": {
      "root": ".codex/multi-agent/deliverables/<topic>-<YYYYMMDD>-<session_id>",
      "entry_doc": "DELIVERABLE_INDEX.md",
      "link_policy": "relative_markdown_only"
    }
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
  "session_id": "sess-001",
  "current_phase": "user_final_notice",
  "workflow_status": "closing",
  "final_notice_sent": false,
  "delivery_root": ".codex/multi-agent/deliverables/harness-baseline-20260320-sess-001",
  "open_blockers": [],
  "next_actions": [
    {
      "owner": "lead-coordinator",
      "task_id": "CLOSE-1",
      "action": "send final user notice and mark workflow closed"
    }
  ],
  "last_checkpoint_id": "cp-closure-003",
  "resume_risks": [
    "closure gate can drift if final notice is not persisted"
  ]
}
```
