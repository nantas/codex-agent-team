# Codex Agent Team

`codex-agent-team` is a Codex-oriented multi-agent workflow skill. It helps a lead agent draft a task panel, externalize shared state under `.codex/multi-agent/`, coordinate specialist sub-agents, and keep checkpoint/recovery state fresh.

## Install For Agents

Clone alone is not enough. Run the installer so the skill is copied into your local Codex skill directory.

First-time install:

```bash
git clone <your-fork-or-origin-url> ~/.codex/codex-agent-team
~/.codex/codex-agent-team/.codex/install-local.sh --repo ~/.codex/codex-agent-team
```

Already cloned in this checkout:

```bash
./.codex/install-local.sh
```

After install or update, restart Codex so it reloads the local skill catalog.

Detailed scenarios, verify, update, uninstall, and troubleshooting:

- [`.codex/INSTALL.md`](./.codex/INSTALL.md)

## What Gets Installed

The installer publishes a self-contained skill package containing:

- `SKILL.md`
- `references/`
- this `README.md`

Default destination:

```text
~/.codex/skills/codex-agent-team
```

You can override the destination with `--target-dir` and the installed skill directory name with `--skill-name`.

## Verify

```bash
ls ~/.codex/skills/codex-agent-team
find ~/.codex/skills/codex-agent-team/references -maxdepth 1 -type f | sort
```
