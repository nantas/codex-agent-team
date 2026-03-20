# Agent Install Guide

This guide is the canonical install entry for `codex-agent-team`.

## Scope Confirmation

Before install, agent must ask user one question:

- install scope: `project` or `global`

## Install Targets

- `project`: `<project-root>/.agents/skills/codex-agent-team`
- `global`: `~/.agents/skills/codex-agent-team`

## Install Commands

If repository is already cloned:

```bash
./.agents/install-local.sh --scope project
```

```bash
./.agents/install-local.sh --scope global
```

First-time clone example:

```bash
git clone <your-fork-or-origin-url> ~/codex-agent-team
cd ~/codex-agent-team
./.agents/install-local.sh --scope global
```

## Verify

Project scope:

```bash
test -f .agents/skills/codex-agent-team/SKILL.md
find .agents/skills/codex-agent-team/references -maxdepth 1 -type f | sort
```

Global scope:

```bash
test -f ~/.agents/skills/codex-agent-team/SKILL.md
find ~/.agents/skills/codex-agent-team/references -maxdepth 1 -type f | sort
```
