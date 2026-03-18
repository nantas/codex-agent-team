# Codex Agent Team OS Design

## Goal

Design a Codex-only global workflow skill that helps a lead agent organize and run a small expert team for complex tasks while reducing compact frequency, recovery regressions, goal drift, and context loss.

## Scope

This design covers:

- manual user-triggered entry only
- Codex-specific orchestration using native collaboration tools
- task intake and panel confirmation before any live orchestration
- mixed state management through thread coordination plus repository-local files
- a default-but-overridable team model
- checkpoint and recovery rules intended to reduce compact damage
- a shareable standalone repository layout for the skill

This design does not cover:

- runtime-agnostic compatibility layers
- automatic triggering based on intent classification
- a full event-sourced implementation
- a rigid global team structure that applies unchanged to every task

## User Outcome

The intended user experience is:

- complex tasks can be handled within limited context windows more reliably
- the system requires fewer compacts because task truth is externalized earlier
- when compact does happen, the task is less likely to regress or drift because recovery reads structured state instead of relying on fragile conversational memory

## Core Product Position

This skill is not a domain skill. It is a Codex team operating system.

It should:

- read a user request for a complex task
- draft a machine-friendly task panel with extracted understanding and suggested defaults
- let the user correct only the important parts
- create a shared state area under the current repository's `.codex/`
- form a lead-plus-specialists team
- run live orchestration using short structured coordination
- persist enough truth that compact and agent failure become recoverable events instead of silent regressions

## Entry Constraints

The skill must be explicitly invoked by the user.

It must not auto-trigger.

Before live orchestration begins, the skill must:

1. extract information from the user prompt
2. build a draft task panel
3. present the agent's understanding and recommended defaults
4. let the user correct the minimum necessary items
5. persist the approved contract

Only then may the lead agent form and coordinate the team.

## Skill Structure

The skill should live in this repository root as a single shareable skill package.

Recommended structure:

```text
SKILL.md
references/
  intake-and-panel.md
  shared-state-model.md
  communication-protocol.md
  team-formation.md
  checkpoints-and-recovery.md
  execution-rules.md
  role-template-defaults.md
```

Design intent:

- `SKILL.md` stays short and acts as the router
- deeper operational details live in sidecar docs
- only the relevant sidecar doc is loaded per phase

## End-to-End Flow

### 1. Intake

The lead agent reads the user's prompt and extracts:

- goal
- non-goals
- expected deliverable
- tentative acceptance criteria
- known constraints
- obvious risks
- likely specialist roles

It should prefer inference plus defaults over asking the user to fill a long configuration form.

### 2. Panel Draft

The lead agent writes a draft `panel.json` that contains:

- current task understanding
- recommended defaults
- items that need confirmation
- a place for approved contract values

The user should be asked to correct the agent's understanding, not author the whole process from scratch.

### 3. User Confirmation

The user confirms or edits the minimum set of important variables:

- goal accuracy
- non-goals
- acceptance criteria
- role adjustments
- phase strategy adjustments

If the user gives only a simple approval, defaults are accepted and promoted into the approved contract.

### 4. Live Orchestration

After approval, the lead agent:

- initializes `.codex/multi-agent/`
- writes shared state files
- forms the team
- creates tasks
- spawns only the specialists actually needed
- begins structured coordination

### 5. Checkpointed Execution

During execution, the lead agent and specialists:

- keep task truth in shared files
- keep thread messages short and structured
- summarize key peer exchanges back into shared state
- perform stage and condition-based checkpoints
- refresh compact recovery state before risk accumulates

## Shared State Model

The first version should use a lightweight snapshot-plus-log design under:

```text
.codex/multi-agent/
```

Recommended files:

- `session.json`
- `panel.json`
- `team.json`
- `tasks.json`
- `checkpoints.json`
- `reports.jsonl`
- `handoffs.jsonl`
- `last-breaths.jsonl`
- `compact-recovery.json`

Responsibilities:

- lead agent owns global truth files and checkpoint state
- specialists may update task-local execution state and append-only report streams
- compact recovery reads short snapshots first, logs only as fallback

This is intentionally lighter than full event sourcing, but structured enough to externalize task truth.

## Communication Model

Because Codex collaboration input does not natively inject sender semantics into model-visible message structure, the workflow must encode source and intent inside the message content.

Recommended message types:

- `assign`
- `question`
- `answer`
- `status`
- `blocker`
- `handoff`

Every message should carry:

- sender
- sender role
- target
- task id
- intent
- topic
- reply mode

Protocol goals:

- keep each message narrow
- keep peer exchange tied to a concrete task
- ensure peer outcomes are summarized back into shared state
- reduce lead-agent context pollution

## Team Model

The only fixed role is the lead coordinator.

All other roles are generated from the approved contract and task type.

Examples by task shape:

- implementation-heavy task: implementation, integration, verification
- debugging task: reproduction, root cause, fix, verification
- research task: research, tradeoff analysis, synthesis

Each generated role must define:

- mission
- owned scope
- non-goals
- allowed peer queries
- expected outputs
- escalation triggers
- state write permissions

If a role cannot be described clearly in those terms, it should not be created.

## Checkpoints and Recovery

Checkpoints are mandatory because the real risk is not compact itself but long stretches of unexternalized task state.

Trigger checkpoints:

- after panel confirmation
- after team formation
- after first task wave assignment
- after major blocker resolution
- before integration
- before acceptance review
- before final wrap-up
- whenever context has grown heavy
- whenever compact is likely
- whenever new user information changes scope
- whenever an agent exits unexpectedly

Each checkpoint should:

- settle current facts
- update shared files
- refresh `compact-recovery.json`
- preserve critical decisions
- declare the next safe resume point

`compact-recovery.json` should remain intentionally short and contain only the minimum needed to resume without goal drift.

## Repository Strategy

The skill should be built in this standalone repository so it can be shared and versioned independently of any one project.

The repository's purpose is:

- host the skill package
- host plan and design documents
- later host validation artifacts for skill authoring

The skill itself is intended to operate inside whatever repository the user is currently working in, not inside this repo's own `.codex/`.

## Design Principles

- manual activation only
- Codex-only assumptions are acceptable
- prefer defaults plus user correction over long intake questionnaires
- externalize task truth early
- keep live messages short and structured
- keep global truth under lead control
- allow specialists to write task-local execution state
- make compact a controlled maintenance step, not a state-loss event

## Future Evolution

The selected design is the lightweight A path: center-led coordination with a shared task ledger.

Potential later evolutions:

- add a stronger phase state machine on top of the same files
- evolve append streams toward event sourcing
- derive richer snapshots from logs once the lightweight version proves useful

Those are intentionally deferred. The first version should prove the workflow with minimal moving parts.
