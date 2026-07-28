#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
catalog="$repo_root/.anthesis/catalogs/inference-integrity-scenarios.json"
suite="$repo_root/fixtures/inference-integrity/scenario-suite-v1alpha1.yaml"
fixtures="$repo_root/fixtures/inference-integrity/fixtures-v1alpha1.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
for path in "$catalog" "$suite" "$fixtures"; do
  [[ -f "$path" && ! -L "$path" ]] || fail "contract must be a regular file: ${path#$repo_root/}"
done

jq -e '
  .version == "anthesis-governance-lab.inference-integrity-scenario-catalog/v1" and
  .status == "executable_fixture_contract" and
  .canonical_authority == "hackelia-micrantha/anthesis#108" and
  .suite == "fixtures/inference-integrity/scenario-suite-v1alpha1.yaml" and
  .fixtures == "fixtures/inference-integrity/fixtures-v1alpha1.json" and
  .scenario_count == 24 and
  .executable == true and
  .execution_mode == "fixture_only" and
  .requirements == {gpu:false, network:false, live_model:false} and
  .report_contract == "anthesis.inference-integrity-report/v1alpha1" and
  .exit_codes == {success:0, invalid_input:3, expectation_mismatch:7, unsupported_version:8} and
  .declared_expectations == ["verdict", "capability_class", "policy_posture"] and
  (.scenarios | length == 24) and
  ([.scenarios[].number] == [range(1;25)]) and
  ([.scenarios[].id] | length == (unique | length)) and
  ([.scenarios[].fixture_key] | length == (unique | length)) and
  all(.scenarios[];
    (.id | type == "string" and length > 0) and
    (.fixture_key | type == "string" and length > 0)
  )
' "$catalog" >/dev/null || fail "inference scenario catalog contract is invalid"

mapfile -t catalog_ids < <(jq -r '.scenarios[].id' "$catalog")
mapfile -t catalog_fixture_keys < <(jq -r '.scenarios[].fixture_key' "$catalog")
mapfile -t suite_ids < <(sed -n 's/^  - id: //p' "$suite")
mapfile -t suite_fixture_keys < <(sed -n 's/^    fixture_key: //p' "$suite")

[[ "${#suite_ids[@]}" -eq 24 ]] || fail "canonical suite must contain 24 scenario IDs"
[[ "${#suite_fixture_keys[@]}" -eq 24 ]] || fail "canonical suite must contain 24 fixture keys"
[[ "${catalog_ids[*]}" == "${suite_ids[*]}" ]] || fail "catalog scenario order must match canonical suite"
[[ "${catalog_fixture_keys[*]}" == "${suite_fixture_keys[*]}" ]] || fail "catalog fixture mapping must match canonical suite"

mapfile -t fixture_keys < <(jq -r '.fixtures | keys[]' "$fixtures" | sort)
mapfile -t catalog_fixture_keys_sorted < <(jq -r '.scenarios[].fixture_key' "$catalog" | sort)
[[ "${catalog_fixture_keys_sorted[*]}" == "${fixture_keys[*]}" ]] || \
  fail "catalog must map every canonical fixture exactly once"

jq -e '
  .version == "anthesis.inference-integrity-fixtures/v1alpha1" and
  (.fixtures | type == "object" and length == 24)
' "$fixtures" >/dev/null || fail "canonical fixture contract is invalid"

echo "Inference-integrity executable 24-case catalog validation passed"
