#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$repo_root/fixtures/external-security/proof-execution-replay-v1.json}"

fail() { echo "error: $*" >&2; exit 1; }
[[ "$#" -le 1 ]] || fail "expected zero or one fixture path"
command -v jq >/dev/null || fail "jq is required"
[[ -f "$fixture" && ! -L "$fixture" ]] || fail "fixture must be a regular, non-symlink file"

# Derive outcomes from evidence/observation fields, never from expected verdicts.
# The independent witness, seal, recorder timing and full path inventory are
# explicitly *modeled*, not verified in the operating system or a live provider.
jq -e '
  def canonical_events:
    if .decision == "deny" then ["deny:alpha"]
    else ["allow:alpha", "dispatch:alpha", "commit:alpha"] end;
  def history:
    if .recorded_events != canonical_events or
       (.trace_seal_valid | not) or
       (.decision == "deny" and .observed_action != "none") or
       (.independent_witness == "observed" and .recorded_action != .observed_action) or
       .effect_path == "unmediated"
    then "REJECTED"
    elif .independent_witness != "observed" or
         (.capture_complete | not) or
         (.recorder_before_commit | not)
    then "UNRESOLVED"
    else "VERIFIED" end;
  def replay:
    (history) as $h |
    if $h != "VERIFIED" then $h
    elif ((.declared_dependencies - .available_dependencies) | length) != 0 then "UNRESOLVED"
    elif (.replay_world_equivalent | not) then "REJECTED"
    else "VERIFIED" end;
  def dispatch:
    if .new_protected_effect_requested and
       .fresh_authorization and
       (.fresh_authorized_action == .followon_action) and
       (.fresh_authorized_principal == .requesting_principal) and
       (.current_authority_revoked | not) and
       history == "VERIFIED"
    then "allow" else "deny" end;

  . as $root |
  .version == "anthesis-governance-lab.proof-execution-replay/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_network == false and .requires_credentials == false and
  .requires_live_model == false and
  (.assumptions | type == "array" and length >= 4) and
  (.does_not_prove | type == "array" and length >= 4) and
  (.proves | type == "array" and length >= 2) and
  (.cases | type == "array" and length == 19) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.decision | IN("allow", "deny")) and
    (.recorded_action | IN("alpha", "none")) and
    (.observed_action | IN("alpha", "beta", "none")) and
    (.effect_path | IN("governed", "unmediated")) and
    (.recorded_events | type == "array" and length > 0 and all(. | type == "string")) and
    (.trace_seal_valid | type == "boolean") and
    (.capture_complete | type == "boolean") and
    (.recorder_before_commit | type == "boolean") and
    (.independent_witness | IN("observed", "unavailable")) and
    (.declared_dependencies | type == "array" and all(. | type == "string") and length == (unique | length)) and
    (.available_dependencies | type == "array" and all(. | type == "string") and length == (unique | length)) and
    (.replay_world_equivalent | type == "boolean") and
    (.new_protected_effect_requested | type == "boolean") and
    (.fresh_authorization | type == "boolean") and
    (.followon_action | IN("alpha", "beta")) and
    (.requesting_principal | IN("principal_operator", "principal_other")) and
    ((.fresh_authorized_action == null) or (.fresh_authorized_action | IN("alpha", "beta"))) and
    ((.fresh_authorized_principal == null) or (.fresh_authorized_principal | IN("principal_operator", "principal_other"))) and
    (.current_authority_revoked | type == "boolean") and
    (.expected | keys | sort == ["dispatch", "history", "replay"]) and
    (.expected.history | IN("VERIFIED", "REJECTED", "UNRESOLVED")) and
    (.expected.replay | IN("VERIFIED", "REJECTED", "UNRESOLVED")) and
    (.expected.dispatch | IN("allow", "deny")) and
    (. as $c | $c.expected.history == ($c | history) and
                $c.expected.replay == ($c | replay) and
                $c.expected.dispatch == ($c | dispatch))
  ) and
  ([
    ["governed-exact-effect", "VERIFIED", "VERIFIED", "deny"],
    ["deny-with-zero-effect", "VERIFIED", "VERIFIED", "deny"],
    ["direct-provider-bypass", "REJECTED", "REJECTED", "deny"],
    ["deny-with-durable-effect", "REJECTED", "REJECTED", "deny"],
    ["sealed-trace-event-replacement", "REJECTED", "REJECTED", "deny"],
    ["sealed-trace-event-deletion", "REJECTED", "REJECTED", "deny"],
    ["sealed-trace-event-reordering", "REJECTED", "REJECTED", "deny"],
    ["alternate-credential-effect", "REJECTED", "REJECTED", "deny"],
    ["collector-acknowledges-after-commit", "UNRESOLVED", "UNRESOLVED", "deny"],
    ["independent-witness-unavailable", "UNRESOLVED", "UNRESOLVED", "deny"],
    ["capture-scope-unverified", "UNRESOLVED", "UNRESOLVED", "deny"],
    ["declared-replay-dependency-missing", "VERIFIED", "UNRESOLVED", "deny"],
    ["hidden-replay-dependency-drift", "VERIFIED", "REJECTED", "deny"],
    ["historical-valid-after-current-revocation", "VERIFIED", "VERIFIED", "deny"],
    ["new-authority-required-for-followon", "VERIFIED", "VERIFIED", "allow"],
    ["live-world-drift-despite-replay", "VERIFIED", "REJECTED", "deny"],
    ["fresh-authorization-revoked", "VERIFIED", "VERIFIED", "deny"],
    ["fresh-authorization-wrong-action", "VERIFIED", "VERIFIED", "deny"],
    ["fresh-authorization-wrong-principal", "VERIFIED", "VERIFIED", "deny"]
  ] | all(.[]; . as $e | any($root.cases[];
    .id == $e[0] and
    .expected.history == $e[1] and
    .expected.replay == $e[2] and
    .expected.dispatch == $e[3]
  ))) and
  (any(.cases[]; .id == "direct-provider-bypass" and .effect_path == "unmediated")) and
  (any(.cases[]; .id == "deny-with-durable-effect" and .decision == "deny" and .observed_action == "alpha")) and
  (any(.cases[]; .id == "alternate-credential-effect" and .recorded_action == "alpha" and .observed_action == "beta")) and
  (any(.cases[]; .id == "collector-acknowledges-after-commit" and .recorder_before_commit == false)) and
  (any(.cases[]; .id == "independent-witness-unavailable" and .independent_witness == "unavailable")) and
  (any(.cases[]; .id == "capture-scope-unverified" and .capture_complete == false)) and
  (any(.cases[]; .id == "declared-replay-dependency-missing" and ((.declared_dependencies - .available_dependencies) | length) > 0)) and
  (any(.cases[]; .id == "historical-valid-after-current-revocation" and .current_authority_revoked == true)) and
  (any(.cases[]; .id == "fresh-authorization-revoked" and .fresh_authorization == true and .current_authority_revoked == true)) and
  (any(.cases[]; .id == "fresh-authorization-wrong-action" and .fresh_authorized_action != .followon_action)) and
  (any(.cases[]; .id == "fresh-authorization-wrong-principal" and .fresh_authorized_principal != .requesting_principal))
' "$fixture" >/dev/null || fail "proof-of-execution replay fixture invariants failed"

echo "Proof-of-execution and replay fixture validation passed (19 synthetic cases)"
