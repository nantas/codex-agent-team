#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: ./.codex/install-local.sh [--repo /absolute/path] [--target-dir /path] [--skill-name name]

Installs the codex-agent-team skill package into a local Codex skill directory.
EOF
}

repo_root=""
target_dir="${HOME}/.codex/skills"
skill_name="codex-agent-team"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      repo_root="$2"
      shift 2
      ;;
    --target-dir)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      target_dir="$2"
      shift 2
      ;;
    --skill-name)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      skill_name="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_repo_root="$(cd "${script_dir}/.." && pwd)"

if [[ -z "${repo_root}" ]]; then
  repo_root="${default_repo_root}"
elif [[ "${repo_root}" != /* ]]; then
  echo "--repo must be an absolute path: ${repo_root}" >&2
  exit 1
fi

payload_paths=(
  "${repo_root}/SKILL.md"
  "${repo_root}/references"
  "${repo_root}/README.md"
)

for payload_path in "${payload_paths[@]}"; do
  if [[ ! -e "${payload_path}" ]]; then
    echo "missing payload: ${payload_path}" >&2
    exit 1
  fi
done

install_dir="${target_dir}/${skill_name}"
stage_root="$(mktemp -d "${TMPDIR:-/tmp}/codex-agent-team-install.XXXXXX")"
trap 'rm -rf "${stage_root}"' EXIT

mkdir -p "${target_dir}" "${stage_root}/${skill_name}"

cp "${repo_root}/SKILL.md" "${stage_root}/${skill_name}/SKILL.md"
cp "${repo_root}/README.md" "${stage_root}/${skill_name}/README.md"
cp -R "${repo_root}/references" "${stage_root}/${skill_name}/references"

rm -rf "${install_dir}"
mv "${stage_root}/${skill_name}" "${install_dir}"

echo "Installed ${skill_name} to ${install_dir}"
echo "Contents:"
find "${install_dir}" -maxdepth 2 -type f | sort
echo "Restart Codex to reload the local skill catalog."
