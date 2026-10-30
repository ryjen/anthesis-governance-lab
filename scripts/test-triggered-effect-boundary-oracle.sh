#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_fixture="$repo_root/fixtures/external-security/environmental-influence-v1.json"
validator="$repo_root/scripts/test-triggered-effect-boundary.sh"
work="$(mktemp -d "${TMPDIR:-/tmp}/govlab-trigger-mutations.XXXXXXXX")"
trap 'rm -rf -- "$work"' EXIT
bash "$validator" >/dev/null
reject_mutation() {
  local name="$1" filter="$2" candidate="$work/$1.json"
  jq "$filter" "$source_fixture" >"$candidate"
  [[ "$(jq -Sc . "$candidate")" != "$(jq -Sc . "$source_fixture")" ]] ||
    { echo "mutation did not change case: $name" >&2; exit 1; }
  if TRIGGERED_EFFECT_FIXTURE="$candidate" bash "$validator" >"$work/$name.log" 2>&1; then
    echo "synthetic trigger fixture incorrectly accepted: $name" >&2
    exit 1
  fi
  echo "rejected: $name"
}
reject_mutation deny-rebranded-as-positive '
  (.cases[] | select(.id == "hostile-observation-protected-effect-denied")) |=
    (.requested_effect = "write-benign-report" |
     .action_authorized = true | .expected_decision = "allow" |
     .execution_record_present = true |
     .terminal_state.benign_artifact_present = true)
'
reject_mutation allow-rebranded-as-deny '
  (.cases[] | select(.id == "hostile-observation-benign-objective-succeeds")) |=
    (.requested_effect = "protected-policy-write" |
     .action_authorized = false | .expected_decision = "deny" |
     .execution_record_present = false |
     .terminal_state.benign_artifact_present = false)
'
reject_mutation missing-trigger-observation '
  (.cases[] | select(.id == "hostile-observation-protected-effect-denied") | .hostile_content_present) = false
'
reject_mutation missing-positive '
  .cases |= map(select(.id != "hostile-observation-benign-objective-succeeds"))
'
reject_mutation target-substitution '
  .scenario.protected_target = "report/authorized.txt"
'
reject_mutation spoofed-authority '
  (.cases[] | select(.id == "hostile-observation-protected-effect-denied") | .action_authorized) = true
'
echo 'trigger-to-effect negative mutations passed (6/6 rejected)'
