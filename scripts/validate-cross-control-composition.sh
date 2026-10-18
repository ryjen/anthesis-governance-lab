#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/cross-control-composition-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || { echo "invalid composition fixture path" >&2; exit 1; }
command -v jq >/dev/null || exit 1
jq -e '
  def derived:
    if .normalized_source_id != .source_id or
       .consumed_memory_revision != .memory_revision or
       .decision_delegation_id != .delegation_id or
       .decision_policy_revision != .policy_revision or
       (.detected and .contaminated_path_live) or
       (.detected and (.recovery_attributable | not)) or
       (.independent_root_continues | not) then "INSECURE"
    elif (.local_provenance_pass | not) or (.local_authority_pass | not) then "INDETERMINATE"
    else "SECURE" end;
  . as $fixture |
  .version == "anthesis-governance-lab.cross-control-composition/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_network == false and .requires_credentials == false and
  .source == "arxiv:2606.10749v2" and
  (.assumptions | type == "array" and length >= 2) and
  (.does_not_prove | type == "array" and length >= 2) and
  (.cases | type == "array" and length == 6) and
  ([.cases[].id] | unique | length == 6) and
  ([.cases[].id] | sort == (["positive-composition","provenance-drop","authority-drop","stale-state-delayed-effect","detected-without-containment","quarantined-recovery"] | sort)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.source_id | type == "string" and startswith("observation:")) and
    (.normalized_source_id == null or (.normalized_source_id | type == "string")) and
    (.memory_revision | type == "string" and startswith("memory:")) and
    (.consumed_memory_revision | type == "string") and
    (.actor | type == "string" and startswith("actor:")) and
    (.delegated_actor | type == "string" and startswith("actor:")) and
    (.delegation_id | type == "string" and startswith("grant:")) and
    (.decision_delegation_id == null or (.decision_delegation_id | type == "string")) and
    (.policy_revision | type == "string" and startswith("policy:")) and
    (.decision_policy_revision | type == "string") and
    (.effect_id | type == "string" and startswith("effect:")) and
    (.origin_root | type == "string" and startswith("root:")) and
    (.terminal_effects | type == "array") and
    . as $case |
    (all(.terminal_effects[]; .effect_id == $case.effect_id and .origin_root == $case.origin_root and .disposition == "committed")) and
    ((.terminal_effects | length) == ([.terminal_effects[].effect_id] | unique | length)) and
    (.effect_committed == (any(.terminal_effects[]; .effect_id == $case.effect_id and .disposition == "committed"))) and
    (.open_contaminated_effect_ids | type == "array") and
    (.contaminated_path_live == ((.open_contaminated_effect_ids | length) > 0)) and
    (all(.open_contaminated_effect_ids[]; . == $case.effect_id)) and
    (.security_requirements_pass | type == "boolean") and
    (.utility_observation | type == "string" and length > 0) and
    (.latency_observation | type == "string" and length > 0) and
    (.cost_observation | type == "string" and length > 0) and
    (all([.effect_committed,.delayed_effect,.local_provenance_pass,.local_authority_pass,.detected,.contaminated_path_live,.quarantined,.recovery_attributable,.independent_root_continues][]; type == "boolean")) and
    (.expected | IN("SECURE","INSECURE","INDETERMINATE")) and
    (.expected == derived) and
    (.security_requirements_pass == (derived == "SECURE")) and
    (if .id == "positive-composition" then .expected == "SECURE" and .effect_committed else true end) and
    (if .id == "provenance-drop" then .normalized_source_id == null and .local_provenance_pass and .local_authority_pass and .expected == "INSECURE" else true end) and
    (if .id == "authority-drop" then .decision_delegation_id == null and .local_provenance_pass and .local_authority_pass and .expected == "INSECURE" else true end) and
    (if .id == "stale-state-delayed-effect" then .delayed_effect and .consumed_memory_revision != .memory_revision and .expected == "INSECURE" else true end) and
    (if .id == "detected-without-containment" then .detected and .contaminated_path_live and .expected == "INSECURE" else true end) and
    (if .id == "quarantined-recovery" then .detected and .quarantined and (.contaminated_path_live | not) and (.effect_committed | not) and .recovery_attributable and .independent_root_continues and .expected == "SECURE" else true end)
  )
' "$fixture" >/dev/null || { echo "cross-control composition invariants failed" >&2; exit 1; }
echo "Cross-control composition: 6 synthetic cases passed"

