# Baseline Failure Scenarios (RED)

This document defines expected failure behavior **before** using `codex-agent-team`.
Use these as RED baselines, then compare against the checklist in `validation/manual-eval-checklist.md`.

## Scope

- Date: `2026-03-18`
- Target workflow: Codex-only multi-agent orchestration for complex tasks
- Baseline condition: no `codex-agent-team` skill guidance applied

## Scenario BS-01: Worker spawn before goal clarification

**Pressure case**
- Lead starts spawning specialists before extracting and confirming user goal/non-goals.

**Observable bad outcome**
- Workers produce outputs that conflict on objective or acceptance criteria.
- User receives rework questions late, after work already started.
- At least one task is discarded or rewritten due to initial goal mismatch.

## Scenario BS-02: Upfront over-configuration

**Pressure case**
- System asks the user to fill a large configuration form instead of proposing inferred defaults.

**Observable bad outcome**
- User spends excessive turns defining process metadata rather than validating task intent.
- Early interaction stalls before execution starts.
- Important variables still remain ambiguous despite long intake.

## Scenario BS-03: Peer exchange not externalized to shared state

**Pressure case**
- Specialists exchange decisions in-thread but do not summarize back to repository-local shared state.

**Observable bad outcome**
- Lead cannot reconstruct decision history from state files alone.
- Integration is delayed by repeated clarification requests.
- Thread history becomes the only source of truth for dependencies.

## Scenario BS-04: Compact without recovery snapshot refresh

**Pressure case**
- Compact occurs while current facts, decisions, and resume point are not refreshed in recovery snapshot.

**Observable bad outcome**
- Post-compact agent restarts with missing constraints or wrong priorities.
- Acceptance criteria drift between pre-compact and post-compact behavior.
- Work is repeated because prior progress is not recoverable from snapshot-first reads.

## Scenario BS-05: Sub-agent exits without last-breath capture

**Pressure case**
- A worker exits unexpectedly (error/timeout/interruption) with no structured exit summary.

**Observable bad outcome**
- Partial work status and unresolved blockers are lost.
- Replacement worker duplicates investigation already done.
- Lead cannot determine safe resume point for the interrupted task.

## Scenario BS-06: User interaction channel drift

**Pressure case**
- Clarifications are asked through mixed channels (direct subagent chat, oversized relay summaries, unbatched ad-hoc prompts).

**Observable bad outcome**
- User must answer unrelated questions in one large message.
- Clarification routing is ambiguous and workers receive extra irrelevant context.
- Interaction state cannot be reconstructed from shared state fields.

## Pass/Fail Signal for Baseline Runs

For baseline RED validation, each scenario is considered reproduced if at least one listed observable outcome appears.
GREEN target (with skill) is defined by the corresponding checks in `validation/manual-eval-checklist.md`.
