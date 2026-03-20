# Agent Prompt-Driven Release Workflow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a fully automated release workflow triggered by user prompt intent (for example `发布新版本`, `发布 v1.2.3`) that publishes a GitHub Release page containing changelog content and one fixed agent-install prompt linked to a version-pinned install guide.

**Architecture:** Keep release orchestration in-repo with deterministic scripts under `.agents/`, use `CHANGELOG.md` as the release source of truth, and publish Release notes from a generated markdown artifact that always includes the required install prompt line. Installation is standardized to `.agents/skills` only, with explicit `project` and `global` scopes. GitHub Actions handles final release publishing on version tags.

**Tech Stack:** Bash, Python 3, GitHub Actions, `gh` CLI (optional local publish path), Markdown docs.

---

### Task 1: Create Release Contract and Scope Definitions

**Files:**
- Create: `docs/release-contract.md`
- Modify: `AGENTS.md`

**Step 1: Write the failing policy check test first**

Create a policy test scaffold:

```python
# tests/release/test_release_contract.py
from pathlib import Path

def test_release_contract_has_required_sections():
    text = Path("docs/release-contract.md").read_text(encoding="utf-8")
    for key in [
        "Prompt Triggers",
        "Version Resolution Rules",
        "Release Page Required Sections",
        "Agent Install Prompt Canonical Line",
        "Install Scope Mapping",
    ]:
        assert f"## {key}" in text
```

**Step 2: Run test to verify RED**

Run: `python3 -m pytest tests/release/test_release_contract.py -q`  
Expected: FAIL (`docs/release-contract.md` missing)

**Step 3: Write minimal contract doc**

Document only necessary rules:
- prompt triggers: `发布新版本`, `发布 xxx 版本`, `发布 vX.Y.Z`
- explicit version or bump resolution
- required release body blocks:
  - `## Changelog`
  - `## Agent Auto Install`
- canonical install prompt line format
- scope mapping:
  - `project -> <repo>/.agents/skills`
  - `global -> ~/.agents/skills`
- prohibition: `.codex/skills`

**Step 4: Add AGENTS routing hook**

Add a concise rule in `AGENTS.md` so prompt-intent release requests route to the release automation script.

**Step 5: Run test to verify GREEN and commit**

Run: `python3 -m pytest tests/release/test_release_contract.py -q`  
Expected: PASS

```bash
git add docs/release-contract.md AGENTS.md tests/release/test_release_contract.py
git commit -m "docs: define prompt-driven release contract and routing"
```

### Task 2: Add Version-Pinned Install Guide in `.agents`

**Files:**
- Create: `.agents/INSTALL.md`
- Modify: `README.md`

**Step 1: Write failing test first**

```python
# tests/release/test_install_guide.py
from pathlib import Path

def test_install_guide_enforces_agents_skills_only():
    text = Path(".agents/INSTALL.md").read_text(encoding="utf-8")
    assert ".agents/skills" in text
    assert ".codex/skills" not in text
```

**Step 2: Run test to verify RED**

Run: `python3 -m pytest tests/release/test_install_guide.py -q`  
Expected: FAIL (`.agents/INSTALL.md` missing)

**Step 3: Write minimal install guide**

Include:
- agent must ask user `project` or `global` before install
- project target: `<project-root>/.agents/skills/codex-agent-team`
- global target: `~/.agents/skills/codex-agent-team`
- verification commands for both scopes

**Step 4: Update README install sections**

Point install docs to `.agents/INSTALL.md`, keep wording concise, remove `.codex/skills` defaults.

**Step 5: Re-run tests and commit**

Run: `python3 -m pytest tests/release/test_install_guide.py -q`  
Expected: PASS

```bash
git add .agents/INSTALL.md README.md tests/release/test_install_guide.py
git commit -m "docs: add .agents installation guide and scope mapping"
```

### Task 3: Implement Unified Installer for `project|global`

**Files:**
- Create: `.agents/install-local.sh`
- Modify: `.codex/install-local.sh`
- Create: `tests/release/test_install_script.py`

**Step 1: Write failing tests for argument and path behavior**

```python
import subprocess

def run(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)

def test_install_script_requires_scope_or_interactive_flag():
    p = run("bash .agents/install-local.sh")
    assert p.returncode != 0
    assert "--scope project|global" in p.stderr
```

**Step 2: Run tests to verify RED**

Run: `python3 -m pytest tests/release/test_install_script.py -q`  
Expected: FAIL (script missing)

**Step 3: Implement minimal installer**

Behavior:
- required input: `--scope project|global`
- optional: `--repo`, `--skill-name`
- default targets:
  - `project`: `<repo>/.agents/skills`
  - `global`: `${HOME}/.agents/skills`
