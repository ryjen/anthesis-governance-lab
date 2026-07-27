#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
binary="${ANTHESIS_LAB_BIN:-$repo_root/.anthesis/bin/anthesis-lab}"

fail() { echo "error: $*" >&2; exit 1; }
[[ -x "$binary" ]] || fail "verified anthesis-lab binary not found: $binary"
command -v jq >/dev/null || fail "jq is required"

work_dir="$(mktemp -d "$repo_root/.anthesis/inference-integrity.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

json_a="$work_dir/report-a.json"
json_b="$work_dir/report-b.json"
yaml_report="$work_dir/report.yaml"

"$binary" inference-integrity --repo "$repo_root" --format json >"$json_a"
"$binary" inference-integrity --repo "$repo_root" --format json >"$json_b"
cmp -s "$json_a" "$json_b" || fail "JSON report is not deterministic"

jq -e '
  .version == "anthesis.inference-integrity-report/v1alpha1" and
  .passed == true and
  .total == 16 and
  .passed_count == 16 and
  .failed_count == 0 and
  (.scenarios | length == 16 and all(.[]; .passed == true))
' "$json_a" >/dev/null || fail "canonical inference-integrity report is invalid"

"$binary" inference-integrity --repo "$repo_root" --format yaml >"$yaml_report"
grep -Fq 'version: anthesis.inference-integrity-report/v1alpha1' "$yaml_report" || \
  fail "YAML report version is missing"
grep -Fq 'passed: true' "$yaml_report" || fail "YAML report did not pass"

fixture="$work_dir/mismatch"
mkdir -p "$fixture/fixtures/inference-integrity"
cp "$repo_root/fixtures/inference-integrity/scenario-suite-v1alpha1.yaml" \
  "$fixture/fixtures/inference-integrity/"
cp "$repo_root/fixtures/inference-integrity/fixtures-v1alpha1.json" \
  "$fixture/fixtures/inference-integrity/"
sed -i '0,/policy_posture: allow/s//policy_posture: fail_closed/' \
  "$fixture/fixtures/inference-integrity/scenario-suite-v1alpha1.yaml"

set +e
"$binary" inference-integrity --repo "$fixture" --format json >"$work_dir/mismatch.json"
status=$?
set -e
[[ "$status" -eq 7 ]] || fail "expectation mismatch exited $status, expected 7"
jq -e '.passed == false and .failed_count == 1' "$work_dir/mismatch.json" >/dev/null || \
  fail "expectation mismatch report is invalid"

echo "Inference-integrity executable suite: 16 passed; mismatch exit 7 verified"
