# Codex Agent Team OS Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Codex-only shareable workflow skill in this repository that drafts a task panel, persists team state under project-local `.codex/`, and coordinates a lead-plus-specialists operating model designed to reduce compact regressions.

**Architecture:** The repository will host one root skill package with a short `SKILL.md` entrypoint and sidecar reference docs for intake, state model, communication, team formation, execution rules, and recovery. Implementation should follow the writing-skills discipline: baseline failure scenarios first, then minimal skill guidance, then re-test and tighten loopholes.

**Tech Stack:** Markdown skill docs, JSON examples/schemas where useful, shell-based validation, Codex skill conventions.

---

### Task 1: Initialize Repository Skeleton

**Files:**
- Create: `SKILL.md`
- Create: `references/intake-and-panel.md`
- Create: `references/shared-state-model.md`
- Create: `references/communication-protocol.md`
- Create: `references/team-formation.md`
- Create: `references/checkpoints-and-recovery.md`
- Create: `references/execution-rules.md`
- Create: `references/role-template-defaults.md`

**Step 1: Create the base directories**

Run: `mkdir -p references`
Expected: `references/` exists in the repo root.

**Step 2: Create stub files with only headings**

Write minimal placeholders to each file so the repository has an explicit target structure before content is added.

**Step 3: Verify the file tree**

Run: `find . -maxdepth 2 -type f | sort`
Expected: the root `SKILL.md` and all seven reference files are present.

**Step 4: Commit**

```bash
git add SKILL.md references
git commit -m "chore: initialize codex agent team skill structure"
```

### Task 2: Define Baseline Failure Scenarios Before Skill Content

**Files:**
- Create: `validation/baseline-scenarios.md`
- Create: `validation/manual-eval-checklist.md`

**Step 1: Write the baseline failure scenarios**

Document at least these pressure cases:

- the lead agent starts spawning workers before clarifying the user's true goal
- the system asks the user to configure too many variables up front
- peer agents exchange information without writing summaries back to shared state
- compact occurs without an updated recovery snapshot
- a sub-agent exits and no recoverable "last breath" is captured

**Step 2: Define what failure looks like without the skill**

For each scenario, describe the observable bad outcome in plain language.

**Step 3: Create a manual evaluation checklist**

The checklist should let a future operator test:

- whether panel drafting happened before live orchestration
- whether defaults were proposed instead of a long intake questionnaire
- whether shared state files were part of the workflow
- whether compact recovery was explicitly handled

**Step 4: Commit**

```bash
git add validation
git commit -m "test: define baseline failure scenarios for the workflow skill"
```

### Task 3: Write the Root Skill Entrypoint

**Files:**
- Modify: `SKILL.md`

**Step 1: Write the frontmatter**

Use only:

```yaml
---
name: codex-agent-team
description: Use when the user explicitly wants a Codex-only multi-agent workflow for a complex task with a lead agent, specialist sub-agents, shared state, checkpoints, and compact-safe recovery.
---
```

**Step 2: Add hard constraints**

The entrypoint must state:

- manual trigger only
- panel confirmation before live orchestration
- state must be externalized under project-local `.codex/`
- compact requires recovery refresh
- execution uses sidecar docs, not one giant inline workflow

**Step 3: Add the navigation flow**

Link to the exact reference docs in the order they should be read.

**Step 4: Review for brevity**

Ensure `SKILL.md` stays concise and routes rather than restating all details.

**Step 5: Commit**

```bash
git add SKILL.md
git commit -m "feat: add codex agent team skill entrypoint"
```

### Task 4: Write Intake and Panel Guidance

**Files:**
- Modify: `references/intake-and-panel.md`

**Step 1: Document extraction-first behavior**

Specify that the workflow should infer:

- goal
- non-goals
- deliverable
- acceptance criteria
- constraints
- likely roles

before asking the user follow-up questions.

**Step 2: Define the `panel.json` structure**

Include:

- `task_understanding`
- `recommended_defaults`
- `needs_confirmation`
- `approved_contract`

**Step 3: Define the user confirmation behavior**

Make clear that the user corrects the agent's draft rather than filling a full configuration form.

**Step 4: Add a compact example**

Include one short example of:

- input prompt
- inferred panel draft
- confirmation interaction shape

**Step 5: Commit**

```bash
git add references/intake-and-panel.md
git commit -m "feat: document intake and task panel workflow"
```

### Task 5: Write Shared State Model Guidance

**Files:**
- Modify: `references/shared-state-model.md`

**Step 1: Define the `.codex/multi-agent/` layout**

Document the first-version files:

- `session.json`
- `panel.json`
- `team.json`
- `tasks.json`
- `checkpoints.json`
- `reports.jsonl`
- `handoffs.jsonl`
- `last-breaths.jsonl`
- `compact-recovery.json`

**Step 2: Define ownership rules**

State clearly which files are lead-owned and which append/update surfaces are specialist-writable.

**Step 3: Define update triggers**

Document when each file must be refreshed.

**Step 4: Add one minimal JSON example**

Show one example snapshot for:

