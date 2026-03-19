# Checkpoints And Recovery

## Purpose

Reduce compact damage and agent-exit regressions by forcing regular state externalization and deterministic recovery.

## Mandatory Checkpoint Triggers

The lead coordinator must run a checkpoint at each trigger below.

### Stage-boundary triggers

- after panel confirmation
- after team formation
- after first task wave assignment
- before integration
- before acceptance review
- before final wrap-up

### Condition-based triggers

- after major blocker resolution
- when context has grown heavy
- when compact is likely
- immediately before invoking compact
- when user updates scope or constraints
- when any agent exits unexpectedly

## Required Checkpoint Actions

Each checkpoint must perform all actions:

1. Settle current facts: what is done, in progress, blocked, and deferred.
2. Refresh shared snapshots: update `tasks.json`, `team.json` (if changed), and `checkpoints.json`.
3. Capture critical decisions: record accepted/rejected options and rationale in the checkpoint entry.
4. Refresh interaction state: persist whether user reply is pending and which question batch is active.
5. Refresh compact state: overwrite `compact-recovery.json` with minimal fresh resume payload.
6. Declare next safe resume point: define the immediate next step and owner.

If any step is skipped, checkpoint is incomplete and compact should not proceed.

## Recovery Read Order

When resuming after compact, interruption, or coordinator handoff, read in this order:

1. `compact-recovery.json`
2. `session.json`
3. `tasks.json`
4. `checkpoints.json`
5. append logs only if needed:
   - `reports.jsonl`
   - `handoffs.jsonl`
   - `last-breaths.jsonl`

Rule: snapshots first, logs second. Do not reconstruct the full timeline unless snapshots are insufficient.

## Compact Recovery Payload Contract

`compact-recovery.json` should remain short and include only resume-critical fields:

- `session_id`
- `approved_goal`
- `active_acceptance_criteria`
- `current_phase`
- `open_blockers`
- `next_actions` (owner + task id + action)
- `last_checkpoint_id`
- `resume_risks`

Do not include long narrative history.

## Last-Breath Contract

If a specialist exits due to error, timeout, or forced stop, append one structured object to `last-breaths.jsonl` with:

- `timestamp`
- `agent_id`
- `role_id`
- `task_id`
- `exit_reason`
- `last_known_state`
- `attempted_actions`
- `artifacts_or_paths`
- `open_risks`
- `recommended_next_step`
- `escalation_needed` (boolean)

Lead action on last-breath:

1. ingest the entry;
2. checkpoint immediately;
3. decide recover path: reassign, retry, or scope adjust;
4. record decision in `checkpoints.json`.

## Failure Guardrails

- Never run compact without a fresh checkpoint and recovery snapshot.
- Never close a blocked task without either resolution evidence or explicit defer decision.
- Never ignore an unexpected agent exit; treat it as mandatory recovery work.
