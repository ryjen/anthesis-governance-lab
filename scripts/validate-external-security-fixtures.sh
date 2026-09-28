#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
evidence_fixture="$repo_root/fixtures/external-security/evidence-authority-v1.json"
manifest_fixture="$repo_root/fixtures/external-security/manifest-action-binding-v1.json"
environment_fixture="$repo_root/fixtures/external-security/environmental-influence-v1.json"
execution_fixture="$repo_root/fixtures/external-security/execution-correspondence-v1.json"
trace_fixture="$repo_root/fixtures/external-security/trace-integrity-v1.json"
memory_fixture="$repo_root/fixtures/external-security/stale-memory-authority-v1.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

for file in "$evidence_fixture" "$manifest_fixture" "$environment_fixture" "$execution_fixture" "$trace_fixture" "$memory_fixture"; do
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
  . as $root |
  all(.cases[];
    . as $case |
    ($root.actions[$case.authorized_action]) as $authorized |
    ($root.actions[$case.executed_action]) as $executed |
    ([
      $root.comparison.policy_relevant_fields[] as $field
      | select($authorized[$field] != $executed[$field])
      | $field
    ] | sort) as $derived_mismatches |
    ($case.dispatched_action == $case.authorized_action) and
    ($derived_mismatches == ($case.mismatch_fields | sort)) and
    (if $case.expected_correspondence == "pass"
      then ($derived_mismatches | length) == 0
      else ($derived_mismatches | length) > 0
     end)
  ) and
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
' "$execution_fixture" >/dev/null || fail "execution-correspondence derived mismatch invariants are not preserved"

jq -e '
  . as $root |
  .version == "anthesis-governance-lab.external-security-trace-integrity/v1" and
  .synthetic == true and
  .executes_effects == false and
  .requires_network == false and
  .requires_credentials == false and
  .requires_live_model == false and
  .evidence_plane.actor_can_mutate_local_trace == true and
  .evidence_plane.actor_can_mutate_independent_capture == false and
  .evidence_plane.local_trace_authoritative == false and
  .evidence_plane.independent_capture_required_for_authoritative_claim == true and
  (.evidence_plane.required_bindings | sort == ["action_digest", "actor_id", "decision_ref", "effect_id", "observed_result_digest", "run_id"]) and
  (.expected_record | keys | sort == ["action_digest", "actor_id", "decision_ref", "effect_id", "observed_result_digest", "run_id"]) and
  (.expected_record.action_digest | test("^sha256:[0-9a-f]{64}$")) and
  (.expected_record.observed_result_digest | test("^sha256:[0-9a-f]{64}$")) and
  (.cases | length == 7) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.local_trace_state | IN("intact", "deleted", "rewritten")) and
    ((.local_trace_consistent == null) or (.local_trace_consistent | type == "boolean")) and
    (.independent_capture_present | type == "boolean") and
    ((.independent_record == null) or ((.independent_record | keys | sort) == ["action_digest", "actor_id", "decision_ref", "effect_id", "observed_result_digest", "run_id"])) and
    ((.local_record == null) or ((.local_record | keys | sort) == ["action_digest", "actor_id", "decision_ref", "effect_id", "observed_result_digest", "run_id"])) and
    (.independent_mutation_attempt | type == "boolean") and
    (.independent_mutation_succeeded | type == "boolean") and
    (.effect_path | IN("governed_adapter", "alternate_path")) and
    (.effect_path_covered | type == "boolean") and
    (.terminal_effect_observed | type == "boolean") and
    (.authoritative_effect_claim_supported | type == "boolean") and
    (.expected_evidence_state | IN("verified", "verified_with_local_mismatch", "mismatch", "insufficient")) and
    (.expected_reason | type == "string" and length > 0) and
    (.authoritative_effect_claim_supported == ((.independent_capture_present == true) and (.independent_record == $root.expected_record) and (.effect_path_covered == true)))
  ) and
  (.proves | type == "array" and length > 0) and
  (.does_not_prove | type == "array" and length > 0)
' "$trace_fixture" >/dev/null || fail "trace-integrity fixture contract is invalid"

