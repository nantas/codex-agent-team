#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/codex-agent-team-e2e.XXXXXX")"
trap 'rm -rf "${tmp_root}"' EXIT

cd "${repo_root}"

echo "[1/4] release dry-run smoke"
dry_output="$(bash .agents/release.sh --intent "发布 v1.0.0" --repo acme/codex-agent-team --dry-run)"
grep -q "TARGET_VERSION=1.0.0" <<<"${dry_output}"
grep -q "INSTALL_GUIDE_URL=https://github.com/acme/codex-agent-team/blob/v1.0.0/.agents/INSTALL.md" <<<"${dry_output}"

echo "[2/4] release notes generation smoke"
notes_file="${tmp_root}/release-notes-v1.0.0.md"
python3 .agents/scripts/generate_release_notes.py \
  --repo acme/codex-agent-team \
  --version 1.0.0 \
  --changelog-path CHANGELOG.md > "${notes_file}"
grep -q "^## Changelog" "${notes_file}"
grep -q "^## Agent Auto Install" "${notes_file}"
grep -q "https://github.com/acme/codex-agent-team/blob/v1.0.0/.agents/INSTALL.md" "${notes_file}"

echo "[3/4] project-scope install smoke"
project_target="${tmp_root}/project/.agents/skills"
bash .agents/install-local.sh \
  --scope project \
  --repo "${repo_root}" \
  --target-dir "${project_target}" \
  --skill-name codex-agent-team-e2e
test -f "${project_target}/codex-agent-team-e2e/SKILL.md"

echo "[4/4] global-scope install smoke (redirected target)"
global_target="${tmp_root}/global/.agents/skills"
bash .agents/install-local.sh \
  --scope global \
  --repo "${repo_root}" \
  --target-dir "${global_target}" \
  --skill-name codex-agent-team-e2e-global
test -f "${global_target}/codex-agent-team-e2e-global/SKILL.md"

echo "E2E smoke PASS"
