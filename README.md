# Codex Agent Team

`codex-agent-team` is a Codex-oriented multi-agent workflow skill. It helps a lead agent draft a task panel, externalize shared state under `.codex/multi-agent/`, coordinate specialist sub-agents, and keep checkpoint/recovery state fresh.

Current interaction baseline:

- unified user interaction protocol for both `parallel` and `serial` execution
- lead-owned `request_user_input` collection with structured routing
- no direct user-to-subagent interaction in `parallel`

## Install For Agents

Clone alone is not enough. Run the installer so the skill is copied into `.agents/skills`.

First-time install:

```bash
git clone <your-fork-or-origin-url> ~/codex-agent-team
cd ~/codex-agent-team
./.agents/install-local.sh --scope global
```

Already cloned in this checkout:

```bash
./.agents/install-local.sh --scope project
```

After install or update, restart Codex so it reloads the local skill catalog.

Detailed scenarios, verify, update, uninstall, and troubleshooting:

- [`.agents/INSTALL.md`](./.agents/INSTALL.md)

## What Gets Installed

The installer publishes a self-contained skill package containing:

- `SKILL.md`
- `references/`
- this `README.md`

Default destination:

```text
~/.agents/skills/codex-agent-team
```

Project-scope destination:

```text
<project-root>/.agents/skills/codex-agent-team
```

## Verify

```bash
ls ~/.agents/skills/codex-agent-team
find ~/.agents/skills/codex-agent-team/references -maxdepth 1 -type f | sort
```

## Release

Prompt-driven release automation entry:

```bash
./.agents/release.sh --intent "发布新版本" --bump patch --repo <owner/repo> --dry-run
```

```bash
./.agents/release.sh --intent "发布 vX.Y.Z" --repo <owner/repo>
```

Release details and operator runbook:

- [`docs/release-operations.md`](./docs/release-operations.md)