- package payload: `SKILL.md`, `references/`, `README.md`, `.agents/INSTALL.md`
- atomic stage-copy then replace

**Step 4: Convert `.codex/install-local.sh` to compatibility wrapper**

Wrapper prints deprecation notice and delegates to `.agents/install-local.sh` with preserved args.

**Step 5: Run tests and commit**

Run:
- `bash -n .agents/install-local.sh .codex/install-local.sh`
- `python3 -m pytest tests/release/test_install_script.py -q`

Expected: all PASS

```bash
git add .agents/install-local.sh .codex/install-local.sh tests/release/test_install_script.py
git commit -m "feat: add scope-aware installer targeting .agents/skills"
```

### Task 4: Add Changelog Source-of-Truth and Parser

**Files:**
- Create: `CHANGELOG.md`
- Create: `.agents/scripts/changelog_extract.py`
- Create: `tests/release/test_changelog_extract.py`

**Step 1: Write failing extractor tests first**

```python
from .helpers import run_py

def test_extract_specific_version_block():
    result = run_py(".agents/scripts/changelog_extract.py", "--version", "1.0.0")
    assert result.returncode == 0
    assert "## [1.0.0]" not in result.stdout
    assert "### Added" in result.stdout
```

**Step 2: Run to verify RED**

Run: `python3 -m pytest tests/release/test_changelog_extract.py -q`  
Expected: FAIL (file/script missing)

**Step 3: Implement minimal changelog + extractor**

- `CHANGELOG.md` format: Keep a Changelog style, headings like `## [1.2.3] - YYYY-MM-DD`
- extractor returns exact markdown section body for requested version
- fail non-zero if version section missing

**Step 4: Re-run tests**

Run: `python3 -m pytest tests/release/test_changelog_extract.py -q`  
Expected: PASS

**Step 5: Commit**

```bash
git add CHANGELOG.md .agents/scripts/changelog_extract.py tests/release/test_changelog_extract.py
git commit -m "feat: add changelog source and version extractor"
```

### Task 5: Generate Canonical Release Notes With Required Install Prompt

**Files:**
- Create: `.agents/scripts/generate_release_notes.py`
- Create: `tests/release/test_generate_release_notes.py`

**Step 1: Write failing tests first**

```python
def test_release_notes_include_required_install_prompt_line():
    # run generator for v1.2.3
    # assert one-line prompt includes:
    # "https://github.com/<org>/<repo>/blob/v1.2.3/.agents/INSTALL.md"
    ...
```

**Step 2: Run RED**

Run: `python3 -m pytest tests/release/test_generate_release_notes.py -q`  
Expected: FAIL

**Step 3: Implement generator**

Inputs:
- `--repo owner/repo`
- `--version X.Y.Z`
- `--changelog-path CHANGELOG.md`

Output markdown must include:
- `## Changelog` (from extractor)
- `## Agent Auto Install`
- canonical single-line prompt:
  - `请让你的 agent 按此安装指南完成 codex-agent-team vX.Y.Z 安装：https://github.com/<owner>/<repo>/blob/vX.Y.Z/.agents/INSTALL.md`

**Step 4: Re-run tests**

Run: `python3 -m pytest tests/release/test_generate_release_notes.py -q`  
Expected: PASS

**Step 5: Commit**

```bash
git add .agents/scripts/generate_release_notes.py tests/release/test_generate_release_notes.py
git commit -m "feat: generate release notes with canonical install prompt"
```

### Task 6: Implement Prompt-Driven Release Orchestrator Script

**Files:**
- Create: `.agents/release.sh`
- Create: `tests/release/test_release_orchestrator.py`

**Step 1: Write failing tests first**

Test matrix:
- `--intent "发布新版本"` + `--bump patch`
- `--intent "发布 v1.4.0"` (explicit version)
- invalid version rejected
- dry-run mode produces deterministic output and no git mutation

**Step 2: Run RED**

Run: `python3 -m pytest tests/release/test_release_orchestrator.py -q`  
Expected: FAIL

**Step 3: Implement minimal orchestrator**

Flow:
1. resolve target version (explicit or bump)
2. ensure working tree clean (except allowed generated files)
3. run `tests/run-all.sh`
4. generate release notes markdown artifact under `.agents/out/release-notes-vX.Y.Z.md`
5. create commit/tag (`vX.Y.Z`)
6. push branch and tag
7. optionally call `gh release create` (or rely on workflow in Task 7)

**Step 4: Re-run tests**

Run: `python3 -m pytest tests/release/test_release_orchestrator.py -q`  
Expected: PASS

