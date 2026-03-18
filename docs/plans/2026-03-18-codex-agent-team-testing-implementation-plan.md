# Codex Agent Team Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a fixture-scenario-driven V1 test harness that validates basic `codex-agent-team` workflow correctness with real Codex collaboration and dual evidence (filesystem + session logs).

**Architecture:** The implementation adds a `fixtures/` scenario set plus a `tests/` harness layer with four entry scripts: run one fixture, collect artifacts, assert fixture expectations, and run all fixtures. Assertions are layered (existence, structural, semantic, must-not-happen) and scoped to four initial scenarios only.

**Tech Stack:** Bash scripts, Python assertion runner, Markdown fixture metadata/docs, repository-local artifact outputs.

---

### Task 1: Create Test Skeleton and Fixture Directories

**Files:**
- Create: `fixtures/basic-happy-path/README.md`
- Create: `fixtures/role-override-path/README.md`
- Create: `fixtures/checkpoint-path/README.md`
- Create: `fixtures/recovery-prep-path/README.md`
- Create: `tests/run-fixture.sh`
- Create: `tests/collect-artifacts.sh`
- Create: `tests/assert-fixture.py`
- Create: `tests/run-all.sh`

**Step 1: Create directories**

Run: `mkdir -p fixtures/basic-happy-path fixtures/role-override-path fixtures/checkpoint-path fixtures/recovery-prep-path tests`
Expected: all fixture and `tests/` directories exist.

**Step 2: Create empty script files and make shell scripts executable**

Run: `touch tests/run-fixture.sh tests/collect-artifacts.sh tests/assert-fixture.py tests/run-all.sh && chmod +x tests/run-fixture.sh tests/collect-artifacts.sh tests/run-all.sh`
Expected: all harness entry files exist; shell entries are executable.

**Step 3: Add minimal fixture README placeholders**

Write one-paragraph placeholders in each fixture README describing intent only.

**Step 4: Verify structure**

Run: `find fixtures tests -maxdepth 2 -type f | sort`
Expected: four fixture READMEs and four harness files are listed.

**Step 5: Commit**

```bash
git add fixtures tests
git commit -m "chore: scaffold fixture scenarios and harness entry files"
```

### Task 2: Define a Shared Fixture Contract

**Files:**
- Create: `fixtures/fixture-schema.md`
- Modify: `fixtures/basic-happy-path/README.md`
- Modify: `fixtures/role-override-path/README.md`
- Modify: `fixtures/checkpoint-path/README.md`
- Modify: `fixtures/recovery-prep-path/README.md`

**Step 1: Write fixture contract doc**

Document required fixture fields:

- fixture id
- prompt/input shape
- expected phase markers
- expected filesystem artifacts
- must-not-happen markers

**Step 2: Align each fixture README to the contract**

Add the same section headings to each fixture README so assertions can map consistently.

**Step 3: Verify consistency quickly**

Run: `rg "^## " fixtures/*/README.md fixtures/fixture-schema.md`
Expected: all fixture files share core section headings.

**Step 4: Commit**

```bash
git add fixtures
git commit -m "docs: define fixture contract for scenario-driven validation"
```

### Task 3: Implement `tests/run-fixture.sh` Entry Flow

**Files:**
- Modify: `tests/run-fixture.sh`

**Step 1: Write failing smoke behavior first**

Implement argument parsing (`<fixture-name>`) and exit non-zero with clear message for missing fixture.

**Step 2: Verify failure path**

Run: `tests/run-fixture.sh`
Expected: FAIL with usage error.

**Step 3: Add minimal success path skeleton**

Implement run directory creation under `tests/out/<fixture>/<timestamp>/` and placeholder invocation flow for top-level skill-triggered run.

**Step 4: Verify basic success path**

Run: `tests/run-fixture.sh basic-happy-path`
Expected: run directory is created with run metadata file.

**Step 5: Commit**

```bash
git add tests/run-fixture.sh
git commit -m "feat: add fixture runner entrypoint skeleton"
```

### Task 4: Implement `tests/collect-artifacts.sh` Evidence Collector

**Files:**
- Modify: `tests/collect-artifacts.sh`

**Step 1: Write failing behavior for missing run context**

Require explicit run directory input and fail if absent.

**Step 2: Verify failure path**

Run: `tests/collect-artifacts.sh`
Expected: FAIL with usage error.

