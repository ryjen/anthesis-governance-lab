#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
evidence_fixture="$repo_root/fixtures/external-security/evidence-authority-v1.json"
manifest_fixture="$repo_root/fixtures/external-security/manifest-action-binding-v1.json"
environment_fixture="$repo_root/fixtures/external-security/environmental-influence-v1.json"
execution_fixture="$repo_root/fixtures/external-security/execution-correspondence-v1.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

for file in "$evidence_fixture" "$manifest_fixture" "$environment_fixture" "$execution_fixture"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "external security fixture must be a regular file: $file"
done

jq -e '
  .version == "anthesis-governance-lab.external-security-evidence-authority/v1" and
  .synthetic == true and
  .executes_effects == false and
  .policy.requires_current_verified_artifact == true and
  .policy.requires_independent_action_authorization == true and
  .policy.fail_closed_on_unverifiable_required_evidence == true and
  (.evidence_states | sort == ["contradictory", "mismatch", "missing", "stale", "unverifiable", "verified"]) and
  (.cases | length == 7) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.artifact_digest | test("^sha256:[0-9a-f]{64}$")) and
    (.evidence_state | IN("verified", "missing", "stale", "mismatch", "contradictory", "unverifiable")) and
    (.action_authorized | type == "boolean") and
    (.expected_decision | IN("allow", "deny")) and
    (.expected_reason | type == "string" and length > 0)
  ) and
  (.does_not_prove | type == "array" and length > 0)
' "$evidence_fixture" >/dev/null || fail "evidence-authority fixture contract is invalid"

jq -e '
  any(.cases[];
    .evidence_state == "verified" and
    .action_authorized == true and
    .expected_decision == "allow") and
  any(.cases[];
    .evidence_state == "verified" and
    .action_authorized == false and
    .expected_decision == "deny" and
    .expected_reason == "action_authority_missing") and
  all(.cases[];
    if .evidence_state != "verified" then .expected_decision == "deny" else true end) and
  any(.cases[];
    .evidence_state == "unverifiable" and
    .expected_reason == "required_evidence_unverifiable")
' "$evidence_fixture" >/dev/null || fail "evidence-authority invariants are not preserved"

jq -e '
  .version == "anthesis-governance-lab.external-security-manifest-action-binding/v1" and
  .synthetic == true and
  .executes_effects == false and
  .policy.requires_admitted_manifest_binding == true and
  .policy.requires_exact_call_binding == true and
  .policy.requires_actor_context_binding == true and
  .policy.requires_live_unrevoked_decision == true and
  (.cases | length == 8) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.admitted_manifest | IN("manifest_m1", "manifest_m2")) and
    ((.decision_manifest == null) or (.decision_manifest | IN("manifest_m1", "manifest_m2"))) and
    (.requested_call | IN("call_a1", "call_a2")) and
    ((.decision_call == null) or (.decision_call | IN("call_a1", "call_a2"))) and
    (.runtime_actor | IN("actor_parent", "actor_other")) and
    ((.decision_actor == null) or (.decision_actor | IN("actor_parent", "actor_other"))) and
    (.decision_live | type == "boolean") and
    (.decision_revoked | type == "boolean") and
    (.expected_decision | IN("allow", "deny")) and
    (.expected_reason | type == "string" and length > 0)
  ) and
  (.does_not_prove | type == "array" and length > 0)
' "$manifest_fixture" >/dev/null || fail "manifest-action-binding fixture contract is invalid"

jq -e '
  any(.cases[];
    .id == "fresh-m1-decision-exact-action" and
    .expected_decision == "allow") and
  any(.cases[];
    .id == "manifest-drift-before-dispatch" and
    .admitted_manifest != .decision_manifest and
    .expected_decision == "deny" and
    .expected_reason == "manifest_binding_stale") and
  any(.cases[];
    .id == "normalized-call-digest-changed" and
    .requested_call != .decision_call and
    .expected_decision == "deny") and
  any(.cases[];
    .id == "actor-context-changed" and
    .runtime_actor != .decision_actor and
    .expected_decision == "deny") and
  any(.cases[];
    .id == "valid-manifest-without-action-decision" and
    .decision_manifest == null and
    .expected_decision == "deny") and
  any(.cases[];
    .id == "fresh-m2-decision-after-drift" and
    .admitted_manifest == "manifest_m2" and
    .decision_manifest == "manifest_m2" and
    .expected_decision == "allow")
' "$manifest_fixture" >/dev/null || fail "manifest-action-binding invariants are not preserved"

