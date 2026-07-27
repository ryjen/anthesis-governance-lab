#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
binary="${ANTHESIS_LAB_BIN:-$repo_root/.anthesis/bin/anthesis-lab}"

fail() { echo "error: $*" >&2; exit 1; }
require_json_value() {
  local file=$1 filter=$2 expected=$3 actual
  actual="$(jq -r "if ($filter) == null then \"__ANTHESIS_MISSING__\" else ($filter | tostring) end" "$file")" || \
    fail "invalid JSON report: $file"
  [[ "$actual" != '__ANTHESIS_MISSING__' ]] || fail "missing JSON field: $filter"
  [[ "$actual" == "$expected" ]] || fail "$filter expected $expected, got $actual"
}

[[ -x "$binary" ]] || fail "verified anthesis-lab binary not found: $binary"
command -v jq >/dev/null || fail "jq is required for report assertions"

work_dir="$(mktemp -d "$repo_root/.anthesis/validation.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
version_report="$work_dir/version.json"
test_report="$work_dir/test.json"
mismatch_report="$work_dir/mismatch.json"

"$binary" version --format json >"$version_report"
require_json_value "$version_report" '.name' 'anthesis-lab'
for contract in \
  anthesis.policy/v1 \
  anthesis.lab-profile/v1 \
  anthesis.scenario/v1 \
  anthesis.decision/v1
do
  jq -e --arg contract "$contract" '.supported_contracts | index($contract) != null' \
    "$version_report" >/dev/null || fail "unsupported public contract: $contract"
done

set +e
"$binary" test --repo "$repo_root" --format json >"$test_report"
test_status=$?
set -e
if [[ "$test_status" -ne 0 ]]; then
  if [[ -s "$test_report" ]]; then
    jq . "$test_report" >&2 || cat "$test_report" >&2
  fi
  fail "canonical suite exited $test_status"
fi
require_json_value "$test_report" '.version' 'anthesis.test-report/v1'
require_json_value "$test_report" '.passed' 'true'
require_json_value "$test_report" '.total' '7'
require_json_value "$test_report" '.passed_count' '7'
require_json_value "$test_report" '.failed_count' '0'
jq -e '.scenarios | length == 7 and all(.passed == true)' "$test_report" >/dev/null || \
  fail "canonical scenario results are incomplete or failed"

fixture="$work_dir/mismatch-fixture"
mkdir -p "$fixture/.anthesis"
cp -R "$repo_root/.anthesis/policies" "$fixture/.anthesis/policies"
cp -R "$repo_root/.anthesis/scenarios" "$fixture/.anthesis/scenarios"
cp "$repo_root/.anthesis/runtime-profile.yaml" "$fixture/.anthesis/runtime-profile.yaml"
scenario="$fixture/.anthesis/scenarios/01-allowed-docs-edit.yaml"
[[ -f "$scenario" && ! -L "$scenario" ]] || fail "unsafe mismatch fixture scenario"
sed -i '0,/decision: allow/s//decision: deny/' "$scenario"
grep -Fq 'decision: deny' "$scenario" || fail "could not create mismatch expectation"

set +e
"$binary" test --repo "$fixture" --format json >"$mismatch_report"
mismatch_status=$?
set -e
if [[ "$mismatch_status" -ne 7 ]]; then
  if [[ -s "$mismatch_report" ]]; then
    jq . "$mismatch_report" >&2 || cat "$mismatch_report" >&2
  fi
  fail "intentional mismatch exited $mismatch_status, expected 7"
fi
require_json_value "$mismatch_report" '.version' 'anthesis.test-report/v1'
require_json_value "$mismatch_report" '.passed' 'false'
require_json_value "$mismatch_report" '.total' '7'
require_json_value "$mismatch_report" '.passed_count' '6'
require_json_value "$mismatch_report" '.failed_count' '1'
jq -e '.scenarios[] | select(.scenario_id == "01-allowed-docs-edit") | .passed == false and (.mismatches | length > 0)' \
  "$mismatch_report" >/dev/null || fail "mismatch report did not identify scenario 01"

echo "Canonical suite: 7 passed, 0 failed"
echo "Intentional governance drift: detected with exit code 7"