**Step 5: Commit**

```bash
git add .agents/release.sh tests/release/test_release_orchestrator.py
git commit -m "feat: add prompt-driven release orchestrator"
```

### Task 7: Add GitHub Action for Tagged Release Publishing

**Files:**
- Create: `.github/workflows/release.yml`
- Create: `tests/release/test_release_workflow_contract.py`

**Step 1: Write failing workflow contract test first**

```python
from pathlib import Path

def test_release_workflow_has_required_steps():
    text = Path(".github/workflows/release.yml").read_text(encoding="utf-8")
    assert "on:" in text
    assert "tags:" in text and "v*" in text
    assert "generate_release_notes.py" in text
    assert "Agent Auto Install" in text or "release-notes" in text
```

**Step 2: Run RED**

Run: `python3 -m pytest tests/release/test_release_workflow_contract.py -q`  
Expected: FAIL

**Step 3: Implement workflow**

Trigger: push tags `v*`  
Core steps:
- checkout
- setup python
- run `tests/run-all.sh`
- run release note generator for tag version
- publish GitHub Release with generated body

**Step 4: Re-run test**

Run: `python3 -m pytest tests/release/test_release_workflow_contract.py -q`  
Expected: PASS

**Step 5: Commit**

```bash
git add .github/workflows/release.yml tests/release/test_release_workflow_contract.py
git commit -m "feat: publish tagged releases with generated install prompt"
```

### Task 8: Documentation and Backward Compatibility Cleanup

**Files:**
- Modify: `.codex/INSTALL.md`
- Modify: `README.md`
- Create: `docs/release-operations.md`

**Step 1: Write failing doc consistency test first**

```python
from pathlib import Path

def test_repo_docs_prefer_agents_install_path():
    corpus = "\n".join(
        Path(p).read_text(encoding="utf-8")
        for p in ["README.md", ".codex/INSTALL.md", "docs/release-operations.md"]
    )
    assert ".agents/skills" in corpus
```

**Step 2: Run RED**

Run: `python3 -m pytest tests/release/test_doc_consistency.py -q`  
Expected: FAIL

**Step 3: Update docs**

- `.codex/INSTALL.md`: mark legacy, point to `.agents/INSTALL.md`
- `README.md`: release flow entry + prompt trigger examples
- `docs/release-operations.md`: operator runbook (dry-run, real run, rollback)

**Step 4: Run tests**

Run: `python3 -m pytest tests/release/test_doc_consistency.py -q`  
Expected: PASS

**Step 5: Commit**

```bash
git add README.md .codex/INSTALL.md docs/release-operations.md tests/release/test_doc_consistency.py
git commit -m "docs: align release and install docs to .agents paths"
```

### Task 9: End-to-End Verification and Release Dry Run

**Files:**
- Modify: `tests/README.md`
- Create: `tests/release/e2e-smoke.sh`

**Step 1: Add failing e2e smoke script first**

Define checks:
- generate release notes for a fixture version
- assert release notes include changelog + prompt line + version-pinned INSTALL URL
- run installer in temp project/global dirs and verify targets

**Step 2: Run RED**

Run: `bash tests/release/e2e-smoke.sh`  
Expected: FAIL before implementation completion

**Step 3: Implement minimal e2e smoke**

Use temp dirs and `--dry-run` where possible; ensure no accidental tag push in CI.

**Step 4: Run full verification suite**

Run:
- `bash -n .agents/install-local.sh .agents/release.sh .codex/install-local.sh`
- `python3 -m pytest tests/release -q`
- `tests/run-all.sh`
- `bash tests/release/e2e-smoke.sh`

Expected: all PASS

**Step 5: Final commit**

```bash
git add tests/README.md tests/release/e2e-smoke.sh
git commit -m "test: add release e2e smoke verification"
```

## Notes

- Keep implementation DRY: centralize release-note generation in one script used by both local release command and GitHub workflow.
- Keep YAGNI: no UI, no external DB, no package manager integration; repository-local scripts only.
- Keep release deterministic: same version input must produce identical release body (except timestamp metadata if any).
- Enforce one canonical install prompt sentence per release to reduce operator variance.
- Prefer failing-fast for missing changelog sections, malformed semver, or absent `.agents/INSTALL.md`.

Plan complete and saved to `docs/plans/2026-03-20-agent-prompt-driven-release-workflow-plan.md`. Two execution options:

1. Subagent-Driven (this session) - I dispatch fresh subagent per task, review between tasks, fast iteration
2. Parallel Session (separate) - Open new session with executing-plans, batch execution with checkpoints

Which approach?