**Step 3: Implement artifact collection skeleton**

Collect:

- filesystem artifacts bundle
- session log bundle
- manifest listing collected files

**Step 4: Verify output contract**

Run: `tests/collect-artifacts.sh tests/out/basic-happy-path/<run-id>`
Expected: `artifacts/` and manifest outputs exist for that run.

**Step 5: Commit**

```bash
git add tests/collect-artifacts.sh
git commit -m "feat: add evidence collection script"
```

### Task 5: Implement `tests/assert-fixture.py` Layered Assertions

**Files:**
- Modify: `tests/assert-fixture.py`

**Step 1: Write failing assertion for missing required evidence**

Implement minimal check that fails when either filesystem or session-log evidence is missing.

**Step 2: Verify failing assertion**

Run: `python3 tests/assert-fixture.py --fixture basic-happy-path --run-dir tests/out/basic-happy-path/<run-id>`
Expected: FAIL on incomplete evidence.

**Step 3: Add layered assertion pipeline**

Implement ordered stages:

1. existence
2. structural
3. semantic
4. must-not-happen

**Step 4: Add fixture-specific assertion mapping for 4 initial fixtures**

Implement per-fixture rule branches for:

- `basic-happy-path`
- `role-override-path`
- `checkpoint-path`
- `recovery-prep-path`

**Step 5: Verify with one positive and one negative run sample**

Run twice against controlled samples to confirm pass/fail reporting is explicit.

**Step 6: Commit**

```bash
git add tests/assert-fixture.py
git commit -m "feat: add layered fixture assertion engine"
```

### Task 6: Implement `tests/run-all.sh` Orchestrator

**Files:**
- Modify: `tests/run-all.sh`

**Step 1: Add fixture list and sequential loop**

Hardcode initial fixture order:

- basic-happy-path
- role-override-path
- checkpoint-path
- recovery-prep-path

**Step 2: Execute full chain per fixture**

For each fixture, run:

1. `tests/run-fixture.sh`
2. `tests/collect-artifacts.sh`
3. `python3 tests/assert-fixture.py`

**Step 3: Add aggregate summary output**

Print per-fixture status and final overall pass/fail.

**Step 4: Verify orchestration behavior**

Run: `tests/run-all.sh`
Expected: all fixtures execute in order; summary emitted; non-zero exit on any failure.

**Step 5: Commit**

```bash
git add tests/run-all.sh
git commit -m "feat: add run-all fixture harness orchestration"
```

### Task 7: Add Top-Layer Skill-Triggered Execution Notes

**Files:**
- Create: `tests/README.md`

**Step 1: Document dual-layer entry model**

Explain:

- top layer uses real skill-triggered/agent-driven workflow invocation
- bottom layer scripts provide deterministic evidence collection and assertions

**Step 2: Document exact local commands**

Include:

- `tests/run-fixture.sh <fixture>`
- `tests/run-all.sh`
- `python3 tests/assert-fixture.py ...`

**Step 3: Document V1 limitations**

State clearly that V1 validates workflow correctness only (not intelligence quality or full recovery robustness).

**Step 4: Commit**

```bash
git add tests/README.md
git commit -m "docs: describe dual-layer test harness usage and V1 scope"
```

### Task 8: Final Validation and Clean Handoff

**Files:**
- Modify: `tests/*.sh` and `tests/assert-fixture.py` as needed
- Modify: `fixtures/*/README.md` as needed

**Step 1: Run formatting/lint checks for scripts**

Run: `bash -n tests/run-fixture.sh tests/collect-artifacts.sh tests/run-all.sh`
Expected: no shell syntax errors.

**Step 2: Run full harness once**

Run: `tests/run-all.sh`
Expected: deterministic fixture-by-fixture output with explicit pass/fail reasons.

**Step 3: Verify repository scope**

Run: `git status --short`
Expected: only `fixtures/` and `tests/` changes (plus this plan/design docs if not committed yet).

**Step 4: Commit**

```bash
git add fixtures tests
git commit -m "test: deliver v1 codex-agent-team fixture validation harness"
```

## Notes for Execution

- Use `@superpowers/executing-plans` to run this plan task-by-task.
- Do not expand scope into intelligence scoring or full recovery stress testing in this iteration.
- Keep evidence contracts stable so future fixtures can be added without changing core harness flow.
