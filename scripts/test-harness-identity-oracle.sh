#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_fixture="$repo_root/fixtures/external-security/harness-identity-v1.json"
validator="$repo_root/scripts/validate-harness-identity-fixture.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
bash "$validator" >/dev/null
reject_mutation() {
  local label="$1" filter="$2"
  local candidate="$work/$label.json"
  jq "$filter" "$source_fixture" > "$candidate"
  [[ "$(jq -Sc . "$candidate")" != "$(jq -Sc . "$source_fixture")" ]] || {
    echo "mutation did not change fixture: $label" >&2; exit 1;
  }
  if HARNESS_IDENTITY_FIXTURE="$candidate" bash "$validator" >"$work/$label.log" 2>&1; then
    echo "oracle accepted mutated case: $label" >&2; exit 1;
  fi
  echo "rejected: $label"
}
reject_mutation false-green-field-order '
  (.cases[] | select(.id == "observation-order-drift") | .expected) = "qualified"
'
reject_mutation false-green-schema '
  (.cases[] | select(.id == "tool-schema-drift") | .expected) = "qualified"
'
reject_mutation false-green-catalog '
  (.cases[] | select(.id == "tool-catalog-drift") | .expected) = "qualified"
'
reject_mutation evaluator-tamper-promoted '
  (.cases[] | select(.id == "evaluator-tamper") | .expected) = "qualified"
'
reject_mutation substituted-evidence-promoted '
  (.cases[] | select(.id == "evidence-substitution") | .expected) = "qualified"
'
reject_mutation interrupted-promoted '
  (.cases[] | select(.id == "interrupted-recovery") | .expected) = "qualified"
'
reject_mutation unauthorized-effect-laundered '
  (.cases[] | select(.id == "unauthorized-effect-witness") | .expected) = "qualified"
'
reject_mutation missing-positive '
  .cases |= map(select(.id != "authorized-positive"))
'
echo "harness identity oracle mutation regressions passed (8 rejected)"
