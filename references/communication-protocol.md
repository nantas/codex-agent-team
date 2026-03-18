# Communication Protocol

## Rationale

Codex collaboration messages do not reliably expose sender semantics as structured metadata to the model.
Therefore each message body must carry explicit source and intent fields.
This keeps coordination auditable, reduces context drift, and ensures decisions are written back to `shared state`.

## Allowed Message Types

Use only:

- `assign`
- `question`
- `answer`
- `status`
- `blocker`
- `handoff`

If a communication need does not fit these types, escalate to the lead and log the decision.

## Required Fields

Every message must include:

- `sender`
- `sender_role`
- `target`
- `task_id`
- `intent`
- `topic`
- `reply_mode`

Recommended envelope:

```text
type: <assign|question|answer|status|blocker|handoff>
sender: <agent-id>
sender_role: <role>
target: <agent-id|role|lead>
task_id: <task-id>
intent: <one-line intent>
topic: <short topic>
reply_mode: <sync|async|no-reply>
body: <compact payload>
```

## Short Reply Shapes

### `question`

```text
type: question
task_id: T7
intent: confirm API contract
topic: input schema
body: Need confirmation: is `approved_contract.acceptance_criteria` immutable after checkpoint cp-003?
```

### `status`

```text
type: status
task_id: T7
intent: progress update
topic: parser implementation
body: 70% complete; unit checks passing; no blocker.
```

### `blocker`

```text
type: blocker
task_id: T7
intent: escalate unresolved dependency
topic: missing interface owner
body: Cannot proceed without schema owner decision by checkpoint cp-004.
```

### `handoff`

```text
type: handoff
task_id: T7
intent: transfer validated output
topic: schema ready for integration
body: Deliverable committed to shared state; integration can start.
```

## Peer Communication Rules

Peer-to-peer messaging is limited to:

- clarification
- contract/interface confirmation
- dependency resolution

Rules:

- Keep peer messages task-scoped and concise.
- Do not renegotiate `approved_contract` through peer channels.
- Any peer decision affecting scope, acceptance criteria, or sequencing must be escalated to lead.
- Summarize material peer outcomes into `shared state` (`reports.jsonl` or `handoffs.jsonl`) before closing the thread.
