#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixtures="$root/fixtures/inference-integrity"
fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

check() {
  local file="$1"
  local expr="$2"
  jq -e "$expr" "$fixtures/$file" >/dev/null || fail "final catalog contract failed: $file"
}

check cross-provider-fixed-seed-rejected.json '
  .original_execution.verification_request.requested_capability_class == "fixed_seed" and
  .original_execution.verification_request.capability_class == "semantic_only" and
  .verification_result.comparison.provider_ref != .original_execution.resolved_execution.provider_ref and
  (.verification_result.limitations | index("cross_provider_not_fixed_seed_equivalent") != null) and
  .verification_result.authoritative == false and
  .policy_result.outcome == "require_human_review"'

check semantic-only-provider-check.json '
  .original_execution.verification_request.capability_class == "semantic_only" and
  .verification_result.comparison.fixed_seed_equivalence_claimed == false and
  (.verification_result.limitations | index("semantic_only_no_token_equivalence") != null) and
  .verification_result.authoritative == false and
  .policy_result.outcome == "allow_with_signal"'

check observe-release-before-verification.json '
  .original_execution.verification_request.operating_mode == "observe" and
  .original_execution.release.released_before_verification == true and
  .verification_result.verdict == "suspicious" and
  .verification_result.authoritative == false and
  .policy_result.outcome == "allow_with_signal" and
  .policy_result.recommendation == "increase_sampling"'

check selective-gate-hold-release.json '
  .original_execution.verification_request.operating_mode == "selective_gate" and
  .original_execution.release.held_pending_verification == true and
  .original_execution.release.released_after_conformant_verification == true and
  .verification_result.verdict == "conformant" and
  .verification_result.authoritative == false and
  .policy_result.release_authorized == true and
  .policy_result.outcome == "allow"'

check required-gate-verifier-outage.json '
  .original_execution.verification_request.operating_mode == "required_gate" and
  .original_execution.release.held_pending_verification == true and
  .original_execution.release.released == false and
  .verification_result.availability == "unavailable" and
  (.verification_result.limitations | index("verifier_outage") != null) and
  .verification_result.verdict == "indeterminate" and
  .policy_result.release_authorized == false and
  .policy_result.outcome == "require_human_review"'

check policy-approved-recovery.json '
  .verification_result.verdict == "conformant" and
  .verification_result.authoritative == false and
  .policy_result.recovery.previous_state == "suspended" and
  .policy_result.recovery.requested_state == "active" and
  .policy_result.recovery.policy_approved == true and
  (.policy_result.recovery.operator_approval_ref | startswith("approval:")) and
  .policy_result.recovery.automatic_reactivation == false and
  .policy_result.authority == "phloem-calyx-policy-plane"'

[[ "$(jq '.fixtures | length' "$fixtures/manifest.json")" -eq 24 ]] || fail "final catalog must contain 24 fixtures"

echo "Inference-integrity final 24-scenario catalog validation passed"
