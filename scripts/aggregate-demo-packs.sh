#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
runner="$repo_root/scripts/run-demo-pack.sh"
catalog="$repo_root/docs/scenarios/demo-catalog.json"

fail() { echo "error: $*" >&2; exit 3; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$runner" && ! -L "$runner" ]] || fail "demo-pack runner must be a regular file"
[[ -f "$catalog" && ! -L "$catalog" ]] || fail "demo catalog must be a regular file"

work_dir="$(mktemp -d "$repo_root/.anthesis/demo-pack-aggregate.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

mapfile -t packs < <(bash "$runner" --list)
[[ "${#packs[@]}" -gt 0 ]] || fail "demo catalog contains no packs"

mismatches=0
invalid=0
passed=0
total_scenarios=0
fragments=()

for pack in "${packs[@]}"; do
  raw_report="$work_dir/$pack.raw.json"
  fragment="$work_dir/$pack.fragment.json"
  fragments+=("$fragment")

  set +e
  bash "$runner" "$pack" >"$raw_report" 2>"$work_dir/$pack.stderr"
  status=$?
  set -e

  classification=invalid
  report_json=null
  scenario_count=0

  if jq -e '.version == "anthesis.test-report/v1" and (.total | type == "number")' \
    "$raw_report" >/dev/null 2>&1; then
    report_json="$(jq -c . "$raw_report")"
    scenario_count="$(jq -r '.total' "$raw_report")"
  fi

  case "$status" in
    0)
      if [[ "$report_json" != null ]] && jq -e '.passed == true and .failed_count == 0' \
        "$raw_report" >/dev/null; then
        classification=passed
        passed=$((passed + 1))
        total_scenarios=$((total_scenarios + scenario_count))
      else
        invalid=$((invalid + 1))
      fi
      ;;
    7)
      if [[ "$report_json" != null ]] && jq -e '.passed == false and .failed_count > 0' \
        "$raw_report" >/dev/null; then
        classification=expectation_mismatch
        mismatches=$((mismatches + 1))
        total_scenarios=$((total_scenarios + scenario_count))
      else
        invalid=$((invalid + 1))
      fi
      ;;
    *)
      invalid=$((invalid + 1))
      ;;
  esac

  jq -n \
    --arg pack_id "$pack" \
    --arg classification "$classification" \
    --argjson exit_code "$status" \
    --argjson report "$report_json" \
    '{pack_id:$pack_id, exit_code:$exit_code, classification:$classification, report:$report}' \
    >"$fragment"
done

expected_packs="$(jq -er '.packs | length' "$catalog")"
[[ "${#packs[@]}" -eq "$expected_packs" ]] || fail "aggregated pack count differs from catalog"

overall_classification=passed
overall_exit=0
if [[ "$invalid" -gt 0 ]]; then
  overall_classification=invalid
  overall_exit=3
elif [[ "$mismatches" -gt 0 ]]; then
  overall_classification=expectation_mismatch
  overall_exit=7
fi

jq -s \
  --arg classification "$overall_classification" \
  --argjson exit_code "$overall_exit" \
  --argjson pack_count "${#packs[@]}" \
  --argjson passed_packs "$passed" \
  --argjson mismatched_packs "$mismatches" \
  --argjson invalid_packs "$invalid" \
  --argjson total_scenarios "$total_scenarios" \
  '{
    version:"anthesis.demo-pack-report/v1",
    classification:$classification,
    exit_code:$exit_code,
    pack_count:$pack_count,
    passed_packs:$passed_packs,
    mismatched_packs:$mismatched_packs,
    invalid_packs:$invalid_packs,
    total_scenarios:$total_scenarios,
    packs:.
  }' "${fragments[@]}"

exit "$overall_exit"
