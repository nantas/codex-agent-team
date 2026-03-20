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
resource_budget='{"max_concurrent_specialists":2,"open_agent_count":1}'
fd_downgrade='{"active": false, "trigger": null, "pause_spawn_waves": false, "mode_before": "parallel", "mode_after": "parallel", "stabilization_evidence": "not_required"}'
workflow_status="active"
final_notice_sent="false"
delivery_root="null"
closed_at="null"
delivery_contract='{"delivery_root":null,"entry":null,"link_policy":"relative-markdown-links-only"}'
scope_drift_state="null"
scope_revision='"rev-001-initial"'

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
      "resume_risks": [],
      "suspendedAgents": []
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
      "resume_risks": [],
      "suspendedAgents": []
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
      "resume_risks": [],
      "suspendedAgents": []
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
      "resume_risks": ["compact could interrupt final review"],
      "suspendedAgents": []
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
      "resume_risks": [],
      "suspendedAgents": []
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
  resource-safety-path)
    panel_roles='["lead", "implementation", "verification"]'
    team_roles='["lead", "implementation", "verification"]'
    task_owner_1="implementation"
    task_owner_2="verification"
    markers=(
      "panel.confirmed"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "resource.budget.persisted"
      "resource.close_agent.cleanup"
      "recovery.suspended_agents.refreshed"
      "resource.resume_agent.rehydrated"
      "resource-close-cleanup-confirmed"
      "resource-resume-sequenced"
    )
    question_stage_id="stage-resource-safety"
    question_ids='["q-resource-cleanup-ready"]'
    reply_route='{"q-resource-cleanup-ready":{"task_id":"T1","owner_role":"implementation"}}'
    last_sync_turn_id="turn-resource-001"
    resource_budget='{"max_concurrent_specialists":3,"open_agent_count":1}'
    reports_lines=(
      '{"task_id":"T1","role_id":"implementation","status":"done","summary":"Produced suspend-ready implementation handoff."}'
      '{"task_id":"T2","role_id":"verification","status":"in_progress","summary":"Resumed from checkpointed suspend metadata."}'
    )
    handoffs_lines=(
      '{"from_role":"implementation","to_role":"verification","task_id":"T1","summary":"Checkpointed handoff recorded before close_agent cleanup."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-resource-001",
        "phase": "after_implementation_handoff",
        "decisions": ["implementation specialist cleaned up with close_agent"],
        "next_step": "resume specialist deterministically"
      },
      {
        "checkpoint_id": "cp-resource-002",
        "phase": "after_resume_handoff",
        "decisions": ["resume_agent and scoped send_input completed"],
        "next_step": "continue verification"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-resource-safety-path",
      "approved_goal": "Validate close and resume lifecycle controls",
      "active_acceptance_criteria": ["close_agent cleanup required", "resume via checkpointed state"],
      "current_phase": "resume_in_progress",
      "open_blockers": [],
      "next_actions": [{"owner":"verification","task_id":"T2","action":"continue resumed verification task"}],
      "last_checkpoint_id": "cp-resource-002",
      "resume_risks": ["stale suspended agents list can cause wrong resume target"],
      "suspendedAgents": [
        {
          "agent_id": "agent-impl-01",
          "role_id": "implementation",
          "task_id": "T1",
          "status": "suspended",
          "suspend_reason": "handoff_checkpointed_then_closed",
          "handoff_checkpoint_id": "cp-resource-001",
          "resume_input": {
            "task_id": "T1",
            "owner_role": "implementation",
            "instruction": "Resume from checkpoint cp-resource-001 and continue scoped implementation follow-up."
          }
        },
        {
          "agent_id": "agent-ver-01",
          "role_id": "verification",
          "task_id": "T2",
          "status": "suspended",
          "suspend_reason": "verification_pause_for_gate",
          "handoff_checkpoint_id": "cp-resource-002",
          "resume_input": {
            "task_id": "T2",
            "owner_role": "verification",
            "instruction": "Resume from checkpoint cp-resource-002 and finish verification gate review."
          }
        }
      ]
    }'
    ;;
  emfile-downgrade-path)
    panel_roles='["lead", "implementation", "verification"]'
    team_roles='["lead", "implementation", "verification"]'
    task_owner_1="implementation"
    task_owner_2="verification"
    markers=(
      "panel.confirmed"
      "team.formed"
      "tasks.assigned"
      "resource.fd_budget.persisted"
      "resource.fd.emfile_detected"
      "execution.mode.serial_downgraded"
      "execution.spawn_waves.paused"
      "checkpoint.recorded"
      "resource-emfile-downgrade-triggered"
      "resource-emfile-serial-guard-active"
    )
    execution_mode="serial"
    question_stage_id="stage-emfile-guardrail"
    question_ids='["q-emfile-stabilization-window"]'
    reply_route='{"q-emfile-stabilization-window":{"task_id":"T2","owner_role":"verification"}}'
    last_sync_turn_id="turn-emfile-001"
    resource_budget='{"max_concurrent_specialists":4,"open_agent_count":4}'
    fd_downgrade='{"active": true, "trigger": "EMFILE", "pause_spawn_waves": true, "mode_before": "parallel", "mode_after": "serial", "stabilization_evidence": "fd_errors_cleared_and_open_agent_count_below_budget"}'
    reports_lines=(
      '{"task_id":"T1","role_id":"implementation","status":"done","summary":"Detected FD exhaustion and raised downgrade event."}'
      '{"task_id":"T2","role_id":"verification","status":"in_progress","summary":"Serial guardrail active while waiting for stabilization evidence."}'
    )
    handoffs_lines=(
      '{"from_role":"implementation","to_role":"verification","task_id":"T1","summary":"EMFILE downgrade triggered; spawn waves paused."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-emfile-001",
        "phase": "fd_downgrade_triggered",
        "decisions": ["execution downgraded parallel->serial due to EMFILE"],
        "next_step": "pause spawn waves and gather stabilization evidence"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-emfile-downgrade-path",
      "approved_goal": "Validate EMFILE downgrade guardrail",
      "active_acceptance_criteria": ["serial downgrade on EMFILE", "pause spawn waves until stable"],
      "current_phase": "serial_guardrail_active",
      "open_blockers": ["fd_exhaustion_active"],
      "next_actions": [{"owner":"verification","task_id":"T2","action":"verify stabilization evidence before resuming parallel"}],
      "last_checkpoint_id": "cp-emfile-001",
      "resume_risks": ["resuming parallel too early can repeat FD exhaustion"],
      "suspendedAgents": []
    }'
    ;;
  deliverable-packaging-path)
    panel_roles='["lead", "synthesis", "verification"]'
    team_roles='["lead", "synthesis", "verification"]'
    task_owner_1="synthesis"
    task_owner_2="verification"
    markers=(
      "panel.confirmed"
      "checkpoint.recorded"
      "delivery.packaging.started"
      "delivery.entry.index_generated"
      "delivery.manifest.generated"
      "closure.summary.generated"
      "delivery.packaging.completed"
    )
    question_stage_id="stage-delivery-packaging"
    question_ids='["q-delivery-package-ready"]'
    reply_route='{"q-delivery-package-ready":{"task_id":"T2","owner_role":"verification"}}'
    last_sync_turn_id="turn-delivery-001"
    workflow_status="closing"
    delivery_root='".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable"'
    delivery_contract='{"delivery_root":".codex/multi-agent/deliverables/<topic>-<YYYYMMDD>-<session_id>","entry":"DELIVERABLE_INDEX.md","link_policy":"relative-markdown-links-only"}'
    reports_lines=(
      '{"task_id":"T1","role_id":"synthesis","status":"done","summary":"Prepared baseline synthesis package content."}'
      '{"task_id":"T2","role_id":"verification","status":"in_progress","summary":"Checking deliverable package completeness."}'
    )
    handoffs_lines=(
      '{"from_role":"synthesis","to_role":"verification","task_id":"T1","summary":"Deliverable package ready for final completeness check."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-delivery-001",
        "phase": "delivery_packaging",
        "decisions": ["package path fixed", "entry+manifest+closure summary required"],
        "next_step": "run closure completeness review"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-deliverable-packaging-path",
      "approved_goal": "Validate deliverable packaging contract",
      "active_acceptance_criteria": ["themed deliverable directory", "required package files present"],
      "current_phase": "closure_review",
      "workflow_status": "closing",
      "final_notice_sent": false,
      "delivery_root": ".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable",
      "open_blockers": [],
      "next_actions": [{"owner":"verification","task_id":"T2","action":"validate package completeness and link policy"}],
      "last_checkpoint_id": "cp-delivery-001",
      "resume_risks": [],
      "suspendedAgents": [],
      "closure_state": {"phase":"closure_review","gate_passed":true,"final_notice_sent":false,"delivery_entry_path":".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable/DELIVERABLE_INDEX.md"}
    }'
    ;;
  final-closure-control-path)
    panel_roles='["lead", "synthesis", "verification"]'
    team_roles='["lead", "synthesis", "verification"]'
    task_owner_1="synthesis"
    task_owner_2="verification"
    markers=(
      "panel.confirmed"
      "checkpoint.recorded"
      "closure.phase.synthesis_done"
      "closure.phase.delivery_packaging"
      "closure.phase.closure_review"
      "closure.phase.user_final_notice"
      "closure.notice.sent"
      "closure.phase.workflow_closed"
    )
    question_stage_id="stage-final-closure"
    question_ids='["q-final-closure-ack"]'
    reply_route='{"q-final-closure-ack":{"task_id":"T2","owner_role":"verification"}}'
    last_sync_turn_id="turn-closure-001"
    workflow_status="closed"
    final_notice_sent="true"
    delivery_root='".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-closure"'
    closed_at='"20260320T120500Z"'
    delivery_contract='{"delivery_root":".codex/multi-agent/deliverables/<topic>-<YYYYMMDD>-<session_id>","entry":"DELIVERABLE_INDEX.md","link_policy":"relative-markdown-links-only"}'
    reports_lines=(
      '{"task_id":"T1","role_id":"synthesis","status":"done","summary":"Completed closure review and objective attainment summary."}'
      '{"task_id":"T2","role_id":"verification","status":"done","summary":"Validated final notice and closed-state persistence."}'
    )
    handoffs_lines=(
      '{"from_role":"lead","to_role":"verification","task_id":"T1","summary":"Final notice sent; validate workflow closed state."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-closure-001",
        "phase": "delivery_packaging",
        "decisions": ["delivery package completed"],
        "next_step": "run closure review"
      },
      {
        "checkpoint_id": "cp-closure-002",
        "phase": "user_final_notice",
        "decisions": ["final notice emitted to user"],
        "next_step": "persist closed state"
      },
      {
        "checkpoint_id": "cp-closure-003",
        "phase": "workflow_closed",
        "decisions": ["workflow marked closed"],
        "next_step": "stop orchestration"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-final-closure-control-path",
      "approved_goal": "Validate hard closure gates and explicit completion signaling",
      "active_acceptance_criteria": ["closure chain respected", "final notice sent before closed"],
      "current_phase": "workflow_closed",
      "workflow_status": "closed",
      "final_notice_sent": true,
      "delivery_root": ".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-closure",
      "open_blockers": [],
      "next_actions": [{"owner":"lead","task_id":"NONE","action":"none"}],
      "last_checkpoint_id": "cp-closure-003",
      "resume_risks": [],
      "suspendedAgents": [],
      "closure_state": {"phase":"workflow_closed","gate_passed":true,"final_notice_sent":true,"delivery_entry_path":".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-closure/DELIVERABLE_INDEX.md"}
    }'
    ;;
  relative-link-integrity-path)
    panel_roles='["lead", "synthesis", "verification"]'
    team_roles='["lead", "synthesis", "verification"]'
    task_owner_1="synthesis"
    task_owner_2="verification"
    markers=(
      "panel.confirmed"
      "delivery.entry.index_generated"
      "delivery.links.relative_enforced"
      "delivery.links.integrity_checked"
      "checkpoint.recorded"
    )
    question_stage_id="stage-relative-link-check"
    question_ids='["q-link-integrity-pass"]'
    reply_route='{"q-link-integrity-pass":{"task_id":"T2","owner_role":"verification"}}'
    last_sync_turn_id="turn-links-001"
    workflow_status="closing"
    delivery_root='".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links"'
    delivery_contract='{"delivery_root":".codex/multi-agent/deliverables/<topic>-<YYYYMMDD>-<session_id>","entry":"DELIVERABLE_INDEX.md","link_policy":"relative-markdown-links-only"}'
    reports_lines=(
      '{"task_id":"T1","role_id":"synthesis","status":"done","summary":"Generated deliverable index with sidecar links."}'
      '{"task_id":"T2","role_id":"verification","status":"in_progress","summary":"Validating relative-link integrity and target presence."}'
    )
    handoffs_lines=(
      '{"from_role":"synthesis","to_role":"verification","task_id":"T1","summary":"Entry doc links ready for integrity validation."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-links-001",
        "phase": "closure_review",
        "decisions": ["relative link policy applied"],
        "next_step": "verify all sidecar links resolve"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-relative-link-integrity-path",
      "approved_goal": "Validate relative markdown link integrity in final entry doc",
      "active_acceptance_criteria": ["links relative", "link targets exist"],
      "current_phase": "closure_review",
      "workflow_status": "closing",
      "final_notice_sent": false,
      "delivery_root": ".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links",
      "open_blockers": [],
      "next_actions": [{"owner":"verification","task_id":"T2","action":"validate all entry-doc links resolve to existing files"}],
      "last_checkpoint_id": "cp-links-001",
      "resume_risks": [],
      "suspendedAgents": [],
      "closure_state": {"phase":"closure_review","gate_passed":true,"final_notice_sent":false,"delivery_entry_path":".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-links/DELIVERABLE_INDEX.md"}
    }'
    ;;
  scope-drift-recovery-path)
    panel_roles='["lead", "planner", "implementation", "verification"]'
    team_roles='["lead", "planner", "implementation", "verification"]'
    task_owner_1="planner"
    task_owner_2="implementation"
    markers=(
      "panel.confirmed"
      "scope.drift.detected"
      "scope.contract.updated"
      "tasks.replanned"
      "checkpoint.recorded"
      "recovery.snapshot_refreshed"
      "scope-drift-recovery-applied"
    )
    question_stage_id="stage-scope-drift-replan"
    question_ids='["q-scope-drift-approval"]'
    reply_route='{"q-scope-drift-approval":{"task_id":"T2","owner_role":"implementation"}}'
    last_sync_turn_id="turn-scope-001"
    workflow_status="active"
    scope_revision='"rev-002-drift-applied"'
    scope_drift_state='{
      "detected": true,
      "reason": "user changed scope boundaries after new evidence",
      "old_scope_digest": "scope-a1",
      "new_scope_digest": "scope-b2",
      "applied_revision": "rev-002-drift-applied"
    }'
    reports_lines=(
      '{"task_id":"T1","role_id":"planner","status":"done","summary":"Detected scope drift and proposed updated contract boundary."}'
      '{"task_id":"T2","role_id":"implementation","status":"in_progress","summary":"Replanned execution tasks after scope revision rev-002-drift-applied."}'
    )
    handoffs_lines=(
      '{"from_role":"planner","to_role":"implementation","task_id":"T1","summary":"Scope revision approved; apply replanned task sequence."}'
    )
    checkpoints_payload='[
      {
        "checkpoint_id": "cp-scope-001",
        "phase": "scope_drift_detected",
        "decisions": ["scope drift confirmed from new user constraint"],
        "scope_drift": {"detected": true, "revision": "rev-002-drift-applied"},
        "next_step": "rewrite approved contract and replan tasks"
      },
      {
        "checkpoint_id": "cp-scope-002",
        "phase": "post_scope_replan",
        "decisions": ["tasks replanned and reassigned after scope change"],
        "scope_drift": {"detected": true, "revision": "rev-002-drift-applied"},
        "next_step": "continue execution with replanned scope"
      }
    ]'
    compact_recovery='{
      "session_id": "sess-scope-drift-recovery-path",
      "approved_goal": "Validate deterministic recovery behavior after scope drift",
      "active_acceptance_criteria": ["checkpoint after scope change", "replanned tasks reflected in recovery"],
      "current_phase": "post_scope_replan",
      "open_blockers": ["follow-up verification pending under revised scope"],
      "next_actions": [{"owner":"verification","task_id":"T3","action":"validate replanned outputs against revised scope"}],
      "last_checkpoint_id": "cp-scope-002",
      "resume_risks": ["if revision mismatches, resumed tasks may use stale scope"],
      "suspendedAgents": []
    }'
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
  "workflow_status": "$workflow_status",
  "final_notice_sent": $final_notice_sent,
  "delivery_root": $delivery_root,
  "closed_at": $closed_at,
  "scope_drift_state": $scope_drift_state,
  "resource_budget": $resource_budget,
  "fd_downgrade": $fd_downgrade,
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
    "scope_revision": $scope_revision,
    "acceptance_criteria": ["workflow correctness", "dual evidence"],
    "delivery_contract": $delivery_contract
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

