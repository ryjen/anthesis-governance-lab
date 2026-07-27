#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
manifest="$repo_root/fixtures/inference-integrity/manifest.json"

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
    (.purpose | type == "string" and length > 0) and
    (.verification_class | IN("fixed_seed", "bounded_consistency", "semantic_only", "governance_only", "unsupported"))
  )
' "$manifest" >/dev/null || fail "inference-integrity manifest contract is invalid"

while IFS= read -r path; do
  fixture="$repo_root/$path"
  [[ -f "$fixture" && ! -L "$fixture" ]] || fail "unsafe or missing fixture: $path"
  jq -e '
    .version == "anthesis-governance-lab.inference-integrity-record/v0" and
    .status == "provisional" and
    .synthetic == true and
    (.original_execution.execution_ref | startswith("execution:")) and
    (.original_execution.gateway_contract_ref == "dubnium-llm-gateway/v1") and
    (.original_execution.requested_model_alias | type == "string" and length > 0) and
    (.original_execution.resolved_execution.provider_ref | startswith("provider:")) and
    (.original_execution.resolved_execution.route_ref | startswith("route:")) and
    (.original_execution.resolved_execution.model_artifact_ref | startswith("sha256:")) and
    (.original_execution.resolved_execution.tokenizer_ref | startswith("sha256:")) and
    (.original_execution.resolved_execution.runtime_build_ref | startswith("sha256:")) and
    (.original_execution.sampling.seed_owner == "gateway") and
    (.original_execution.verification_request.capability_class | IN("fixed_seed", "bounded_consistency", "semantic_only", "governance_only", "unsupported")) and
    (.original_execution.verification_request.operating_mode | IN("observe", "selective_gate", "required_gate")) and
    (.verification_result.original_execution_ref == .original_execution.execution_ref) and
    (.verification_result.verdict | IN("conformant", "suspicious", "dangerous", "indeterminate")) and
    .verification_result.authoritative == false and
    (.policy_result.original_execution_ref == .original_execution.execution_ref) and
    (.policy_result.verification_ref == .verification_result.verification_ref) and
    (.policy_result.outcome | IN("allow", "allow_with_signal", "increase_sampling", "quarantine_response", "suspend_route", "isolate_runtime", "isolate_specialist", "suspend_model_alias", "require_human_review", "preserve_forensics", "enter_dormancy")) and
    .policy_result.authority == "phloem-calyx-policy-plane"
  ' "$fixture" >/dev/null || fail "inference-integrity fixture contract is invalid: $path"
done < <(jq -r '.fixtures[].path' "$manifest")

! grep -RInE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|api[_-]?key|password|secret[[:space:]]*:)' \
  "$repo_root/fixtures/inference-integrity" >/dev/null || fail "fixture contains secret-like material"

echo "Inference-integrity provisional fixture validation passed"
