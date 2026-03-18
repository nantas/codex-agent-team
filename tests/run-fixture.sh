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

case "$fixture" in
  basic-happy-path)
    panel_roles='["lead", "implementation", "verification"]'
    team_roles='["lead", "implementation", "verification"]'
    task_owner_1="implementation"
    task_owner_2="verification"
    markers=(
      "panel.drafted"
      "panel.confirmed"
      "execution.orchestration_started"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "recovery.snapshot_refreshed"
      "panel-confirmed"
      "team-formed"
    )
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
      "panel.drafted"
      "panel.confirmed"
      "panel.override_roles_received"
      "panel.override_roles_applied"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "role-override-confirmed"
      "role-override-applied"
    )
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
      "panel.confirmed"
      "team.formed"
      "tasks.assigned"
      "checkpoint.after_panel_confirmation"
      "checkpoint.before_integration"
      "execution.integration_started"
      "checkpoint.recorded"
      "checkpoint-triggered"
      "checkpoint-persisted"
    )
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
      "panel.confirmed"
      "team.formed"
      "tasks.assigned"
      "checkpoint.recorded"
      "recovery.prep_started"
      "recovery.snapshot_refreshed"
      "recovery.resume_point_declared"
      "recovery-prep-refreshed"
    )
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
  "current_phase": "in_progress"
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
    {"role_id":"lead","responsibility":"coordinate workflow"},
    {"role_id":"$task_owner_1","responsibility":"own first task wave"},
    {"role_id":"$task_owner_2","responsibility":"own review/integration follow-up"}
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

printf 'run_dir=%s\n' "$run_dir" >>"$session_dir/session.log"
printf '%s\n' "$run_dir"
