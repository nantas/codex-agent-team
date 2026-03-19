#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: tests/run-fixture.sh <fixture-name>" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

fixture="$1"
repo_root="$(pwd)"
fixture_dir="$repo_root/fixtures/$fixture"

if [[ ! -d "$fixture_dir" ]]; then
  echo "Unknown fixture: $fixture" >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
run_id="${timestamp}-$$"
run_dir="$repo_root/tests/out/$fixture/$run_id"
state_dir="$run_dir/workspace/.codex/multi-agent"
session_dir="$run_dir/session"

mkdir -p "$state_dir" "$session_dir"

cat >"$run_dir/run-metadata.json" <<EOF
{
  "fixture": "$fixture",
  "run_id": "$run_id",
  "created_at": "$timestamp",
  "repo_root": "$repo_root",
  "fixture_readme": "fixtures/$fixture/README.md",
  "driver_mode": "v1-deterministic-harness"
}
EOF

execution_mode="parallel"
awaiting_user_reply="false"
awaiting_mode="interactive_ask"
question_stage_id="stage-default"
question_batch_index="1"
question_ids='["q-default-1"]'
reply_route='{"q-default-1":{"task_id":"T1","owner_role":"implementation"}}'
last_sync_turn_id="turn-default-001"
declare -a rendered_event_lines=()

