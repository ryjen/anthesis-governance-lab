#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
evidence_fixture="$repo_root/fixtures/external-security/evidence-authority-v1.json"
manifest_fixture="$repo_root/fixtures/external-security/manifest-action-binding-v1.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

for file in "$evidence_fixture" "$manifest_fixture"; do
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

echo "External agent-security fixture validation passed"