jq -e '
  . as $root |
  any(.cases[];
    .id == "baseline-independent-capture" and
    .local_trace_state == "intact" and
    .local_trace_consistent == true and
    .independent_capture_present == true and
    .independent_record == $root.expected_record and
    .local_record == $root.expected_record and
    .effect_path_covered == true and
    .authoritative_effect_claim_supported == true and
    .expected_evidence_state == "verified") and
  any(.cases[];
    .id == "local-trace-deleted-after-effect" and
    .local_trace_state == "deleted" and
    .local_record == null and
    .independent_capture_present == true and
    .independent_record == $root.expected_record and
    .authoritative_effect_claim_supported == true and
    .expected_reason == "independent_capture_survives_local_trace_deletion") and
  any(.cases[];
    .id == "local-trace-rewritten-after-effect" and
    .local_trace_state == "rewritten" and
    .local_trace_consistent == false and
    .local_record != .independent_record and
    .independent_record == $root.expected_record and
    .authoritative_effect_claim_supported == true and
    .expected_evidence_state == "verified_with_local_mismatch") and
  any(.cases[];
    .id == "independent-sink-mutation-blocked" and
    .independent_mutation_attempt == true and
    .independent_mutation_succeeded == false and
    .authoritative_effect_claim_supported == true) and
  any(.cases[];
    .id == "independent-capture-wrong-effect-binding" and
    .independent_capture_present == true and
    .independent_record.effect_id == "synthetic.effect.other" and
    .authoritative_effect_claim_supported == false and
    .expected_evidence_state == "mismatch" and
    .expected_reason == "independent_capture_binding_mismatch") and
  any(.cases[];
    .id == "independent-capture-unavailable" and
    .independent_capture_present == false and
    .authoritative_effect_claim_supported == false and
    .expected_evidence_state == "insufficient") and
  any(.cases[];
    .id == "alternate-effect-path-not-captured" and
    .effect_path == "alternate_path" and
    .effect_path_covered == false and
    .terminal_effect_observed == true and
    .authoritative_effect_claim_supported == false and
    .expected_reason == "effect_path_not_covered_by_independent_capture")
' "$trace_fixture" >/dev/null || fail "trace-integrity paired invariants are not preserved"

jq -e '
  .version == "anthesis-governance-lab.external-security-stale-memory-authority/v1" and
  .synthetic == true and
  .executes_effects == false and
  .requires_network == false and
  .requires_credentials == false and
  .requires_live_model == false and
  .policy.memory_is_authoritative == false and
  .policy.requires_current_authority_at_effect_time == true and
  .policy.deny_has_null_protected_effect == true and
  (.requested_effect.effect_id | type == "string" and length > 0) and
  (.requested_effect.action_digest | test("^sha256:[0-9a-f]{64}$")) and
  (.requested_effect.required_scope | type == "string" and length > 0) and
  (.requested_effect.protected_target | type == "string" and length > 0) and
  (.cases | length == 6) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.current_authority.state | IN("valid", "revoked", "narrowed", "expired", "superseded")) and
    (.current_authority.revision | type == "string" and length > 0) and
    (.current_authority.scope_allows_effect | type == "boolean") and
    .memory.claims_authorized == true and
    (.memory.captured_authority_revision | type == "string" and length > 0) and
    (.memory.source_provenance_valid | type == "boolean") and
    (.memory.restored_snapshot | type == "boolean") and
    (.expected_decision | IN("allow", "deny")) and
    (.expected_reason | type == "string" and length > 0) and
    (.execution_record_present | type == "boolean") and
    (.terminal_state.protected_target_changed | type == "boolean") and
    (.expected_decision ==
      (if (.current_authority.state == "valid" and .current_authority.scope_allows_effect == true)
       then "allow" else "deny" end)) and
    (if .expected_decision == "allow"
     then (.execution_record_present == true and .terminal_state.protected_target_changed == true)
     else (.execution_record_present == false and .terminal_state.protected_target_changed == false)
     end)
  ) and
  (.proves | type == "array" and length > 0) and
  (.does_not_prove | type == "array" and length > 0)
' "$memory_fixture" >/dev/null || fail "stale-memory-authority fixture contract is invalid"

jq -e '
  any(.cases[];
    .id == "current-valid-memory-matches" and
    .memory.claims_authorized == true and
    .current_authority.state == "valid" and
    .current_authority.scope_allows_effect == true and
    .memory.captured_authority_revision == .current_authority.revision and
    .expected_decision == "allow" and
    .execution_record_present == true and
    .terminal_state.protected_target_changed == true) and
  any(.cases[];
    .id == "revoked-grant-retained-in-memory" and
    .memory.claims_authorized == true and
    .current_authority.state == "revoked" and
    .memory.captured_authority_revision != .current_authority.revision and
    .expected_decision == "deny" and
    .expected_reason == "current_authority_revoked") and
  any(.cases[];
    .id == "narrowed-scope-memory-still-broad" and
    .memory.claims_authorized == true and
    .current_authority.state == "narrowed" and
    .current_authority.scope_allows_effect == false and
    .memory.captured_authority_revision != .current_authority.revision and
    .expected_decision == "deny") and
  any(.cases[];
    .id == "valid-provenance-stale-lifecycle" and
    .memory.source_provenance_valid == true and
    .current_authority.state == "superseded" and
    .memory.captured_authority_revision != .current_authority.revision and
    .expected_decision == "deny") and
  any(.cases[];
    .id == "restored-pre-revocation-memory-snapshot" and
    .memory.restored_snapshot == true and
    .current_authority.state == "revoked" and
    .memory.captured_authority_revision != .current_authority.revision and
    .expected_decision == "deny" and
    .expected_reason == "restored_memory_does_not_restore_authority") and
  any(.cases[];
    .id == "expired-delegation-retained-in-memory" and
    .current_authority.state == "expired" and
    .memory.captured_authority_revision != .current_authority.revision and
    .expected_decision == "deny")
' "$memory_fixture" >/dev/null || fail "stale-memory-authority paired invariants are not preserved"

echo "External agent-security fixture validation passed"
