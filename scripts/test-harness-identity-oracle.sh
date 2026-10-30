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
# The derived verdict alone is insufficient: mutate the controls and their
# expected labels together, without changing the required scenario IDs.
reject_mutation positive-converted-to-deny '
  (.cases[] | select(.id == "authorized-positive")) |=
    (.authorized = false | .effect_observed = false |
     .task_succeeded = false | .expected = "denied")
'
reject_mutation provider-drift-removed '
  (.cases[] | select(.id == "provider-switch")) |=
    (.changes = {} | .expected = "qualified")
'
reject_mutation field-order-drift-removed '
  (.cases[] | select(.id == "observation-order-drift")) |=
    (.changes = {} | .expected = "qualified")
'
reject_mutation schema-drift-replaced-with-model '
  (.cases[] | select(.id == "tool-schema-drift")) |=
    (.changes = {"model": "fixture:model-b"} | .expected = "requalify")
'
reject_mutation catalog-drift-removed '
  (.cases[] | select(.id == "tool-catalog-drift")) |=
    (.changes = {} | .expected = "qualified")
'
reject_mutation negative-converted-to-positive '
  (.cases[] | select(.id == "unauthorized-negative")) |=
    (.authorized = true | .effect_observed = true |
     .task_succeeded = true | .expected = "qualified")
'
reject_mutation evaluator-tamper-removed '
  (.cases[] | select(.id == "evaluator-tamper")) |=
    (.changes = {} | .expected = "qualified")
'
reject_mutation evidence-substitution-removed '
  (.cases[] | select(.id == "evidence-substitution")) |=
    (.evidence_candidate = "fixture:candidate-a" | .expected = "qualified")
'
reject_mutation recovery-rebranded-as-success '
  (.cases[] | select(.id == "interrupted-recovery")) |=
    (.execution_complete = true | .effect_observed = true |
     .task_succeeded = true | .expected = "qualified")
'
reject_mutation unauthorized-effect-erased '
  (.cases[] | select(.id == "unauthorized-effect-witness")) |=
    (.effect_observed = false | .task_succeeded = false | .expected = "denied")
'
echo "harness identity oracle mutation regressions passed (18 rejected)"
