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
    (.verification_class | IN("fixed_seed", "bounded_consistency", "semantic_only", "governance_only", "unsupported"))
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
  jq -e '
    def sha256_ref: type == "string" and test("^sha256:[0-9a-f]{64}$");
    .version == "anthesis-governance-lab.inference-integrity-record/v0" and
    .status == "provisional" and
    .synthetic == true and
    (.original_execution.execution_ref | type == "string" and startswith("execution:") and length > 10) and
    (.original_execution.gateway_contract_ref == "dubnium-llm-gateway/v1") and
    (.original_execution.requested_model_alias | type == "string" and length > 0) and
    (.original_execution.resolved_execution.provider_ref | type == "string" and startswith("provider:") and length > 9) and
    (.original_execution.resolved_execution.route_ref | type == "string" and startswith("route:") and length > 6) and
    (.original_execution.resolved_execution.model_artifact_ref | sha256_ref) and
    (.original_execution.resolved_execution.tokenizer_ref | sha256_ref) and
    (.original_execution.resolved_execution.runtime_build_ref | sha256_ref) and
    (.original_execution.resolved_execution.runtime_profile_ref | sha256_ref) and
    (.original_execution.resolved_execution.prompt_profile_ref | sha256_ref) and
    (.original_execution.resolved_execution.routing_policy_ref | sha256_ref) and
    (.original_execution.sampling.parameters_digest | sha256_ref) and
    (.original_execution.sampling.seed_commitment | sha256_ref) and
    (.original_execution.sampling.seed_owner == "gateway") and
    (.original_execution.output.response_digest | sha256_ref) and
    (.original_execution.output.token_ids_digest | sha256_ref) and
    (.original_execution.verification_request.capability_class | IN("fixed_seed", "bounded_consistency", "semantic_only", "governance_only", "unsupported")) and
    (.original_execution.verification_request.operating_mode | IN("observe", "selective_gate", "required_gate")) and
    (.verification_result.original_execution_ref == .original_execution.execution_ref) and
    (.verification_result.verifier.build_ref | sha256_ref) and
    (.verification_result.verdict | IN("conformant", "suspicious", "dangerous", "indeterminate")) and
    .verification_result.authoritative == false and
    (.policy_result.original_execution_ref == .original_execution.execution_ref) and
    (.policy_result.verification_ref == .verification_result.verification_ref) and
    (.policy_result.outcome | IN("allow", "allow_with_signal", "increase_sampling", "quarantine_response", "suspend_route", "isolate_runtime", "isolate_specialist", "suspend_model_alias", "require_human_review", "preserve_forensics", "enter_dormancy")) and
    .policy_result.authority == "phloem-calyx-policy-plane"
  ' "$fixture" >/dev/null || fail "inference-integrity fixture contract is invalid: $path"
done < <(printf '%s\n' "${manifest_paths[@]}")

! grep -RInE '(BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|api[_-]?key|password|secret[[:space:]]*:)' \
  "$fixture_root" >/dev/null || fail "fixture contains secret-like material"

echo "Inference-integrity provisional fixture validation passed"
