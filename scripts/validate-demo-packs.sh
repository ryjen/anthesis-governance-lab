#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
aggregator="$repo_root/scripts/aggregate-demo-packs.sh"
catalog="$repo_root/docs/scenarios/demo-catalog.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$aggregator" && ! -L "$aggregator" ]] || fail "demo-pack aggregator must be a regular file"
[[ -f "$catalog" && ! -L "$catalog" ]] || fail "demo catalog must be a regular file"

work_dir="$(mktemp -d "$repo_root/.anthesis/demo-pack-validation.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
report="$work_dir/demo-packs.json"

set +e
bash "$aggregator" >"$report"
status=$?
set -e
[[ "$status" -eq 0 ]] || fail "demo-pack aggregate exited $status"

expected_packs="$(jq -er '.packs | length' "$catalog")"
expected_scenarios="$(jq -er '[.packs[].scenarios[]] | length' "$catalog")"

jq -e \
  --argjson expected_packs "$expected_packs" \
  --argjson expected_scenarios "$expected_scenarios" \
  '.version == "anthesis.demo-pack-report/v1" and
   .classification == "passed" and
   .exit_code == 0 and
   .pack_count == $expected_packs and
   .passed_packs == $expected_packs and
   .mismatched_packs == 0 and
   .invalid_packs == 0 and
   .total_scenarios == $expected_scenarios and
   (.packs | length == $expected_packs) and
   all(.packs[];
     .exit_code == 0 and
     .classification == "passed" and
     .report.version == "anthesis.test-report/v1" and
     .report.passed == true and
     .report.failed_count == 0
   )' "$report" >/dev/null || fail "aggregate demo-pack report is invalid or incomplete"

if grep -Fq "$repo_root" "$report"; then
  fail "aggregate demo-pack report contains an absolute repository path"
fi

echo "Demo packs: $expected_packs passed, $expected_scenarios scenarios passed"
