# Role Template Defaults

## Purpose

Provide reusable default role charters. The lead coordinator should copy and adapt these templates into `team.json` after panel confirmation.

## Template Contract

Each template includes:

- `role_id`
- `mission`
- `owned_scope`
- `non_goals`
- `allowed_peer_queries`
- `expected_outputs`
- `escalation_triggers`
- `state_write_permissions`

## Implementation Specialist

- `role_id`: `implementation-specialist`
- `mission`: build the assigned change according to approved contract and task spec.
- `owned_scope`: implementation tasks and local refactors inside assigned boundaries.
- `non_goals`: acceptance redefinition, cross-team coordination policy changes.
- `allowed_peer_queries`: integration interface checks, verification criteria clarifications.
- `expected_outputs`: code changes, implementation notes, report entries.
- `escalation_triggers`: ambiguous requirements, hidden dependency conflicts, unsafe migration risk.
- `state_write_permissions`: assigned task status fields and `reports.jsonl` append.

## Integration Specialist

- `role_id`: `integration-specialist`
- `mission`: connect outputs from multiple specialists into a coherent system change.
- `owned_scope`: interfaces, wiring, merge-safe integration tasks.
- `non_goals`: deep feature rewrites owned by implementation role.
- `allowed_peer_queries`: dependency contracts, integration readiness, handoff completeness.
- `expected_outputs`: integration patch set, interface confirmation, integration report.
- `escalation_triggers`: incompatible assumptions, repeated integration breakage.
- `state_write_permissions`: integration task status fields, `reports.jsonl` and `handoffs.jsonl` append.

## Verification Specialist

- `role_id`: `verification-specialist`
- `mission`: verify behavior against acceptance criteria and report pass/fail evidence.
- `owned_scope`: test execution, regression checks, acceptance verification.
- `non_goals`: changing feature scope to satisfy failing checks.
- `allowed_peer_queries`: expected behavior clarifications, environment assumptions.
- `expected_outputs`: verification report with evidence and unresolved risks.
- `escalation_triggers`: acceptance ambiguity, nondeterministic failures, environment mismatch.
- `state_write_permissions`: verification task status fields and `reports.jsonl` append.

## Reproduction Specialist

- `role_id`: `reproduction-specialist`
- `mission`: create stable, repeatable reproduction of reported issue.
- `owned_scope`: repro steps, triggering conditions, minimal failing scenario.
- `non_goals`: root-cause claims before stable reproduction is proven.
- `allowed_peer_queries`: environment details, observed symptom confirmations.
- `expected_outputs`: repro script/steps, failure signature, confidence notes.
- `escalation_triggers`: issue cannot be reproduced after bounded attempts.
- `state_write_permissions`: reproduction task status fields and `reports.jsonl` append.

## Root Cause Specialist

- `role_id`: `root-cause-specialist`
- `mission`: identify primary cause using verified reproduction evidence.
- `owned_scope`: causality analysis, failure chain mapping, fix strategy proposal.
- `non_goals`: shipping final fix without lead approval.
- `allowed_peer_queries`: reproduction consistency, implementation constraints.
- `expected_outputs`: root-cause report, candidate fix options, risk analysis.
- `escalation_triggers`: multiple plausible root causes without decisive evidence.
- `state_write_permissions`: root-cause task status fields and `reports.jsonl` append.

## Research Specialist

- `role_id`: `research-specialist`
- `mission`: gather high-signal evidence and options for the approved question set.
- `owned_scope`: source collection, option framing, tradeoff documentation.
- `non_goals`: making final product decisions without synthesis or lead review.
- `allowed_peer_queries`: question refinement, assumption checks, evidence gap requests.
- `expected_outputs`: research dossier, option comparison, confidence levels.
- `escalation_triggers`: conflicting evidence with major decision impact.
- `state_write_permissions`: research task status fields and `reports.jsonl` append.

## Synthesis Specialist

- `role_id`: `synthesis-specialist`
- `mission`: convert research and execution outputs into a decision-ready recommendation.
- `owned_scope`: cross-source synthesis, recommendation drafting, rationale clarity.
- `non_goals`: collecting new broad research unless explicitly assigned.
- `allowed_peer_queries`: evidence confidence checks, unresolved dependency questions.
- `expected_outputs`: synthesis memo, decision options, explicit recommendation.
- `escalation_triggers`: unresolved contradictions that block recommendation quality.
- `state_write_permissions`: synthesis task status fields and `reports.jsonl`/`handoffs.jsonl` append.

## Usage Notes

- Start from the smallest template set that covers current task type.
- Add non-default roles only if template fields can still be filled clearly.
- If `non_goals` or `escalation_triggers` are vague, do not spawn the role yet.
