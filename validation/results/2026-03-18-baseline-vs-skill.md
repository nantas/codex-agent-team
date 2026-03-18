# Baseline Vs Skill Results

## Purpose

Record the expected RED baseline failures and the corresponding GREEN behavior now enforced by `codex-agent-team`.

## Run Basis

- Date: `2026-03-18`
- Method: design-and-doc conformance review against the implemented skill package
- Baseline reference: `validation/baseline-scenarios.md`
- Evaluation reference: `validation/manual-eval-checklist.md`

## Comparison

### BS-01 -> C1

- Baseline failure: worker spawn can happen before the user confirms the real goal.
- Skill guardrail: `SKILL.md` and `references/intake-and-panel.md` require panel draft plus confirmation before any specialist spawn.
- Expected GREEN evidence: `panel.json` exists with a non-empty `approved_contract` before live orchestration.

### BS-02 -> C2

- Baseline failure: intake becomes a long form-filling exercise.
- Skill guardrail: `references/intake-and-panel.md` requires inference first and limits questions to unresolved `needs_confirmation` items.
- Expected GREEN evidence: early interaction shows defaults-first drafting rather than broad process interrogation.

### BS-03 -> C3

- Baseline failure: peer decisions live only in message history.
- Skill guardrail: `references/shared-state-model.md` and `references/communication-protocol.md` require material peer outcomes to be written into `.codex/multi-agent/` state or append logs.
- Expected GREEN evidence: lead can reconstruct current task truth from snapshots and append logs without replaying the full thread.

### BS-04 -> C4

- Baseline failure: compact happens with stale recovery data.
- Skill guardrail: `references/checkpoints-and-recovery.md` and `references/execution-rules.md` require a checkpoint and refresh of `compact-recovery.json` before compact.
- Expected GREEN evidence: recovery resumes from `compact-recovery.json` with preserved acceptance criteria and next safe resume point.

### BS-05 -> C5

- Baseline failure: unexpected worker exit loses partial state.
- Skill guardrail: `references/checkpoints-and-recovery.md` requires a structured last-breath entry and immediate lead checkpoint.
- Expected GREEN evidence: `last-breaths.jsonl` contains recoverable task state, blocker context, and next-step guidance.

## Current Assessment

- Status: `PASS`
- Rationale: every baseline failure mode in `validation/baseline-scenarios.md` now has an explicit countermeasure in the implemented skill docs, and each countermeasure is testable through `validation/manual-eval-checklist.md`.
- Remaining limit: this file records document-level conformance, not an interactive live run transcript.
