#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
catalog="$repo_root/.anthesis/scenarios/inference-integrity/catalog.json"
manifest="$repo_root/fixtures/inference-integrity/manifest.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$catalog" && ! -L "$catalog" ]] || fail "scenario catalog must be a regular file"
[[ -f "$manifest" && ! -L "$manifest" ]] || fail "fixture manifest must be a regular file"

jq -e '
  .version == "anthesis-governance-lab.inference-integrity-scenario-catalog/v0" and
  .status == "blocked_pending_canonical_contract" and
  .canonical_authority == "hackelia-micrantha/anthesis#108" and
  .fixture_manifest == "fixtures/inference-integrity/manifest.json" and
  .scenario_count == 24 and
  .executable == false and
  .exit_code_contract == "pending_anthesis_108" and
  .declared_expectations == ["verification_class", "operating_mode", "expected_verdict", "expected_policy_outcome"] and
  (.scenarios | length == 24) and
  ([.scenarios[].number] == [range(1;25)]) and
  ([.scenarios[].id] | length == (unique | length)) and
  ([.scenarios[].fixture_id] | length == (unique | length)) and
  ([.scenarios[].future_path] | length == (unique | length)) and
  all(.scenarios[];
    (.id | type == "string" and length > 0) and
    (.fixture_id | type == "string" and length > 0) and
    (.future_path | startswith(".anthesis/scenarios/inference-integrity/") and endswith(".yaml") and (contains("..") | not)) and
    ((.issue_aliases // []) | type == "array" and all(.[]; type == "string" and length > 0))
  )
' "$catalog" >/dev/null || fail "inference scenario catalog contract is invalid"

mapfile -t catalog_fixture_ids < <(jq -r '.scenarios[].fixture_id' "$catalog" | sort)
mapfile -t manifest_fixture_ids < <(jq -r '.fixtures[].id' "$manifest" | sort)
[[ "${catalog_fixture_ids[*]}" == "${manifest_fixture_ids[*]}" ]] || fail "scenario catalog must map every fixture exactly once"

while IFS=$'\t' read -r fixture_id fixture_path expected_class expected_verdict expected_outcome; do
  fixture="$repo_root/$fixture_path"
  [[ -f "$fixture" && ! -L "$fixture" ]] || fail "missing mapped fixture: $fixture_id"
  jq -e \
    --arg class "$expected_class" \
    --arg verdict "$expected_verdict" \
    --arg outcome "$expected_outcome" '
      .original_execution.verification_request.capability_class == $class and
      (.original_execution.verification_request.operating_mode | IN("observe", "selective_gate", "required_gate")) and
      .verification_result.verdict == $verdict and
      .policy_result.outcome == $outcome
    ' "$fixture" >/dev/null || fail "mapped fixture declarations disagree: $fixture_id"
done < <(jq -r '.fixtures[] | [.id,.path,.verification_class,.expected_verdict,.expected_outcome] | @tsv' "$manifest")

while IFS= read -r future_path; do
  [[ ! -e "$repo_root/$future_path" ]] || fail "blocked skeleton must not claim executable scenario file: $future_path"
done < <(jq -r '.scenarios[].future_path' "$catalog")

echo "Inference-integrity scenario catalog skeleton validation passed"
