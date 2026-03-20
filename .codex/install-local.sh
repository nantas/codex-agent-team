#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
delegate="${repo_root}/.agents/install-local.sh"

if [[ ! -x "${delegate}" ]]; then
  echo "missing delegate installer: ${delegate}" >&2
  exit 1
fi

echo "Deprecated: use ./.agents/install-local.sh instead of ./.codex/install-local.sh" >&2
exec "${delegate}" "$@"
