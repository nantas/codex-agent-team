#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: ./.agents/release.sh --intent "<release intent>" --repo owner/repo [--bump major|minor|patch] [--changelog-path CHANGELOG.md] [--dry-run]

Examples:
  ./.agents/release.sh --intent "发布新版本" --bump patch --repo owner/repo --dry-run
  ./.agents/release.sh --intent "发布 v1.4.0" --repo owner/repo --dry-run
EOF
}

intent=""
bump=""
repo=""
dry_run=false
changelog_path="CHANGELOG.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --intent)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      intent="$2"
      shift 2
      ;;
    --bump)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      bump="$2"
      shift 2
      ;;
    --repo)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      repo="$2"
      shift 2
      ;;
    --changelog-path)
      [[ $# -ge 2 ]] || { usage; exit 1; }
      changelog_path="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
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

if [[ -z "$intent" ]]; then
  echo "missing required argument: --intent" >&2
  exit 1
fi
if [[ -z "$repo" ]]; then
  echo "missing required argument: --repo" >&2
  exit 1
fi
if [[ ! -f "$changelog_path" ]]; then
  echo "missing changelog: $changelog_path" >&2
  exit 1
fi

latest_version_from_changelog() {
  local line
  line="$(grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+\] - ' "$changelog_path" | head -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "failed to resolve latest version from $changelog_path" >&2
    return 1
  fi
  sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\] - .+$/\1/' <<<"$line"
}

bump_semver() {
  local current="$1"
  local bump_kind="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<<"$current"
  case "$bump_kind" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
    *)
      echo "invalid bump kind: $bump_kind (expected major|minor|patch)" >&2
      return 1
      ;;
  esac
}

resolve_target_version() {
  local parsed=""
  if [[ "$intent" =~ v?([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    parsed="${BASH_REMATCH[1]}"
    echo "$parsed"
    return 0
  fi

  if [[ "$intent" == *"发布新版本"* ]]; then
    if [[ -z "$bump" ]]; then
      echo "intent '发布新版本' requires --bump major|minor|patch" >&2
      return 1
    fi
    local current
    current="$(latest_version_from_changelog)"
    bump_semver "$current" "$bump"
    return 0
  fi

  if [[ "$intent" == *"发布"* && "$intent" == *"v"* ]]; then
    echo "invalid explicit version in intent: $intent" >&2
    return 1
  fi

  echo "unsupported release intent: $intent" >&2
  return 1
}

target_version="$(resolve_target_version)"
release_tag="v${target_version}"
release_notes_path=".agents/out/release-notes-${release_tag}.md"
install_guide_url="https://github.com/${repo}/blob/${release_tag}/.agents/INSTALL.md"

if [[ "$dry_run" == "true" ]]; then
  cat <<EOF
MODE=dry-run
INTENT=${intent}
TARGET_VERSION=${target_version}
RELEASE_TAG=${release_tag}
RELEASE_NOTES_PATH=${release_notes_path}
INSTALL_GUIDE_URL=${install_guide_url}
EOF
  exit 0
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "working tree must be clean before non-dry release run" >&2
  exit 1
fi

tests/run-all.sh

mkdir -p .agents/out
python3 .agents/scripts/generate_release_notes.py \
  --repo "$repo" \
  --version "$target_version" \
  --changelog-path "$changelog_path" > "$release_notes_path"

git add "$changelog_path"
if git diff --cached --quiet; then
  git commit --allow-empty -m "chore(release): ${release_tag}"
else
  git commit -m "chore(release): ${release_tag}"
fi
git tag "${release_tag}"

echo "Release prepared: ${release_tag}"
echo "Release notes: ${release_notes_path}"
