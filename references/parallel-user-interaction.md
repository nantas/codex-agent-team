# User Interaction Protocol (Parallel + Serial)

## Purpose

Define the user-interaction protocol for `codex-agent-team` execution.
This protocol is written for agents running inside this repository and is mandatory when the skill is active.

## Scope

Applies to all modes:

- `parallel`: lead plus specialist subagents
- `serial`: lead-only execution without subagent delegation
- all user-facing clarification and confirmation turns

Does not apply to non-interactive batch/exec runs.

## Hard Preconditions

Before starting execution, the lead must pass all checks below:

1. collaboration mode is `Default` (the lead needs write-capable execution).
2. `request_user_input` is available to the lead.
3. config enables Default-mode interactive prompts:
   - `[features].default_mode_request_user_input = true`
   - or `[profiles.<name>.features].default_mode_request_user_input = true` for active profile.

If any check fails, stop immediately with a fail-fast message and do not continue.

## Interaction Boundary Rules

- Lead is the only agent allowed to collect user answers.
- In `parallel`, users do not interact with subagents directly.
- In `parallel`, subagents do not call `request_user_input`.
- In `parallel`, subagents may only send `message_ask` to the lead.
- In `parallel`, if user requests direct subagent conversation, lead must refuse and route through lead relay.
- In `serial`, the active lead handles user clarification directly and no relay is needed.

## Two Ask Modes

### `message_ask` (subagent -> lead, parallel only)

Used by subagents to request clarification from the lead.

Required behavior:

- one short message only
- one decision topic only
- include `task_id` and intended recipient context
- stop after sending (no continued analysis stream)

### `interactive_ask` (lead -> user, all modes)

Implemented with lead-side `request_user_input`.

Required behavior:

- questions are grouped by one decision stage
- each question has stable `id`
- options are mutually exclusive and concise
- answer collection is structured and mappable back to task owners

## Question Batching Policy

To balance UX and context efficiency:

- maximum questions per confirmation stage: `5` (all batches combined)
- maximum questions per single `request_user_input` call: `3`
- if stage size is `4` or `5`, split automatically as `3+2`

### Merge Criteria

Merge only if questions belong to the same decision stage, for example:

- task decomposition confirmation
- role assignment confirmation
- acceptance-gate confirmation

Do not merge across different decision domains in one batch.

## Relay and Routing Policy

After receiving user answers in `parallel`:

1. map each `question_id` to `(task_id, owner_agent_id or owner_role)`.
2. send only relevant answer slices to each target subagent.
3. include minimal context delta, not full prompt history.
4. update shared state with routing evidence.

Do not send one large combined narrative to all workers.

After receiving user answers in `serial`:

1. apply answers directly to current lead-owned task decisions.
2. persist structured answer map into shared state.
3. continue execution without relay.

## Shared-State Requirements

During an active clarification stage, lead must keep:

- `awaiting_user_reply: true|false`
- `execution_mode: parallel | serial`
- `awaiting_mode: interactive_ask | message_ask`
- `question_stage_id`
- `question_batch_index`
- `question_ids`
- `reply_route` (question id -> task/owner)
- `last_sync_turn_id`

These fields must be refreshed after each batch (`3` then `2` when applicable).
When `execution_mode = serial`, `reply_route` may point to lead-owned task ids only.

## Fail-Fast and Refusal Templates

### Missing lead capability

`This workflow requires lead-side request_user_input in Default mode. Enable features.default_mode_request_user_input, then retry.`

### User asks to talk to subagent directly

`Direct user<->subagent interaction is outside this workflow contract. I will relay your answers to the target subagent through the lead channel.`

## Execution Checklist

Before first execution wave:

- preflight passed
- interaction boundary announced
- shared-state interaction fields initialized

For each clarification stage:

- stage question set collected
- batched with `<=3` per call
- user answers collected
- per-owner routing sent (`parallel`) or direct task update applied (`serial`)
- shared state updated
- checkpoint refreshed if stage materially changes task flow
