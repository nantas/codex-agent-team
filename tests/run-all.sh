#!/usr/bin/env bash
set -euo pipefail

fixtures=(
  "basic-happy-path"
  "role-override-path"
  "checkpoint-path"
  "recovery-prep-path"
)

pass_count=0
fail_count=0

for fixture in "${fixtures[@]}"; do
  echo "==> Running fixture: $fixture"
  if ! run_dir="$(tests/run-fixture.sh "$fixture")"; then
    echo "FAIL $fixture: fixture run failed"
    fail_count=$((fail_count + 1))
    continue
  fi

  if ! tests/collect-artifacts.sh "$run_dir" >/dev/null; then
    echo "FAIL $fixture: artifact collection failed"
    fail_count=$((fail_count + 1))
    continue
  fi

  if python3 tests/assert-fixture.py --fixture "$fixture" --run-dir "$run_dir"; then
    echo "PASS $fixture"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL $fixture: assertions failed"
    fail_count=$((fail_count + 1))
  fi
done

echo "Summary: pass=$pass_count fail=$fail_count total=${#fixtures[@]}"
if [[ $fail_count -ne 0 ]]; then
  exit 1
fi
