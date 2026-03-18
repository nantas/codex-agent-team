# Intake And Panel

## Purpose

This document defines the pre-orchestration contract for `panel` drafting and user confirmation.
The lead agent must finish this phase before any specialist spawn.

## Extraction-First Intake

Do not start with a long questionnaire.
The lead agent must first infer the following from the user request:

- `goal`
- `non_goals`
- `deliverable`
- `acceptance_criteria`
- `constraints`
- `likely_roles`

Follow-up questions are allowed only for items that remain blocking or high-risk after inference.
Questions should be scoped to unresolved fields in `needs_confirmation`.

## `panel.json` Contract

Write `panel.json` under `.codex/multi-agent/` with exactly these top-level sections:

- `task_understanding`
- `recommended_defaults`
- `needs_confirmation`
- `approved_contract`

### Field Intent

- `task_understanding`: machine-readable summary of inferred task truth.
- `recommended_defaults`: agent-proposed defaults for strategy, role shape, and execution policy.
- `needs_confirmation`: minimum set of contract points requiring user approval or correction.
- `approved_contract`: authoritative values after user confirmation; this is the execution source of truth.

## User Confirmation Behavior

The user corrects the draft; the user does not author workflow config from scratch.

Rules:

- Present concise draft understanding and defaults first.
- Ask for correction only on fields in `needs_confirmation`.
- If user replies with simple approval, promote `recommended_defaults` into `approved_contract`.
- If user edits scope or acceptance criteria, rewrite `approved_contract` and mark a `checkpoint` before orchestration.
- Do not spawn specialists until `approved_contract` is present and non-empty.

## Compact Example

### Input Prompt

```text
Build a Codex multi-agent workflow skill for complex tasks. Keep it reusable and reduce compact regressions.
```

### Inferred `panel.json` Draft (trimmed)

```json
{
  "task_understanding": {
    "goal": "Create a reusable Codex-only multi-agent workflow skill",
    "non_goals": [
      "runtime-agnostic abstraction layer",
      "auto-trigger by intent classifier"
    ],
    "deliverable": "Root SKILL.md plus sidecar reference docs",
    "acceptance_criteria": [
      "panel before orchestration",
      "shared state under .codex/",
      "compact recovery guidance"
    ]
  },
  "recommended_defaults": {
    "phase_strategy": "intake -> panel -> confirmation -> orchestration -> checkpoints",
    "likely_roles": ["lead", "implementation", "integration", "verification"]
  },
  "needs_confirmation": [
    "acceptance_criteria",
    "likely_roles"
  ],
  "approved_contract": {}
}
```

### Confirmation Interaction Shape

```text
Lead: I inferred your goal/non-goals and drafted defaults. Please confirm or edit:
1) acceptance criteria
2) role set

User: Approved. Keep verification role mandatory.

Lead: Applied. `approved_contract` finalized with mandatory verification role.
```
