# Release Operations

This runbook defines how to publish versions using prompt-driven automation.

## Trigger Patterns

Use one of these intents:

- `发布新版本`
- `发布 xxx 版本`
- `发布 vX.Y.Z`

If version is not explicit, release runner must ask for bump type (`major|minor|patch`).

## Dry Run

```bash
./.agents/release.sh --intent "发布新版本" --bump patch --repo <owner/repo> --dry-run
```

Dry run prints:

- `TARGET_VERSION`
- release tag
- release notes output path
- version-pinned install guide URL

## Real Release

```bash
./.agents/release.sh --intent "发布 vX.Y.Z" --repo <owner/repo>
```

Flow:

1. validate clean working tree
2. run `tests/run-all.sh`
3. generate release notes
4. create commit/tag
5. publish Release from tag via workflow

## Required Release Body Contract

Each release body must include:

- `## Changelog`
- `## Agent Auto Install`

Agent install prompt must point to:

`https://github.com/<owner>/<repo>/blob/vX.Y.Z/.agents/INSTALL.md`

## Install Scope Policy

- `project`: `<project-root>/.agents/skills/codex-agent-team`
- `global`: `~/.agents/skills/codex-agent-team`

`.codex/skills` is out of scope for this release workflow.
