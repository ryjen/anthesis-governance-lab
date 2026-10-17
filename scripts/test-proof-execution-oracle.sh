#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_fixture="$repo_root/fixtures/external-security/proof-execution-replay-v1.json"
validator="$repo_root/scripts/validate-proof-execution-fixtures.sh"

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
  grep -Fq 'proof-of-execution replay fixture invariants failed' "$work_dir/err" || \
    fail "$label failed for an unexpected reason"
  case_index=$((case_index + 1))
}

expect_rejected "false verified claim" '(.cases[] | select(.id == "governed-exact-effect") | .expected.history) = "REJECTED"'
expect_rejected "unobserved alternate credential mutation" '(.cases[] | select(.id == "governed-exact-effect") | .observed_action) = "beta"'
expect_rejected "deleted commit receipt" '(.cases[] | select(.id == "governed-exact-effect") | .recorded_events) = ["allow:alpha", "dispatch:alpha"]'
expect_rejected "missing declared replay dependency hidden" '(.cases[] | select(.id == "declared-replay-dependency-missing") | .available_dependencies) = ["policy:v1", "runtime:v1"]'
expect_rejected "revoked fresh authorization" '(.cases[] | select(.id == "new-authority-required-for-followon") | .current_authority_revoked) = true'
expect_rejected "absent required case" 'del(.cases[] | select(.id == "independent-witness-unavailable"))'

echo "Proof-of-execution mutation oracle: $case_index negative mutations rejected"
