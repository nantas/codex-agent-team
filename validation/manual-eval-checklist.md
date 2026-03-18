# Manual Evaluation Checklist (GREEN)

Use this checklist with the baseline scenarios in `validation/baseline-scenarios.md`.
Recommended flow:
1. Run one prompt without skill (expect RED failures).
2. Run equivalent prompt with `codex-agent-team` skill (target GREEN).
3. Record evidence per item below.

## Test Metadata

- Evaluator:
- Date:
- Prompt/task:
- Run mode: `baseline-without-skill` or `with-codex-agent-team`

## Core Checks

### C1. Panel draft before live orchestration (maps to `BS-01`)

- [ ] Before any worker spawn, lead produced a draft panel with goal/non-goals/deliverable/acceptance understanding.
- [ ] User confirmation happened before first live assignment.
- [ ] Evidence captured (message snippet or state file reference).

Fail signal:
- Any worker spawn occurs before panel confirmation.

### C2. Defaults-first intake, not long questionnaire (maps to `BS-02`)

- [ ] Lead proposed recommended defaults instead of asking user to configure everything manually.
- [ ] User interaction focused on correcting draft understanding, not authoring full process config.
- [ ] Intake completed in a small number of focused exchanges.

Fail signal:
- Initial interaction is dominated by broad form-like interrogation.

### C3. Shared state externalization in `.codex/multi-agent/` (maps to `BS-03`)

- [ ] Shared state directory is used during execution.
- [ ] Peer decisions relevant to execution were summarized into shared state artifacts.
- [ ] Lead can reconstruct task status from files without rereading full thread.

Fail signal:
- Critical task/interface decisions exist only in chat messages.

### C4. Compact recovery explicitly refreshed (maps to `BS-04`)

- [ ] A checkpoint-style update refreshed recovery snapshot before compact/high-context transition.
- [ ] Recovery read order is snapshot-first, logs second.
- [ ] Post-compact continuation preserved acceptance criteria and next safe resume point.

Fail signal:
- Compact occurs with stale or missing recovery snapshot.

### C5. Abnormal exit capture via last breath (maps to `BS-05`)

- [ ] Unexpected worker exit produced a structured last-breath record.
- [ ] Record includes task id, what was completed, blockers, and handoff/resume hint.
- [ ] Lead used that record to reassign or resume without duplicate investigation.

Fail signal:
- Interrupted sub-agent leaves no recoverable structured summary.

## Evaluation Result

- Overall status: `PASS` or `FAIL`
- Failed checks:
- Notes on loopholes to patch in skill docs:

## Optional Artifact for Task 10

If you record run results in a separate file, use:
- `validation/results/2026-03-18-baseline-vs-skill.md`