case "$fixture" in
  basic-happy-path)
    panel_roles='["lead", "implementation", "verification"]'
    team_roles='["lead", "implementation", "verification"]'
    task_owner_1="implementation"
    task_owner_2="verification"
    markers=(
      "interaction.preflight.started"
      "interaction.preflight.config_checked"
      "interaction.preflight.passed"
      "interaction.boundary.announced"
      "panel.drafted"
      "panel.confirmed"
      "interaction.stage.collected"
      "interaction.batch.1.sent"
      "interaction.batch.1.received"
      "interaction.routing.applied"
      "interaction-state-persisted"
      "execution.orchestration_started"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "recovery.snapshot_refreshed"
      "panel-confirmed"
      "team-formed"
    )
    question_stage_id="stage-panel-confirmation"
    question_ids='["q-panel-confirm-goal"]'
    reply_route='{"q-panel-confirm-goal":{"task_id":"T1","owner_role":"implementation"}}'
    last_sync_turn_id="turn-basic-001"
    reports_lines=(
      '{"task_id":"T1","role_id":"implementation","status":"in_progress","summary":"Implemented baseline workflow artifacts."}'
      '{"task_id":"T2","role_id":"verification","status":"pending","summary":"Verification queued after implementation handoff."}'
    )
    handoffs_lines=(
      '{"from_role":"implementation","to_role":"verification","task_id":"T1","summary":"Baseline artifacts ready for review."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-001",
        "phase": "after_panel_confirmation",
        "decisions": ["approved default role set"],
        "next_step": "form team"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-basic-happy-path",
      "approved_goal": "Run the baseline codex-agent-team fixture",
      "active_acceptance_criteria": ["panel before orchestration", "checkpoint before finish"],
      "current_phase": "verification_pending",
      "open_blockers": [],
      "next_actions": [{"owner":"verification","task_id":"T2","action":"review baseline artifacts"}],
      "last_checkpoint_id": "cp-001",
      "resume_risks": []
    }'
    ;;
  role-override-path)
    panel_roles='["lead", "planner", "implementer", "verifier"]'
    team_roles='["lead", "planner", "implementer", "verifier"]'
    task_owner_1="planner"
    task_owner_2="implementer"
    markers=(
      "interaction.preflight.started"
      "interaction.preflight.config_checked"
      "interaction.preflight.passed"
      "interaction.boundary.announced"
      "panel.drafted"
      "panel.confirmed"
      "interaction.stage.collected"
      "interaction.batch.1.sent"
      "interaction.batch.1.received"
      "interaction.routing.applied"
      "interaction-state-persisted"
      "panel.override_roles_received"
      "panel.override_roles_applied"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "role-override-confirmed"
      "role-override-applied"
    )
    question_stage_id="stage-role-override"
    question_ids='["q-role-set"]'
    reply_route='{"q-role-set":{"task_id":"T1","owner_role":"planner"}}'
    last_sync_turn_id="turn-override-001"
    reports_lines=(
      '{"task_id":"T1","role_id":"planner","status":"done","summary":"Planned work using override roles."}'
      '{"task_id":"T2","role_id":"implementer","status":"in_progress","summary":"Implementation assigned to override role."}'
    )
    handoffs_lines=(
      '{"from_role":"planner","to_role":"implementer","task_id":"T1","summary":"Plan handed off under approved role override."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-override-001",
        "phase": "after_panel_confirmation",
        "decisions": ["accepted user role overrides"],
        "next_step": "assign tasks to override roles"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-role-override-path",
      "approved_goal": "Validate role override fidelity",
      "active_acceptance_criteria": ["override roles persist into team and tasks"],
      "current_phase": "task_execution",
      "open_blockers": [],
      "next_actions": [{"owner":"verifier","task_id":"T3","action":"confirm override role persistence"}],
      "last_checkpoint_id": "cp-override-001",
      "resume_risks": []
    }'
    ;;
  checkpoint-path)
    panel_roles='["lead", "implementation", "integration", "verification"]'
    team_roles='["lead", "implementation", "integration", "verification"]'
    task_owner_1="implementation"
    task_owner_2="integration"
    markers=(
      "interaction.preflight.started"
      "interaction.preflight.config_checked"
      "interaction.preflight.passed"
      "interaction.boundary.announced"
      "panel.confirmed"
      "interaction.stage.collected"
      "interaction.batch.1.sent"
      "interaction.batch.1.received"
      "interaction.routing.applied"
      "interaction-state-persisted"
      "team.formed"
      "tasks.assigned"
      "checkpoint.after_panel_confirmation"
      "checkpoint.before_integration"
      "execution.integration_started"
      "checkpoint.recorded"
      "checkpoint-triggered"
      "checkpoint-persisted"
    )
    question_stage_id="stage-integration-gate"
    question_ids='["q-integration-readiness"]'
    reply_route='{"q-integration-readiness":{"task_id":"T2","owner_role":"integration"}}'
    last_sync_turn_id="turn-checkpoint-001"
    reports_lines=(
      '{"task_id":"T1","role_id":"implementation","status":"done","summary":"Implementation complete before integration boundary."}'
      '{"task_id":"T2","role_id":"integration","status":"in_progress","summary":"Integration started after checkpoint."}'
    )
    handoffs_lines=(
      '{"from_role":"implementation","to_role":"integration","task_id":"T1","summary":"Ready for integration after checkpoint."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-checkpoint-001",
        "phase": "after_panel_confirmation",
        "decisions": ["team charter approved"],
        "next_step": "assign first task wave"
      },
      {
        "checkpoint_id": "cp-checkpoint-002",
        "phase": "before_integration",
        "decisions": ["integration may begin"],
        "next_step": "start integration"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-checkpoint-path",
      "approved_goal": "Validate checkpoint persistence",
      "active_acceptance_criteria": ["checkpoint at required boundaries"],
      "current_phase": "integration",
      "open_blockers": [],
      "next_actions": [{"owner":"verification","task_id":"T3","action":"verify checkpoint chain"}],
      "last_checkpoint_id": "cp-checkpoint-002",
      "resume_risks": []
    }'
    ;;
  recovery-prep-path)
    panel_roles='["lead", "implementation", "verification"]'
    team_roles='["lead", "implementation", "verification"]'
    task_owner_1="implementation"
    task_owner_2="verification"
    markers=(
      "interaction.preflight.started"
      "interaction.preflight.config_checked"
      "interaction.preflight.passed"
      "interaction.boundary.announced"
      "panel.confirmed"
      "interaction.stage.collected"
      "interaction.batch.1.sent"
      "interaction.batch.1.received"
      "interaction.routing.applied"
      "interaction-state-persisted"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "recovery.prep_started"
      "recovery.snapshot_refreshed"
      "recovery.resume_point_declared"
      "recovery-prep-refreshed"
    )
    execution_mode="serial"
    question_stage_id="stage-recovery-safety-check"
    question_ids='["q-recovery-safe-resume"]'
    reply_route='{"q-recovery-safe-resume":{"task_id":"T3","owner_role":"lead"}}'
    last_sync_turn_id="turn-recovery-001"
    reports_lines=(
      '{"task_id":"T1","role_id":"implementation","status":"done","summary":"Prepared state for compact-safe handoff."}'
      '{"task_id":"T2","role_id":"verification","status":"in_progress","summary":"Reviewing recovery readiness."}'
    )
    handoffs_lines=(
      '{"from_role":"implementation","to_role":"verification","task_id":"T1","summary":"Recovery payload ready for review."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-recovery-001",
        "phase": "before_final_wrap_up",
        "decisions": ["refresh compact recovery before finish"],
        "next_step": "declare safe resume point"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-recovery-prep-path",
      "approved_goal": "Validate recovery preparation",
      "active_acceptance_criteria": ["fresh compact recovery snapshot before finish"],
      "current_phase": "final_wrap_up",
      "open_blockers": [],
      "next_actions": [{"owner":"lead","task_id":"T3","action":"resume from compact-recovery.json if interrupted"}],
      "last_checkpoint_id": "cp-recovery-001",
      "resume_risks": ["compact could interrupt final review"]
    }'
    ;;
  interaction-protocol-path)
    panel_roles='["lead", "planner", "implementation", "verification"]'
    team_roles='["lead", "planner", "implementation", "verification"]'
    task_owner_1="planner"
    task_owner_2="implementation"
    markers=(
      "interaction.display.summary_first"
      "interaction.display.sent_input.collapsed"
      "interaction.display.sent_input.expanded"
      "interaction.display.finished_waiting.collapsed"
      "interaction.display.finished_waiting.expanded"
      "interaction.display.indentation.valid"
      "interaction.display.truncation.applied"
      "checkpoint.recorded"
      "interaction-display-contract-passed"
      "interaction-display-semantics-consistent"
    )
    execution_mode="parallel"
    question_stage_id="stage-acceptance-gate"
    question_batch_index="2"
    question_ids='["q-acceptance-risk-threshold","q-acceptance-release-gate"]'
    reply_route='{
      "q-acceptance-goal":{"task_id":"T1","owner_role":"planner"},
      "q-acceptance-non-goal":{"task_id":"T1","owner_role":"planner"},
      "q-acceptance-owner":{"task_id":"T2","owner_role":"implementation"},
      "q-acceptance-risk-threshold":{"task_id":"T2","owner_role":"implementation"},
      "q-acceptance-release-gate":{"task_id":"T2","owner_role":"verification"}
    }'
    last_sync_turn_id="turn-interaction-002"
    reports_lines=(
      '{"task_id":"T1","role_id":"planner","status":"done","summary":"Collected stage-level questions and produced structured ids."}'
      '{"task_id":"T2","role_id":"implementation","status":"in_progress","summary":"Applied routed answer slices without large relay narrative."}'
      '{"task_id":"T3","role_id":"verification","status":"pending","summary":"Waiting for acceptance gate after routed replies."}'
    )
    handoffs_lines=(
      '{"from_role":"planner","to_role":"implementation","task_id":"T1","summary":"Answer ids mapped to implementation-owned decisions."}'
      '{"from_role":"lead","to_role":"verification","task_id":"T2","summary":"Release-gate answer routed to verification only."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-interaction-001",
        "phase": "after_interaction_stage",
        "decisions": ["preflight passed", "5 question stage batched as 3+2", "reply routing persisted"],
        "next_step": "continue implementation with routed answers"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-interaction-protocol-path",
      "approved_goal": "Validate unified interaction protocol and preflight checks",
      "active_acceptance_criteria": ["lead-only user interaction", "batched request_user_input", "structured routing persisted"],
      "current_phase": "interaction_routing_applied",
      "open_blockers": [],
      "next_actions": [{"owner":"implementation","task_id":"T2","action":"execute with routed answers from interaction stage"}],
      "last_checkpoint_id": "cp-interaction-001",
      "resume_risks": []
    }'
    rendered_event_lines=(
      "[2026-03-19T03:24:01Z] Sent input -> impl | T2 | clarify gate | Validate release gate..."
      "[2026-03-19T03:24:01Z] Sent input"
      "  target: impl"
      "  task_id: T2"
      "  intent: clarify acceptance"
      "  topic: release gate"
      "  body: User asks for release gate validation with dependency checks and staged rollout notes; include risk handling for integration stability and edge-case sign-off before verification."
      "    body_source: lead_relay"
      "[2026-03-19T03:24:08Z] Finished waiting -> impl | completed | 1732ms | Gate accepted..."
      "[2026-03-19T03:24:08Z] Finished waiting"
      "  target: impl"
      "  status: completed"
      "  elapsed_ms: 1732"
      "  result: Accepted release gate; one rollback risk kept for verification handoff."
      "  next_action: relay"
      "    next_owner: verification"
    )
    ;;
  *)
    echo "Unsupported fixture: $fixture" >&2
    exit 1
    ;;
