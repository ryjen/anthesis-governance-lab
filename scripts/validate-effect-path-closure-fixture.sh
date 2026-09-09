#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$repo_root/fixtures/external-security/effect-path-closure-v1.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$fixture" && ! -L "$fixture" ]] || fail "effect-path closure fixture must be a regular file: $fixture"

jq -e '
  .version == "anthesis-governance-lab.external-security-effect-path-closure/v1" and
  .synthetic == true and
  .executes_effects == false and
  .requires_network == false and
  .requires_credentials == false and
  .requires_live_model == false and
  (.invariant | type == "string" and contains("unavoidable exact-effect enforcement boundary")) and
  (.effects | type == "object" and length >= 3) and
  (.authorizations | type == "object" and length >= 4) and
  (.paths | type == "object" and length >= 4) and
  (.cases | length >= 10) and
  ([.cases[].id] | length == (unique | length)) and
  all(.effects[];
    (.operation | type == "string" and length > 0) and
    (.target | type == "string" and length > 0) and
    (.arguments | type == "object") and
    (.digest | test("^sha256:[0-9a-f]{64}$"))
  ) and
  all(.authorizations[];
    (.effect | type == "string" and . as $effect | $effect | IN("effect_a", "effect_target_mutated", "effect_args_mutated")) and
    (.executor_identity | type == "string" and length > 0) and
    (.state | IN("active", "consumed", "expired")) and
    .single_use == true
  ) and
  all(.paths[];
    (.path_class | IN("mediated", "bypass")) and
    .semantically_equivalent_effect == true and
    (.expected_reachability | IN("reachable", "unreachable")) and
    (.requires_enforcement_boundary | type == "boolean")
  ) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.path | IN("governed_adapter", "raw_api", "alternate_registry", "direct_credential")) and
    (.requested_effect | IN("effect_a", "effect_target_mutated", "effect_args_mutated")) and
    ((.authorization_ref == null) or (.authorization_ref | IN("permit_a", "permit_a_consumed", "permit_a_expired", "permit_wrong_executor"))) and
    (.control_signal_observed | type == "boolean") and
    (.enforcement_boundary_available | type == "boolean") and
    (.enforcement_boundary_observed | type == "boolean") and
    (.executor_observed | type == "boolean") and
    (.effect_count | type == "number" and . >= 0 and floor == .) and
    (.expected_verdict | IN("allow", "block")) and
    (.expected_reason | type == "string" and length > 0) and
    (.proves | type == "array" and length > 0) and
    (.does_not_prove | type == "array" and length > 0)
  ) and
  (.proves | type == "array" and length > 0) and
  (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null || fail "effect-path closure fixture contract is invalid"

jq -e '
  .paths.governed_adapter.path_class == "mediated" and
  .paths.governed_adapter.expected_reachability == "reachable" and
  .paths.governed_adapter.requires_enforcement_boundary == true and
  ([.paths | to_entries[] | select(.value.path_class == "bypass")] | length >= 3) and
  all(.paths | to_entries[] | select(.value.path_class == "bypass");
    .value.expected_reachability == "unreachable") and
  .authorizations.permit_a.effect == "effect_a" and
  .authorizations.permit_a.executor_identity == "executor_primary" and
  .authorizations.permit_a.state == "active" and
  .authorizations.permit_a_consumed.state == "consumed" and
  .authorizations.permit_a_expired.state == "expired" and
  .authorizations.permit_wrong_executor.executor_identity == "executor_other"
' "$fixture" >/dev/null || fail "effect-path closure path or authorization model is invalid"

jq -e '
  all(.cases[];
    if .expected_verdict == "block"
    then .effect_count == 0
    else .effect_count == 1
    end) and
  any(.cases[];
    .id == "mediated-exact-effect-allowed" and
    .path == "governed_adapter" and
    .requested_effect == "effect_a" and
    .authorization_ref == "permit_a" and
    .enforcement_boundary_available == true and
    .enforcement_boundary_observed == true and
    .executor_observed == true and
    .effect_count == 1 and
    .expected_verdict == "allow") and
  any(.cases[];
    .id == "raw-api-bypass-blocked" and
    .path == "raw_api" and
    .authorization_ref == null and
    .executor_observed == false and
    .effect_count == 0 and
    .expected_verdict == "block") and
  any(.cases[];
    .id == "alternate-registry-bypass-blocked" and
    .path == "alternate_registry" and
    .effect_count == 0 and
    .expected_verdict == "block") and
  any(.cases[];
    .id == "direct-credential-bypass-blocked" and
    .path == "direct_credential" and
    .effect_count == 0 and
    .expected_verdict == "block")
' "$fixture" >/dev/null || fail "effect-path closure positive/bypass invariants are not preserved"

jq -e '
  any(.cases[];
    .id == "target-mutated-after-authorization" and
    .requested_effect == "effect_target_mutated" and
    .authorization_ref == "permit_a" and
    .enforcement_boundary_observed == true and
    .executor_observed == false and
    .effect_count == 0 and
    .expected_reason == "effect_binding_mismatch") and
  any(.cases[];
    .id == "arguments-mutated-after-authorization" and
    .requested_effect == "effect_args_mutated" and
    .authorization_ref == "permit_a" and
    .effect_count == 0 and
    .expected_reason == "effect_binding_mismatch") and
  any(.cases[];
    .id == "consumed-authorization-replay-blocked" and
    .authorization_ref == "permit_a_consumed" and
    .effect_count == 0 and
    .expected_reason == "authorization_replayed") and
  any(.cases[];
    .id == "expired-authorization-blocked" and
    .authorization_ref == "permit_a_expired" and
    .effect_count == 0 and
    .expected_reason == "authorization_expired") and
  any(.cases[];
    .id == "wrong-executor-identity-blocked" and
    .authorization_ref == "permit_wrong_executor" and
    .effect_count == 0 and
    .expected_reason == "executor_identity_mismatch") and
  any(.cases[];
    .id == "enforcement-boundary-unavailable-fails-closed" and
    .enforcement_boundary_available == false and
    .enforcement_boundary_observed == false and
    .executor_observed == false and
    .effect_count == 0 and
    .expected_reason == "enforcement_boundary_unavailable")
' "$fixture" >/dev/null || fail "effect binding, replay, identity, or fail-closed invariants are not preserved"

jq -e '
  any(.cases[];
    .id == "control-signal-observed-but-raw-bypass-blocked" and
    .path == "raw_api" and
    .control_signal_observed == true and
    .authorization_ref == "permit_a" and
    .enforcement_boundary_observed == false and
    .executor_observed == false and
    .effect_count == 0 and
    .expected_verdict == "block" and
    .expected_reason == "observed_signal_does_not_authorize_bypass_path") and
  any(.proves[]; contains("observed control traffic and enforced mediation are distinct")) and
  any(.does_not_prove[]; contains("unknown or unmodeled bypass paths")) and
  any(.does_not_prove[]; contains("ACS conformance"))
' "$fixture" >/dev/null || fail "observation-versus-enforcement or assurance-boundary invariants are not preserved"

echo "Effect-path closure fixture validation passed"
