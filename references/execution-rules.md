# Execution Rules

## Purpose

Define live orchestration discipline for the lead coordinator and specialists so execution stays aligned with approved contract, shared state, and compact-safe recovery.

## Live Orchestration Discipline

### User interaction discipline (all modes)

- Lead must be in `Default` mode with lead-side `request_user_input` available before execution begins.
- Clarification questions must be grouped by decision stage and use structured question ids.
- Stage-level question cap is `5`; per-call cap is `3`; split `4/5` as `3+2`.
- In `parallel`, subagents cannot collect user input directly and must route via lead relay.
- In `serial`, lead collects user answers directly and applies them to lead-owned tasks.
- Every clarification batch must be persisted in shared state before continuing work.

### When the lead may spawn specialists

Lead may spawn a specialist only when:

- panel confirmation is complete and `approved_contract` is persisted;
- role charter is written in `team.json`;
- at least one active task in `tasks.json` is assigned to the role;
- state write permissions are explicit.
- interaction preflight in `references/parallel-user-interaction.md` has passed.

### When the lead must wait

Lead must wait and avoid new spawn waves when:

- there are unresolved blockers that can invalidate current assignments;
- integration or verification evidence for the current wave is still pending;
- checkpoint is due but not yet executed.
- resource safety downgrade is active (for example `EMFILE` / `Too many open files` / `os error 24`).

## Resource Safety Rules

- Resource budget is mandatory before each spawn wave: persist max concurrent specialists and current open-agent count in shared state.
- After specialist completion, lead must run explicit cleanup via `close_agent` after ingesting outputs/handoffs.
- Treat `close_agent` as suspend-capable (context recoverable later), not as irreversible discard.
- Required suspend sequence:
  1. `wait_agent` until terminal or handoff-ready status.
  2. Write shared-state handoff + checkpoint (`tasks.json`, append logs, `checkpoints.json`, `compact-recovery.json`).
  3. `close_agent` for that specialist.
- Required resume sequence:
  1. `resume_agent` using recorded `agent_id`.
  2. Rehydrate context from checkpoint/handoff references in shared state.
  3. Continue via scoped `send_input`.
- `EMFILE` guardrail: if `EMFILE`, `Too many open files`, or `os error 24` appears, auto-downgrade execution to `serial`.
- During downgrade, stop new spawn waves until stable (no repeated FD errors in retry window and open-agent count below budget).
- Record downgrade trigger, mode switch, and stabilization evidence in checkpoint state before returning to parallel waves.

### When specialists may message peers

Specialists may message peers only for:

- clarification on dependency assumptions;
- contract/interface confirmation;
- dependency resolution needed to unblock their owned task.

Peer messages must use the communication protocol and be summarized back into shared state.

### When issues must escalate to lead

Specialists must escalate immediately when:

- acceptance criteria conflict with observed constraints;
- scope ambiguity blocks progress beyond bounded attempts;
- dependency owner does not respond within agreed reply mode/time;
- new risk could invalidate approved contract or timeline.

## Anti-Drift Rules

- `approved_contract` in `panel.json` is authoritative for goal, non-goals, and acceptance criteria.
- Acceptance criteria cannot be changed silently in thread conversation.
- Any acceptance change requires explicit lead update and checkpoint record.
- Specialists cannot redefine scope, success metrics, or non-goals.
- Peer agreement does not override lead decisions or approved contract.

## State Discipline

- Task truth must be kept in `.codex/multi-agent/` snapshots and append logs.
- Key peer outcomes must be reflected in `tasks.json` and/or `handoffs.jsonl`.
- Before phase transitions, lead must checkpoint and refresh `compact-recovery.json`.

## Compact Discipline

- Compact is allowed only after checkpoint-style state externalization is complete.
- Required before compact:
  - latest `tasks.json` and `checkpoints.json` committed to current truth.
  - fresh `compact-recovery.json` with next safe resume point.
  - unresolved blockers and owners explicitly listed.
- If compact risk rises and checkpoint is stale, pause execution and checkpoint first.

## Blocking and Recovery Discipline

- Blockers must include owner, dependency, attempted actions, and escalation deadline.
- After major blocker resolution, run a checkpoint before starting the next wave.
- Unexpected specialist exits trigger last-breath ingestion and immediate checkpoint.