esac

cat >"$state_dir/session.json" <<EOF
{
  "session_id": "sess-$fixture",
  "fixture": "$fixture",
  "mode": "with-codex-agent-team",
  "current_phase": "in_progress",
  "execution_mode": "$execution_mode",
  "awaiting_user_reply": $awaiting_user_reply,
  "awaiting_mode": "$awaiting_mode",
  "question_stage_id": "$question_stage_id",
  "question_batch_index": $question_batch_index,
  "question_ids": $question_ids,
  "reply_route": $reply_route,
  "last_sync_turn_id": "$last_sync_turn_id"
}
EOF

cat >"$state_dir/panel.json" <<EOF
{
  "task_understanding": {
    "goal": "Run fixture $fixture",
    "deliverable": "fixture evidence bundle"
  },
  "recommended_defaults": {
    "likely_roles": $panel_roles
  },
  "needs_confirmation": [],
  "approved_contract": {
    "fixture": "$fixture",
    "roles": $panel_roles,
    "acceptance_criteria": ["workflow correctness", "dual evidence"]
  }
}
EOF

cat >"$state_dir/team.json" <<EOF
{
  "roles": $team_roles,
  "charter": [
    {"role_id":"lead","responsibility":"coordinate workflow","user_interaction_route":"direct"},
    {"role_id":"$task_owner_1","responsibility":"own first task wave","user_interaction_route":"via_lead"},
    {"role_id":"$task_owner_2","responsibility":"own review/integration follow-up","user_interaction_route":"via_lead"}
  ]
}
EOF

