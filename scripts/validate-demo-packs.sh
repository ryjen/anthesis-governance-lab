#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
runner="$repo_root/scripts/run-demo-pack.sh"
catalog="$repo_root/docs/scenarios/demo-catalog.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$runner" && ! -L "$runner" ]] || fail "demo-pack runner must be a regular file"
[[ -f "$catalog" && ! -L "$catalog" ]] || fail "demo catalog must be a regular file"

work_dir="$(mktemp -d "$repo_root/.anthesis/demo-pack-validation.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

mapfile -t packs < <(bash "$runner" --list)
[[ "${#packs[@]}" -gt 0 ]] || fail "demo catalog contains no packs"

passed_packs=0
total_scenarios=0
for pack in "${packs[@]}"; do
  report="$work_dir/$pack.json"
  set +e
  bash "$runner" "$pack" >"$report"
  status=$?
  set -e

  [[ "$status" -eq 0 ]] || fail "demo pack $pack exited $status"
  jq -e '.version == "anthesis.test-report/v1" and .passed == true and .failed_count == 0' \
    "$report" >/dev/null || fail "demo pack $pack did not produce a passing report"

  count="$(jq -er '.total' "$report")"
  [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]] || fail "demo pack $pack has invalid scenario count"
  total_scenarios=$((total_scenarios + count))
  passed_packs=$((passed_packs + 1))
done

expected_packs="$(jq -er '.packs | length' "$catalog")"
expected_scenarios="$(jq -er '[.packs[].scenarios[]] | length' "$catalog")"
[[ "$passed_packs" -eq "$expected_packs" ]] || fail "validated pack count differs from catalog"
[[ "$total_scenarios" -eq "$expected_scenarios" ]] || fail "validated scenario count differs from catalog"

echo "Demo packs: $passed_packs passed, $total_scenarios scenarios passed"
