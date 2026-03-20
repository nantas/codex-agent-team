# Release Contract

## Prompt Triggers

Release automation starts when user intent matches one of:

- `发布新版本`
- `发布 xxx 版本`
- `发布 vX.Y.Z`

## Version Resolution Rules

- If prompt includes explicit semantic version (`X.Y.Z` or `vX.Y.Z`), use it directly.
- If prompt is `发布新版本`, agent must ask one follow-up for bump type: `major`, `minor`, or `patch`.
- Reject invalid or non-semver target versions.

## Release Page Required Sections

Each GitHub Release body must include exactly:

- `## Changelog`
- `## Agent Auto Install`

`## Changelog` content is sourced from `CHANGELOG.md` for the released version only.

## Agent Install Prompt Canonical Line

Release body must include one canonical single-line prompt:

`请让你的 agent 按此安装指南完成 codex-agent-team vX.Y.Z 安装：https://github.com/<owner>/<repo>/blob/vX.Y.Z/.agents/INSTALL.md`

The install guide link must be tag-pinned to the released version.

## Install Scope Mapping

- `project` installs to `<project-root>/.agents/skills/codex-agent-team`
- `global` installs to `~/.agents/skills/codex-agent-team`
- installation target `.codex/skills` is forbidden for this workflow
