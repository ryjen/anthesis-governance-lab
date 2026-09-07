#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
template="$repo_root/.anthesis/evaluation/scorecard.yaml"
example="$repo_root/.anthesis/evaluation/results.example.yaml"
catalog="$repo_root/docs/scenarios/catalog.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

for file in "$template" "$example" "$catalog"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "evaluation input must be a regular file: $file"
done

jq -e '
  .version == "anthesis-governance-lab.evaluation-scorecard/v1" and
  .synthetic_example == false and
  .primary_outcome.target_minimum == 4 and
  .primary_outcome.governance_decision_confidence == null and
  (.canonical_scenarios | length == 7) and
  .technical_correctness.false_negative_allows == null and
  .environment.runtime_identity == "replace-me" and
  .environment.model_identity_status == "not-applicable-no-live-model|recorded" and
  .environment.model_identity == null and
  .technical_correctness.model_identity_status_explicit == null and
  (.assurance_dimensions | keys == ["attribution", "auditability", "bypass_resistance", "enforceability", "human_approval", "least_privilege"]) and
  (.disposition.result == "proceed-to-real-workflow|needs-fix|stop")
' "$template" >/dev/null || fail "evaluation scorecard template contract is invalid"

jq -e '
  .version == "anthesis-governance-lab.evaluation-scorecard/v1" and
  .synthetic_example == true and
  (.primary_outcome.governance_decision_confidence >= 1 and .primary_outcome.governance_decision_confidence <= 5) and
  (.canonical_scenarios | length == 7) and
  all(.canonical_scenarios[]; .matched == true and .observed_decision == .expected_decision) and
  .environment.runtime_identity == "reference-runtime:tool-wrapper" and
  .environment.model_identity_status == "not-applicable-no-live-model" and
  .environment.model_identity == null and
  .reference_trial.governed_effect_mutated == true and
  .reference_trial.raw_writer_bypass_hard_denied == true and
  .reference_trial.raw_writer_state_unchanged == true and
  .reference_trial.out_of_scope_write_hard_denied == true and
  .reference_trial.out_of_scope_state_unchanged == true and
  .technical_correctness.false_negative_allows == 0 and
  .technical_correctness.model_identity_status_explicit == true and
  (.disposition.result | IN("proceed-to-real-workflow", "needs-fix", "stop"))
' "$example" >/dev/null || fail "evaluation result example contract is invalid"

jq -s -e '
  (.[0].collections.canonical.scenarios | map({id, expected_decision})) ==
    (.[1].canonical_scenarios | map({id, expected_decision})) and
  (.[0].collections.canonical.scenarios | map({id, expected_decision})) ==
    (.[2].canonical_scenarios | map({id, expected_decision}))
' "$catalog" "$template" "$example" >/dev/null || fail "evaluation scenarios drifted from the canonical catalog"

grep -Fq 'docs/reference-trial.md' "$repo_root/README.md" || fail "README does not link the executable reference trial"
grep -Fq 'docs/evaluation.md' "$repo_root/README.md" || fail "README does not link design-partner evaluation"
grep -Fq 'The executable reference trial is intentionally different' "$repo_root/README.md" || fail "README does not distinguish synthetic evaluator surfaces from the executable reference trial"
grep -Fq 'does **not** persist an approval and then execute the approved effect' "$repo_root/docs/evaluation.md" || fail "evaluation guide overstates approval execution coverage"
grep -Fq 'not-applicable-no-live-model' "$repo_root/docs/evaluation.md" || fail "evaluation guide does not make model identity status explicit"

echo "Evaluation scorecard and hand-off boundary validation passed"
