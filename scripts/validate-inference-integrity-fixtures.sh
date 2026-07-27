#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture_root="$repo_root/fixtures/inference-integrity"
manifest="$fixture_root/manifest.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$manifest" && ! -L "$manifest" ]] || fail "fixture manifest must be a regular file"

jq -e '
  .version == "anthesis-governance-lab.inference-integrity-fixtures/v0" and
  .status == "provisional" and
  .canonical_authority == "hackelia-micrantha/anthesis#108" and
  .gateway_dependency == "ryjen/dubnium#379" and
  .live_replay_dependency == "ryjen/dubnium#381" and
  .executable_with_anthesis_lab == false and
  .contains_real_prompts == false and
  .contains_real_secrets == false and
  (.fixtures | length > 0) and
  ([.fixtures[].id] | length == (unique | length)) and
  ([.fixtures[].path] | length == (unique | length)) and
  all(.fixtures[];
    (.id | type == "string" and length > 0) and
    (.path | startswith("fixtures/inference-integrity/") and endswith(".json") and (contains("..") | not)) and
    (.path != "fixtures/inference-integrity/manifest.json") and
    (.purpose | type == "string" and length > 0) and
    (.verification_class | IN("fixed_seed", "bounded_consistency", "semantic_only", "governance_only", "unsupported")) and
    (.expected_verdict | IN("conformant", "suspicious", "dangerous", "indeterminate")) and
    (.expected_outcome | IN("allow", "allow_with_signal", "increase_sampling", "quarantine_response", "suspend_route", "isolate_runtime", "isolate_specialist", "suspend_model_alias", "require_human_review", "preserve_forensics", "enter_dormancy"))
  )
' "$manifest" >/dev/null || fail "inference-integrity manifest contract is invalid"

mapfile -t manifest_paths < <(jq -r '.fixtures[].path' "$manifest" | sort)
mapfile -t fixture_paths < <(
  cd "$repo_root"
  find fixtures/inference-integrity -maxdepth 1 -type f -name '*.json' ! -name manifest.json -print | sort
)
[[ "${manifest_paths[*]}" == "${fixture_paths[*]}" ]] || fail "fixture manifest and JSON fixture paths differ"