if [[ "$fixture" == "deliverable-packaging-path" ]]; then
  delivery_dir="$state_dir/deliverables/baseline-synthesis-20260320-sess-deliverable"
  mkdir -p "$delivery_dir"
  cat >"$delivery_dir/DELIVERABLE_INDEX.md" <<'EOF'
# Deliverable Index

## Goal and scope
Baseline synthesis package for issue evidence.

## Macro synthesis
Fact-source split and closure controls are now explicit.

## Acceptance matrix
| criterion | status | evidence |
|---|---|---|
| package generated | pass | [delivery-manifest.json](./delivery-manifest.json) |

## Open risks and unresolved items
- Runtime autotest logs still need follow-up collection.

## Artifact index
- [delivery-manifest.json](./delivery-manifest.json)
- [closure-summary.json](./closure-summary.json)

## Next steps
1. Start improvement design from this package.

## Metadata
- session_id: sess-deliverable-packaging-path
- checkpoint_id: cp-delivery-001
- generated_at: 20260320T120000Z
- owner: lead
EOF
  cat >"$delivery_dir/delivery-manifest.json" <<'EOF'
{
  "session_id": "sess-deliverable-packaging-path",
  "topic": "baseline-synthesis",
  "generated_at": "20260320T120000Z",
  "entry": "DELIVERABLE_INDEX.md",
  "files": ["DELIVERABLE_INDEX.md", "closure-summary.json"]
}
EOF
  cat >"$delivery_dir/closure-summary.json" <<'EOF'
{
  "workflow_status": "closing",
  "objective_attainment": "partial",
  "delivery_root": ".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-deliverable",
  "final_notice_sent": false,
  "remaining_items": ["emit final user notice"]
}
EOF
fi

