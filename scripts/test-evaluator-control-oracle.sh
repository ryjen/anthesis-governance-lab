#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_fixture="$repo_root/fixtures/external-security/evaluator-control-task-v1.json"
validator="$repo_root/scripts/validate-evaluator-control-fixtures.sh"
fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$source_fixture" && ! -L "$source_fixture" ]] || fail "missing source fixture"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
case_index=0
expect_rejected() {
  local label="$1" filter="$2" mutated="$work_dir/fixture.json"
  jq "$filter" "$source_fixture" > "$mutated" || fail "cannot generate $label"
  if bash "$validator" "$mutated" >"$work_dir/out" 2>"$work_dir/err"; then
    fail "$label mutation was incorrectly accepted"
  fi
  grep -Fq 'evaluator-control task fixture invariants failed' "$work_dir/err" || \
    fail "$label failed for an unexpected reason"
  case_index=$((case_index + 1))
}

expect_rejected "forged treatment raw score" '(.cases[] | select(.id == "real-mechanism-treatment") | .expected.raw_correct) = 9'
expect_rejected "overcapable evaluator control hidden" '(.cases[] | select(.id == "overcapable-evaluator-confounder") | .control_predictions) = [false,false,false,false,false,false,false,false,false,false]'
expect_rejected "unmatched comparator relabeled as matched" '(.cases[] | select(.id == "unmatched-control-population") | .conditions_matched) = true'
expect_rejected "missing control silently omitted" '(.cases[] | select(.id == "real-mechanism-treatment") | .control_predictions) = null'
expect_rejected "weakened specification promoted" '(.cases[] | select(.id == "proof-of-weakened-specification") | .source_requirement_covered) = true'
expect_rejected "always-pass mistaken for valid evaluator" '(.cases[] | select(.id == "always-pass-imbalanced-task") | .expected.attribution) = "SUPPORTED"'
expect_rejected "required case deleted" 'del(.cases[] | select(.id == "missing-independent-control"))'
echo "Evaluator control-task mutation oracle: $case_index negative mutations rejected"
