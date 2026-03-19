# Execution-Time Interaction Display Spec

## Scope

- MUST apply to lead-rendered execution events in both `parallel` and `serial` modes.
- MUST keep rendering summary-first: collapsed row first, expanded details on demand.

## Summary-First Model

- MUST emit exactly one collapsed line per event before any details.
- SHOULD auto-expand only for `blocker`, `error`, or explicit user request.
- MUST keep collapsed and expanded views semantically consistent.

## Indentation Contract

- Level 0 (event row): `0` leading spaces.
- Level 1 (primary fields): exactly `2` leading spaces.
- Level 2 (secondary fields): exactly `4` leading spaces.
- MUST NOT render levels deeper than `2`.

## Wrap and Truncation Defaults

- Default line width MUST be `100` characters.
- MUST soft-wrap on word boundaries when possible.
- MUST truncate any single field value past `140` chars to `...`.
- SHOULD keep collapsed output to one visual line by dropping lowest-priority fields first.

## Event Templates

### Sent input

Collapsed:

```text
[<ts>] Sent input -> <target> | <task_id> | <intent_or_topic> | <body_excerpt>
```

Expanded:

```text
[<ts>] Sent input
  target: <target>
  task_id: <task_id>
  intent: <intent>
  topic: <topic>
  body: <body>
```

### Finished waiting

Collapsed:

```text
[<ts>] Finished waiting -> <target> | <status> | <elapsed_ms>ms | <result_excerpt>
```

Expanded:

```text
[<ts>] Finished waiting
  target: <target>
  status: <completed|failed|timeout|cancelled>
  elapsed_ms: <int>
  result: <result_summary>
  next_action: <resume|relay|retry|stop>
```

## Minimal Field-Priority Mapping

Use first present field from left to right.

- `target`: `target`, `recipient`, `agent_id`
- `task_id`: `task_id`, `task`
- `intent_or_topic`: `intent`, `topic`, `type`
- `body`: `body`, `message`, `input`
- `status`: `status`, `outcome`
- `elapsed_ms`: `elapsed_ms`, `wait_ms`, `duration_ms`
- `result`: `result`, `summary`, `body`
- `next_action`: `next_action`, `action`

Collapsed overflow drop order:

- `Sent input`: `body_excerpt`, then `intent_or_topic`
- `Finished waiting`: `result_excerpt`, then `elapsed_ms`, then `next_action`