jq -e '
  .version == "anthesis-governance-lab.external-security-environmental-influence/v1" and
  .synthetic == true and
  .executes_effects == false and
  .requires_network == false and
  .requires_credentials == false and
  .requires_live_model == false and
  (.scenario.source_domain | type == "string" and length > 0) and
  (.scenario.source_ref | contains("sha256:")) and
  (.scenario.acquisition | type == "string" and length > 0) and
  (.scenario.observation_ref | type == "string" and length > 0) and
  (.scenario.protected_target | type == "string" and length > 0) and
  (.scenario.requested_action | type == "string" and length > 0) and
  (.scenario.requested_action_digest | test("^sha256:[0-9a-f]{64}$")) and
  (.scenario.policy_ref | type == "string" and length > 0) and
  (.cases | length == 2) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    .hostile_content_present == true and
    .source_provenance_valid == true and
    .observation_evidence_valid == true and
    (.action_authorized | type == "boolean") and
    (.expected_decision | IN("allow", "deny")) and
    (.expected_reason | type == "string" and length > 0) and
    (.execution_record_present | type == "boolean") and
    (.terminal_state.protected_target_changed | type == "boolean") and
    (.terminal_state.benign_artifact_present | type == "boolean")
  ) and
  (.proves | type == "array" and length > 0) and
  (.does_not_prove | type == "array" and length > 0)
' "$environment_fixture" >/dev/null || fail "environmental-influence fixture contract is invalid"

jq -e '
  any(.cases[];
    .id == "hostile-observation-protected-effect-denied" and
    .hostile_content_present == true and
    .action_authorized == false and
    .expected_decision == "deny" and
    .execution_record_present == false and
    .terminal_state.protected_target_changed == false) and
  any(.cases[];
    .id == "hostile-observation-benign-objective-succeeds" and
    .hostile_content_present == true and
    .action_authorized == true and
    .expected_decision == "allow" and
    .execution_record_present == true and
    .terminal_state.protected_target_changed == false and
    .terminal_state.benign_artifact_present == true)
' "$environment_fixture" >/dev/null || fail "environmental-influence paired invariants are not preserved"

jq -e '
  .version == "anthesis-governance-lab.external-security-execution-correspondence/v1" and
  .synthetic == true and
  .executes_effects == false and
  .requires_network == false and
  .requires_credentials == false and
  .requires_live_model == false and
  .comparison.authorization_record_immutable == true and
  .comparison.execution_evidence_distinct == true and
  .comparison.terminal_state_evidence_distinct == true and
  (.comparison.policy_relevant_fields | sort == ["actor_context", "arguments", "operation", "target", "tool"]) and
  (.actions.action_a.digest | test("^sha256:[0-9a-f]{64}$")) and
  (.actions.action_b.digest | test("^sha256:[0-9a-f]{64}$")) and
  (.cases | length == 2) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.authorized_action | IN("action_a", "action_b")) and
    (.dispatched_action | IN("action_a", "action_b")) and
    (.executed_action | IN("action_a", "action_b")) and
    .authorization_valid == true and
    .dispatch_record_present == true and
    .execution_record_present == true and
    (.mismatch_fields | type == "array") and
    (.expected_correspondence | IN("pass", "fail")) and
    (.expected_reason | type == "string" and length > 0) and
    (.terminal_state.allowed_target_changed | type == "boolean") and
    (.terminal_state.protected_target_changed | type == "boolean")
  ) and
  (.proves | type == "array" and length > 0) and
  (.does_not_prove | type == "array" and length > 0)
' "$execution_fixture" >/dev/null || fail "execution-correspondence fixture contract is invalid"

jq -e '
  any(.cases[];
    .id == "authorized-a-provider-executes-b" and
    .authorized_action == "action_a" and
    .dispatched_action == "action_a" and
    .executed_action == "action_b" and
    .expected_correspondence == "fail" and
    .expected_reason == "executed_action_mismatch" and
    (.mismatch_fields == ["target"]) and
    .terminal_state.allowed_target_changed == false and
    .terminal_state.protected_target_changed == true) and
  any(.cases[];
    .id == "authorized-a-provider-executes-a" and
    .authorized_action == "action_a" and
    .dispatched_action == "action_a" and
    .executed_action == "action_a" and
    .expected_correspondence == "pass" and
    .expected_reason == "exact_execution_correspondence" and
    (.mismatch_fields | length == 0) and
    .terminal_state.allowed_target_changed == true and
    .terminal_state.protected_target_changed == false)
' "$execution_fixture" >/dev/null || fail "execution-correspondence paired invariants are not preserved"

echo "External agent-security fixture validation passed"
