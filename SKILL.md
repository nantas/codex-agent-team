---
name: codex-agent-team
description: Use when the user explicitly wants a Codex-only multi-agent workflow for a complex task with a lead agent, specialist sub-agents, shared state, checkpoints, and compact-safe recovery.
---

# Codex Agent Team

Use this skill only when the user explicitly invokes a Codex-only multi-agent workflow.

## Hard Constraints

- Manual trigger only. Do not auto-trigger this workflow from intent inference.
- Draft and confirm a task panel before any live orchestration or worker spawn.
- Externalize workflow state under project-local `.codex/multi-agent/`.
- Treat the approved panel contract as authoritative until the user changes it.
- Refresh recovery state before any compact and after any recovery-relevant event.
- Keep `SKILL.md` short. Read the sidecar references for execution details instead of expanding the inline workflow here.

## Navigation

Read only the next file needed for the current phase:

1. `references/intake-and-panel.md`
2. `references/shared-state-model.md`
3. `references/team-formation.md`
4. `references/role-template-defaults.md`
5. `references/parallel-user-interaction.md` (applies to both `parallel` and `serial`)
6. `references/communication-protocol.md`
7. `references/checkpoints-and-recovery.md`
8. `references/execution-rules.md`

## Workflow

1. Extract the task from the user's request and draft `panel.json` with recommended defaults.
2. Ask the user to correct only the important items and promote approved values into the contract.
3. Initialize `.codex/multi-agent/` and write the first shared-state snapshots.
4. Form only the specialists required by the approved contract and assign scoped work.
5. Keep coordination messages narrow, summarize important outcomes back into shared state, and checkpoint before compact risk accumulates.
6. Recover from compact or agent failure by reading the recovery snapshot first, then the broader state files only as needed.