if [[ "$fixture" == "final-closure-control-path" ]]; then
  delivery_dir="$state_dir/deliverables/baseline-synthesis-20260320-sess-closure"
  mkdir -p "$delivery_dir"
  cat >"$delivery_dir/DELIVERABLE_INDEX.md" <<'EOF'
# Deliverable Index

## Goal and scope
Finalize closure control package.

## Macro synthesis
Closure gates completed in fixed order and explicitly closed.

## Acceptance matrix
| criterion | status | evidence |
|---|---|---|
| final notice sent | pass | [closure-summary.json](./closure-summary.json) |

## Open risks and unresolved items
- none

## Artifact index
- [delivery-manifest.json](./delivery-manifest.json)
- [closure-summary.json](./closure-summary.json)

## Next steps
1. Stop orchestration.

## Metadata
- session_id: sess-final-closure-control-path
- checkpoint_id: cp-closure-003
- generated_at: 20260320T120500Z
- owner: lead
EOF
  cat >"$delivery_dir/delivery-manifest.json" <<'EOF'
{
  "session_id": "sess-final-closure-control-path",
  "topic": "baseline-synthesis",
  "generated_at": "20260320T120500Z",
  "entry": "DELIVERABLE_INDEX.md",
  "artifacts": ["closure-summary.json"]
}
EOF
  cat >"$delivery_dir/closure-summary.json" <<'EOF'
{
  "workflow_status": "closed",
  "goal_attainment": "complete",
  "delivery_root": ".codex/multi-agent/deliverables/baseline-synthesis-20260320-sess-closure",
  "final_notice_sent": true,
  "remaining_items": []
}
EOF
fi

