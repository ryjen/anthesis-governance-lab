#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/verifier-collapse-controls-v1.json"
validator="$root/scripts/validate-verifier-collapse-controls.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
count=0
reject() {
  local label="$1" mutation="$2"
  jq "$mutation" "$source" > "$work/fixture.json"
  if bash "$validator" "$work/fixture.json" >"$work/out" 2>"$work/err"; then
    echo "mutation accepted: $label" >&2; exit 1
  fi
  grep -Fq "verifier control fixture invariants failed" "$work/err"
  count=$((count+1))
}
reject "always-pass grader promoted" '(.cases[] | select(.id == "always-pass-known-bad") | .expected_validity) = "VALID"'
reject "known-bad oracle corrupted" '(.cases[] | select(.id == "always-pass-known-bad") | .expected_verdict) = "pass"'
reject "abstain collapsed to pass" '(.cases[] | select(.id == "anchored-abstain") | .actual_verdict) = "pass"'
reject "generic auditor promoted" '(.cases[] | select(.id == "generic-auditor-rejects-valid-tag") | .expected_validity) = "VALID"'
reject "missing numeric tag accepted" '(.cases[] | select(.id == "contract-aware-rejects-missing-value") | .actual_verdict) = "pass"'
reject "oracle exposed for selection" '.grader_selection_feedback_exposes_oracle = true'
reject "required control removed" 'del(.cases[] | select(.id == "always-pass-abstain"))'
echo "Verifier-control mutation oracle: $count negative mutations rejected"