cat >"$state_dir/tasks.json" <<EOF
{
  "tasks": [
    {"task_id":"T1","owner_role":"$task_owner_1","status":"done","depends_on":[]},
    {"task_id":"T2","owner_role":"$task_owner_2","status":"in_progress","depends_on":["T1"]}
  ]
}
EOF

cat >"$state_dir/checkpoints.json" <<EOF
{
  "checkpoints": $checkpoints_payload
}
EOF

cat >"$state_dir/compact-recovery.json" <<EOF
$compact_recovery
EOF

: >"$state_dir/reports.jsonl"
for line in "${reports_lines[@]}"; do
  printf '%s\n' "$line" >>"$state_dir/reports.jsonl"
done

: >"$state_dir/handoffs.jsonl"
for line in "${handoffs_lines[@]}"; do
  printf '%s\n' "$line" >>"$state_dir/handoffs.jsonl"
done

: >"$state_dir/last-breaths.jsonl"

: >"$session_dir/phase-markers.log"
: >"$session_dir/session.log"
for marker in "${markers[@]}"; do
  printf '[marker] %s\n' "$marker" >>"$session_dir/phase-markers.log"
  printf 'marker:%s\n' "$marker" >>"$session_dir/session.log"
done

if (( ${#rendered_event_lines[@]} > 0 )); then
  for line in "${rendered_event_lines[@]}"; do
    printf '%s\n' "$line" >>"$session_dir/session.log"
  done
fi

printf 'run_dir=%s\n' "$run_dir" >>"$session_dir/session.log"
printf '%s\n' "$run_dir"
