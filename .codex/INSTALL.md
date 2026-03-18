# Codex Agent Team Install

This repository ships a local installer for Codex skill discovery.

## Quick Install

First-time install from a dedicated checkout:

```bash
git clone <your-fork-or-origin-url> ~/.codex/codex-agent-team
~/.codex/codex-agent-team/.codex/install-local.sh --repo ~/.codex/codex-agent-team
```

If you already cloned the repo and are currently in its root:

```bash
./.codex/install-local.sh
```

Clone alone is insufficient. The installer must run at least once so the skill package is copied into the local Codex skill directory.

## Update

```bash
git pull
./.codex/install-local.sh
```

Restart Codex after updating so the refreshed skill package is reloaded.

## Verify

```bash
ls ~/.codex/skills/codex-agent-team
test -f ~/.codex/skills/codex-agent-team/SKILL.md
find ~/.codex/skills/codex-agent-team/references -maxdepth 1 -type f | sort
```

## Uninstall

```bash
rm -rf ~/.codex/skills/codex-agent-team
```

Restart Codex after uninstall if the skill still appears in the catalog.

## Override Target

Install into an alternate skill root:

```bash
./.codex/install-local.sh --target-dir /tmp/codex-skills
```

Install under a different skill directory name:

```bash
./.codex/install-local.sh --skill-name codex-agent-team-dev
```

Use an explicit checkout path:

```bash
./.codex/install-local.sh --repo /absolute/path/to/codex-agent-team
```

The `--repo` path must be absolute.

## Troubleshooting

- If install fails with `missing payload`, ensure `SKILL.md` and `references/` exist in the checkout.
- If Codex does not discover the skill, restart Codex after install or update.
- If you need side-by-side testing, use `--target-dir` or `--skill-name` instead of editing the script.
