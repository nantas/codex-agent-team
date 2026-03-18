#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: tests/collect-artifacts.sh <run-dir>" >&2
}

if [[ $# -ne 1 ]]; then
  usage
  exit 1
fi

run_dir="$1"
if [[ "$run_dir" != /* ]]; then
  run_dir="$(cd "$run_dir" && pwd)"
fi

if [[ ! -d "$run_dir" ]]; then
  echo "Run directory not found: $run_dir" >&2
  exit 1
fi

metadata_path="$run_dir/run-metadata.json"
state_dir="$run_dir/workspace/.codex/multi-agent"
session_dir="$run_dir/session"
artifacts_dir="$run_dir/artifacts"
fs_dest="$artifacts_dir/filesystem/multi-agent"
session_dest="$artifacts_dir/session-logs"

if [[ ! -f "$metadata_path" ]]; then
  echo "Missing run metadata: $metadata_path" >&2
  exit 1
fi

if [[ ! -d "$state_dir" ]]; then
  echo "Missing workflow state directory: $state_dir" >&2
  exit 1
fi

if [[ ! -d "$session_dir" ]]; then
  echo "Missing session directory: $session_dir" >&2
  exit 1
fi

rm -rf "$artifacts_dir"
mkdir -p "$fs_dest" "$session_dest"

cp -R "$state_dir"/. "$fs_dest"/
cp -R "$session_dir"/. "$session_dest"/

fixture="$(python3 - "$metadata_path" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
print(data["fixture"])
PY
)"

fs_files=()
while IFS= read -r path; do
  fs_files+=("$path")
done < <(find "$fs_dest" -type f | sort)

session_files=()
while IFS= read -r path; do
  session_files+=("$path")
done < <(find "$session_dest" -type f | sort)

markers=()
while IFS= read -r marker; do
  markers+=("$marker")
done < <(grep -h '^\[marker\] ' "$session_dest"/*.log 2>/dev/null | sed 's/^\[marker\] //' | sort -u)

manifest_files_path="$artifacts_dir/manifest-files.txt"
: >"$manifest_files_path"
for path in "${fs_files[@]}" "${session_files[@]}"; do
  if [[ -n "$path" ]]; then
    python3 - "$run_dir" "$path" <<'PY' >>"$manifest_files_path"
import sys
from pathlib import Path
run_dir = Path(sys.argv[1])
path = Path(sys.argv[2])
print(path.relative_to(run_dir).as_posix())
PY
  fi
done

json_array() {
  python3 - "$run_dir" "$@" <<'PY'
import json
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
items = [Path(p).relative_to(run_dir).as_posix() for p in sys.argv[2:] if p]
print(json.dumps(items))
PY
}

markers_json="$(python3 - "${markers[@]}" <<'PY'
import json
import sys
print(json.dumps(sys.argv[1:]))
PY
)"

fs_json="$(json_array "${fs_files[@]}")"
session_json="$(json_array "${session_files[@]}")"

cat >"$artifacts_dir/manifest.json" <<EOF
{
  "fixture": "$fixture",
  "run_dir": "$run_dir",
  "manifest_generated_at": "$(date -u +%Y%m%dT%H%M%SZ)",
  "evidence": {
    "filesystem": {
      "root": "artifacts/filesystem/multi-agent",
      "files": $fs_json
    },
    "session_logs": {
      "root": "artifacts/session-logs",
      "files": $session_json
    }
  },
  "phase_markers": $markers_json,
  "must_not_happen_markers": []
}
EOF

printf '%s\n' "$artifacts_dir"
