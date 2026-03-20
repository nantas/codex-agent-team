# Repository Guidelines

## Project Structure & Module Organization
`codex-agent-team` is a skill package repository, not an application service.

- `SKILL.md`: entry contract and execution flow for the skill.
- `references/`: normative protocol docs (intake, team formation, execution rules, interaction, recovery).
- `fixtures/`: scenario definitions used by the deterministic test harness. One folder per fixture, plus `fixture-schema.md`.
- `tests/`: harness scripts and assertion CLI.
- `validation/`: manual evaluation checklists and baseline scenario definitions.
- `docs/plans/`: design and implementation planning notes.

Primary runtime state surface (in test outputs): `.codex/multi-agent/`.

## Build, Test, and Development Commands
- `./.codex/install-local.sh`: install/update this skill into local Codex skills.
- `tests/run-fixture.sh <fixture>`: generate one deterministic fixture run.
- `tests/collect-artifacts.sh <run-dir>`: collect filesystem + session evidence for a run.
- `python3 tests/assert-fixture.py --fixture <name> --run-dir <run-dir>`: layered assertions (existence, structural, semantic, forbidden markers).
- `tests/run-all.sh`: run the full fixture suite.

## Release Trigger Routing
- When user prompt intent matches release commands (for example `发布新版本`, `发布 xxx 版本`, `发布 vX.Y.Z`), route to repository release automation entrypoint: `./.agents/release.sh`.
- If version is not explicit, ask for bump type (`major|minor|patch`) before running release automation.

Example:
```bash
run_dir="$(tests/run-fixture.sh interaction-protocol-path)"
tests/collect-artifacts.sh "$run_dir"
python3 tests/assert-fixture.py --fixture interaction-protocol-path --run-dir "$run_dir"
```

## Coding Style & Naming Conventions
- Use Markdown with concise, imperative wording and explicit contracts.
- Keep JSON examples valid and minimal; prefer stable key names over prose-only rules.
- Fixture names: kebab-case (`interaction-protocol-path`).
- Marker names: dot-delimited (`interaction.preflight.passed`), as defined in `fixtures/fixture-schema.md`.
- Avoid broad refactors in the same change as protocol updates.

## Testing Guidelines
- Any workflow/protocol change should update both docs and fixture coverage.
- When adding a fixture, add `fixtures/<name>/README.md` with all required sections.
- When adding a fixture, wire it into `tests/run-fixture.sh`, `tests/run-all.sh`, and `SUPPORTED_FIXTURES` in `tests/assert-fixture.py`.
- Ensure expected artifacts include `.codex/multi-agent/*` evidence and phase markers.
- Run `tests/run-all.sh` before submitting.

## Commit & Pull Request Guidelines
- Follow Conventional Commit style seen in history: `feat:`, `test:`, `docs:`.
- Keep commits scoped to one logical change set (protocol + matching tests).
- PRs should include what contract changed.
- PRs should include which fixtures/assertions were added or updated.
- PRs should include the latest `tests/run-all.sh` result summary.