while IFS= read -r path; do
  fixture="$repo_root/$path"
  [[ -f "$fixture" && ! -L "$fixture" ]] || fail "unsafe or missing fixture: $path"
  expected_class="$(jq -er --arg path "$path" '.fixtures[] | select(.path == $path) | .verification_class' "$manifest")"
  expected_verdict="$(jq -er --arg path "$path" '.fixtures[] | select(.path == $path) | .expected_verdict' "$manifest")"
  expected_outcome="$(jq -er --arg path "$path" '.fixtures[] | select(.path == $path) | .expected_outcome' "$manifest")"

  jq -e --arg expected_class "$expected_class" --arg expected_verdict "$expected_verdict" --arg expected_outcome "$expected_outcome" '
    def sha256_ref: type == "string" and test("^sha256:[0-9a-f]{64}$");
    def execution_ref: type == "string" and startswith("execution:") and length > 10;
    def verification_ref: type == "string" and startswith("verification:") and length > 13;
    def route_ref: type == "string" and startswith("route:") and length > 6;
    def complete_identity:
      (.provider_ref | type == "string" and startswith("provider:") and length > 9) and
      (.route_ref | route_ref) and
      (.model_artifact_ref | sha256_ref) and
      (.tokenizer_ref | sha256_ref) and
      (.runtime_build_ref | sha256_ref) and
      (.runtime_profile_ref | sha256_ref) and
      (.prompt_profile_ref | sha256_ref) and
      (.routing_policy_ref | sha256_ref);
    .version == "anthesis-governance-lab.inference-integrity-record/v0" and
    .status == "provisional" and
    .synthetic == true and
    (.original_execution.execution_ref | execution_ref) and
    (.original_execution.gateway_contract_ref == "dubnium-llm-gateway/v1") and
    (.original_execution.requested_model_alias | type == "string" and length > 0) and
    ((.original_execution | has("resolved_execution_complete") | not) or (.original_execution.resolved_execution_complete | type == "boolean")) and
    (((.original_execution | has("resolved_execution_complete")) and .original_execution.resolved_execution_complete == false) or
      (((.original_execution | has("resolved_execution_complete") | not) or .original_execution.resolved_execution_complete == true) and
       (.original_execution.resolved_execution | complete_identity))) and
    (.original_execution.sampling.parameters_digest | sha256_ref) and
    (.original_execution.sampling.seed_commitment | sha256_ref) and
    (.original_execution.sampling.seed_owner | IN("gateway", "runtime")) and
    (.original_execution.output.response_digest | sha256_ref) and
    (.original_execution.output.token_ids_digest | sha256_ref) and
    (.original_execution.verification_request.capability_class == $expected_class) and
    (.original_execution.verification_request.capability_class | IN("fixed_seed", "bounded_consistency", "semantic_only", "governance_only", "unsupported")) and
    (.original_execution.verification_request.operating_mode | IN("observe", "selective_gate", "required_gate")) and
    (.verification_result.original_execution_ref == .original_execution.execution_ref) and
    (.verification_result.verifier.build_ref | sha256_ref) and
    ((.verification_result.verifier.trusted // true) | type == "boolean") and
    (.verification_result.verdict == $expected_verdict) and
    .verification_result.authoritative == false and
    (.policy_result.original_execution_ref == .original_execution.execution_ref) and
    (.policy_result.verification_ref == .verification_result.verification_ref) and
    (.policy_result.outcome == $expected_outcome) and
    .policy_result.authority == "phloem-calyx-policy-plane" and
    (if .case.kind == "runtime_selected_seed" then
       .original_execution.sampling.seed_owner == "runtime" and
       .verification_result.verdict == "indeterminate"
     elif .case.kind == "token_substitution" then
       .verification_result.observations.suspicious_tokens > 0 and
       .verification_result.observations.dangerous_tokens > 0 and
       .policy_result.outcome == "quarantine_response"
     elif .case.kind == "untrusted_verifier" then
       .verification_result.verifier.trusted == false and
       .verification_result.verdict == "indeterminate"
     elif .case.kind == "missing_resolved_identity" then
       .original_execution.resolved_execution_complete == false and
       ([.original_execution.resolved_execution.model_artifact_ref,
         .original_execution.resolved_execution.tokenizer_ref,
         .original_execution.resolved_execution.runtime_build_ref] | any(. == null)) and
       .verification_result.verdict == "indeterminate"
     elif .case.kind == "seed_evidence_rewrite" then
       (.verification_result.observed_seed_commitment | sha256_ref) and
       .verification_result.observed_seed_commitment != .original_execution.sampling.seed_commitment and
       (.verification_result.limitations | index("seed_commitment_mismatch") != null) and
       .policy_result.outcome == "preserve_forensics"
     elif .case.kind == "unsupported_replay_downgrade" then
       .original_execution.verification_request.requested_capability_class == "fixed_seed" and
       .original_execution.verification_request.capability_class == "unsupported" and
       (.verification_result.limitations | index("deterministic_replay_unsupported") != null) and
       .verification_result.verdict == "indeterminate"
     elif .case.kind == "unverifiable_fallback" then
       .original_execution.routing.verification_required == true and
       .original_execution.routing.initial_route_ref != .original_execution.routing.fallback_route_ref and
       .original_execution.routing.fallback_route_ref == .original_execution.resolved_execution.route_ref and
       .original_execution.routing.fallback_verification_class == "unsupported" and
       .original_execution.verification_request.capability_class == "unsupported" and
       (.verification_result.limitations | index("fallback_route_unverifiable") != null) and
       .policy_result.outcome == "suspend_route"
     elif .case.kind == "plano_route_change" then
       (.original_execution.routing.planned_route_ref | route_ref) and
       (.original_execution.routing.resolved_route_ref | route_ref) and
       .original_execution.routing.planned_route_ref != .original_execution.routing.resolved_route_ref and
       .original_execution.routing.resolved_route_ref == .original_execution.resolved_execution.route_ref and
       .original_execution.routing.change_approved == false and
       (.verification_result.limitations | index("unapproved_route_change") != null) and
       .policy_result.outcome == "suspend_route"
     elif .case.kind == "specialist_tamper" then
       (.original_execution.topology.parent_execution_ref | execution_ref) and
       .original_execution.topology.role == "specialist" and
       (.original_execution.topology.specialist_ref | startswith("specialist:")) and
       (.original_execution.topology.sibling_execution_refs | length > 0 and all(.[]; execution_ref)) and
       .verification_result.localization.execution_ref == .original_execution.execution_ref and
       .verification_result.localization.specialist_ref == .original_execution.topology.specialist_ref and
       .verification_result.localization.parent_conformant == true and
       .verification_result.localization.siblings_conformant == true and
       .policy_result.outcome == "isolate_specialist"
     elif .case.kind == "synthesis_tamper" then
       .original_execution.topology.role == "supervisor" and
       (.original_execution.topology.subrun_refs | length >= 2 and all(.[]; execution_ref)) and
       (.original_execution.topology.synthesis_input_digest | sha256_ref) and
       .verification_result.localization.specialist_inputs_conformant == true and
       .verification_result.localization.synthesis_output_conformant == false and
       .verification_result.localization.localized_role == "supervisor_synthesis" and
       .policy_result.outcome == "quarantine_response"
     elif .case.kind == "direct_runtime_bypass" then
       .original_execution.execution_path.governed_gateway_required == true and
       .original_execution.execution_path.governed_gateway_observed == false and
       .original_execution.execution_path.raw_runtime_endpoint_observed == true and
       .original_execution.verification_request.capability_class == "governance_only" and
       (.verification_result.limitations | index("governed_gateway_bypassed") != null) and
       .policy_result.outcome == "isolate_runtime"
     elif .case.kind == "linked_reverification" then
       (.original_execution.evidence_digest | sha256_ref) and
       (.reverification.verification_ref | verification_ref) and
       .reverification.prior_verification_ref == .verification_result.verification_ref and
       .reverification.original_execution_ref == .original_execution.execution_ref and
       .reverification.original_evidence_digest == .original_execution.evidence_digest and
       .reverification.observed_original_evidence_digest == .original_execution.evidence_digest and
       .reverification.append_only == true and
       (.reverification.verifier.build_ref | sha256_ref) and
       .reverification.verdict == "conformant" and
       .reverification.authoritative == false
     elif .case.kind == "reverification_mutation_attempt" then
       (.original_execution.evidence_digest | sha256_ref) and
       (.reverification.verification_ref | verification_ref) and
       .reverification.prior_verification_ref == .verification_result.verification_ref and
       .reverification.original_execution_ref == .original_execution.execution_ref and
       .reverification.original_evidence_digest == .original_execution.evidence_digest and
       (.reverification.submitted_evidence_digest | sha256_ref) and
       .reverification.submitted_evidence_digest != .original_execution.evidence_digest and
       .reverification.immutable_original_preserved == true and
       .reverification.mutation_attempted == true and
       .reverification.append_only == true and
       .reverification.verdict == "dangerous" and
       .reverification.authoritative == false and
       (.verification_result.limitations | index("original_evidence_mutation_attempted") != null) and
       .policy_result.outcome == "preserve_forensics"
     else true end)
  ' "$fixture" >/dev/null || fail "inference-integrity fixture contract is invalid: $path"
done < <(printf '%s\n' "${manifest_paths[@]}")

! grep -RInE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|api[_-]?key|password|secret[[:space:]]*:)' \
  "$fixture_root" >/dev/null || fail "fixture contains secret-like material"

echo "Inference-integrity provisional fixture validation passed"