if [[ "$fixture" == "relative-link-integrity-path" ]]; then
  delivery_dir="$state_dir/deliverables/baseline-synthesis-20260320-sess-links"
  mkdir -p "$delivery_dir"
  cat >"$delivery_dir/issue-01.md" <<'EOF'
# Issue 01

Evidence note.
EOF
  cat >"$delivery_dir/issue-02.md" <<'EOF'
# Issue 02

Evidence note.
EOF
  cat >"$delivery_dir/DELIVERABLE_INDEX.md" <<'EOF'
# Deliverable Index

## Goal and scope
Validate relative markdown links in entry doc.

## Macro synthesis
All sidecar references use local relative paths.

## Acceptance matrix
| criterion | status | evidence |
|---|---|---|
| relative links only | pass | [issue-01.md](./issue-01.md) |
| link targets exist | pass | [issue-02.md](./issue-02.md) |

## Open risks and unresolved items
- none

## Artifact index
- [issue-01.md](./issue-01.md)
- [issue-02.md](./issue-02.md)
- [delivery-manifest.json](./delivery-manifest.json)

## Next steps
1. Apply same link policy to production runs.

## Metadata
- session_id: sess-relative-link-integrity-path
- checkpoint_id: cp-links-001
- generated_at: 20260320T121000Z
- owner: lead
EOF
  cat >"$delivery_dir/delivery-manifest.json" <<'EOF'
{
  "session_id": "sess-relative-link-integrity-path",
  "topic": "baseline-synthesis",
  "generated_at": "20260320T121000Z",
  "entry": "DELIVERABLE_INDEX.md",
  "files": ["DELIVERABLE_INDEX.md", "issue-01.md", "issue-02.md"]
}
EOF
fi

printf 'run_dir=%s\n' "$run_dir" >>"$session_dir/session.log"
printf '%s\n' "$run_dir"