- `panel.json`
- `tasks.json`
- `compact-recovery.json`

Keep examples small.

**Step 5: Commit**

```bash
git add references/shared-state-model.md
git commit -m "feat: document shared state model"
```

### Task 6: Write Communication Protocol Guidance

**Files:**
- Modify: `references/communication-protocol.md`

**Step 1: Define the protocol rationale**

Explain that Codex collaboration messages need explicit sender and intent semantics in the message body.

**Step 2: Define the allowed message types**

Document:

- `assign`
- `question`
- `answer`
- `status`
- `blocker`
- `handoff`

**Step 3: Define required fields**

Every message must carry:

- sender
- sender role
- target
- task id
- intent
- topic
- reply mode

**Step 4: Define short reply shapes**

Document compact reply formats for:

- questions
- status reports
- blockers
- handoffs

**Step 5: Add peer communication rules**

Limit peer usage to:

- clarification
- contract/interface confirmation
- dependency resolution

**Step 6: Commit**

```bash
git add references/communication-protocol.md
git commit -m "feat: document communication protocol"
```

### Task 7: Write Team Formation and Role Defaults

**Files:**
- Modify: `references/team-formation.md`
- Modify: `references/role-template-defaults.md`

**Step 1: Document the default team skeleton**

State that only the lead is fixed and all specialists are derived from the approved contract.

**Step 2: Document role generation by task type**

Cover at least:

- implementation-heavy
- debugging
- research

**Step 3: Define the required contents of a role charter**

Every role should specify:

- mission
- owned scope
- non-goals
- allowed peer queries
- expected outputs
- escalation triggers
- state write permissions

**Step 4: Add a small library of default role templates**

Include at least:

- implementation specialist
- integration specialist
- verification specialist
- reproduction specialist
- root cause specialist
- research specialist
- synthesis specialist

**Step 5: Commit**

```bash
git add references/team-formation.md references/role-template-defaults.md
git commit -m "feat: document team formation and role defaults"
```

### Task 8: Write Checkpoint and Recovery Guidance

**Files:**
- Modify: `references/checkpoints-and-recovery.md`

**Step 1: Define mandatory checkpoint triggers**

Include:

- stage boundaries
- context-heavy moments
- pre-compact
- post-blocker resolution
- user scope changes
- unexpected agent exits

**Step 2: Define checkpoint actions**

Require:

- state settlement
- snapshot refresh
- critical decision capture
- next safe resume point

**Step 3: Define recovery order**

Document the read order:

1. `compact-recovery.json`
2. `session.json`
3. `tasks.json`
4. `checkpoints.json`
5. append logs only if needed

**Step 4: Define the last-breath contract**

Require a structured exit summary for interrupted or errored sub-agents.

**Step 5: Commit**

```bash
git add references/checkpoints-and-recovery.md
git commit -m "feat: document checkpoints and recovery"
```

### Task 9: Write Execution Rules

**Files:**
- Modify: `references/execution-rules.md`

**Step 1: Define live orchestration discipline**

Specify:

- when the lead may spawn new specialists
- when the lead must wait
- when specialists may message peers
- when issues must be escalated to the lead

**Step 2: Define anti-drift rules**

Require:

- panel contract remains authoritative
- acceptance cannot be silently changed
- peer agents cannot redefine scope

**Step 3: Define compact discipline**

State that compact must only happen after checkpoint-style state externalization.

**Step 4: Commit**

```bash
git add references/execution-rules.md
git commit -m "feat: document execution rules"
```

### Task 10: Validate the Skill Against Baseline Scenarios

**Files:**
- Modify: `validation/manual-eval-checklist.md`
- Optionally Create: `validation/results/2026-03-18-baseline-vs-skill.md`

**Step 1: Run the baseline scenarios mentally or in controlled manual prompts without using the skill**

Record the likely failure patterns.

**Step 2: Re-run the same scenarios using the new skill**

Check whether the workflow now:

- drafts a panel first
- avoids long upfront interrogation
- externalizes state
- refreshes recovery state before compact
- captures abnormal exits

**Step 3: Record any loopholes**

If the workflow still permits obvious drift or state loss, capture the exact failure and patch the relevant file.

**Step 4: Commit**

```bash
git add validation
git commit -m "test: validate codex agent team workflow against baseline scenarios"
```

### Task 11: Final Review and Packaging Check

**Files:**
- Modify: `SKILL.md`
- Modify: `references/*.md` as needed

**Step 1: Review trigger quality**

Confirm the skill is clearly manual-triggered and Codex-only.

**Step 2: Review progressive disclosure**

Confirm `SKILL.md` is concise and sidecar routing is explicit.

**Step 3: Review consistency**

Confirm terminology is consistent across:

- panel
- team
- tasks
- checkpoints
- compact recovery

**Step 4: Run a repository sanity check**

Run: `find . -maxdepth 3 -type f | sort`
Expected: the root skill, reference docs, validation docs, and plans are present and sensibly named.

**Step 5: Commit**

```bash
git add .
git commit -m "chore: finalize codex agent team workflow skill package"
```
