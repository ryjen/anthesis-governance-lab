#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
binary="${ANTHESIS_LAB_BIN:-$repo_root/.anthesis/bin/anthesis-lab}"
output_dir="${1:-$repo_root/.anthesis/evidence/inference-integrity}"

fail() { echo "error: $*" >&2; exit 1; }
[[ -x "$binary" ]] || fail "verified anthesis-lab binary not found: $binary"
command -v jq >/dev/null || fail "jq is required"
command -v sha256sum >/dev/null || fail "sha256sum is required"

case "$output_dir" in
  "$repo_root"/*) ;;
  *) fail "output directory must remain inside the repository workspace" ;;
esac

rm -rf "$output_dir"
mkdir -p "$output_dir"
work_dir="$(mktemp -d "$repo_root/.anthesis/evidence-work.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

pass_json="$output_dir/passing-report.json"
pass_yaml="$output_dir/passing-report.yaml"
mismatch_json="$output_dir/mismatch-report.json"

"$binary" inference-integrity --repo "$repo_root" --format json >"$pass_json"
"$binary" inference-integrity --repo "$repo_root" --format yaml >"$pass_yaml"

jq -e '
  .version == "anthesis.inference-integrity-report/v1alpha1" and
  .passed == true and .total == 16 and .passed_count == 16 and .failed_count == 0
' "$pass_json" >/dev/null || fail "passing JSON report is invalid"

fixture_repo="$work_dir/mismatch"
mkdir -p "$fixture_repo/fixtures/inference-integrity"
cp "$repo_root/fixtures/inference-integrity/scenario-suite-v1alpha1.yaml" \
  "$fixture_repo/fixtures/inference-integrity/"
cp "$repo_root/fixtures/inference-integrity/fixtures-v1alpha1.json" \
  "$fixture_repo/fixtures/inference-integrity/"
sed -i '0,/policy_posture: allow/s//policy_posture: fail_closed/' \
  "$fixture_repo/fixtures/inference-integrity/scenario-suite-v1alpha1.yaml"

set +e
"$binary" inference-integrity --repo "$fixture_repo" --format json >"$mismatch_json"
mismatch_status=$?
set -e
[[ "$mismatch_status" -eq 7 ]] || fail "controlled mismatch exited $mismatch_status, expected 7"
jq -e '.passed == false and .failed_count == 1' "$mismatch_json" >/dev/null || \
  fail "controlled mismatch report is invalid"

anthesis_revision="$(sed -n 's/^ANTHESIS_REVISION=//p' "$repo_root/.anthesis/cli-artifact.env")"
[[ "$anthesis_revision" =~ ^[0-9a-f]{40}$ ]] || fail "invalid Anthesis revision metadata"
governance_lab_revision="$(git -C "$repo_root" rev-parse HEAD)"
[[ "$governance_lab_revision" =~ ^[0-9a-f]{40}$ ]] || fail "invalid Governance Lab revision metadata"

jq -n \
  --arg version "anthesis-governance-lab.inference-integrity-evidence-bundle/v1" \
  --arg anthesis_revision "$anthesis_revision" \
  --arg governance_lab_revision "$governance_lab_revision" \
  --arg suite "fixtures/inference-integrity/scenario-suite-v1alpha1.yaml" \
  --arg fixtures "fixtures/inference-integrity/fixtures-v1alpha1.json" \
  --argjson passing_exit_code 0 \
  --argjson mismatch_exit_code "$mismatch_status" \
  '{
    version: $version,
    synthetic: true,
    contains_real_prompts: false,
    contains_real_secrets: false,
    anthesis_revision: $anthesis_revision,
    governance_lab_revision: $governance_lab_revision,
    suite: $suite,
    fixtures: $fixtures,
    reports: {
      passing_json: {path: "passing-report.json", exit_code: $passing_exit_code},
      passing_yaml: {path: "passing-report.yaml", exit_code: $passing_exit_code},
      controlled_mismatch_json: {path: "mismatch-report.json", exit_code: $mismatch_exit_code}
    }
  }' >"$output_dir/manifest.json"

(
  cd "$output_dir"
  sha256sum manifest.json mismatch-report.json passing-report.json passing-report.yaml >SHA256SUMS
  sha256sum --check SHA256SUMS >/dev/null
)

echo "Inference-integrity evidence bundle written to ${output_dir#$repo_root/}"
