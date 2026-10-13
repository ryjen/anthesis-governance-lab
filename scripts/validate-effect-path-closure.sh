#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$root/fixtures/external-security/effect-path-closure-v1.json"
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }
[[ -f "$fixture" && ! -L "$fixture" ]] || { echo "missing or symlinked fixture" >&2; exit 1; }
jq -e '
  . as $root |
  .version == "anthesis-governance-lab.external-security-effect-path-closure/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_network == false and .requires_credentials == false and .requires_live_model == false and
  ([.cases[].id] | length == (unique | length)) and
  ([.cases[] | select(.expected_verdict == "allow")] | length == 1) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    ($root.paths[.path] != null) and ($root.effects[.requested_effect] != null) and
    (.authorization_ref == null or $root.authorizations[.authorization_ref] != null) and
    (.effect_count | type == "number") and .effect_count >= 0 and
    (.expected_verdict | IN("allow", "block")) and
    (.proves | type == "array" and length > 0) and
    (.does_not_prove | type == "array" and length > 0) and
    (if .expected_verdict == "block" then
      .effect_count == 0 and .executor_observed == false
    else
      .effect_count == 1 and .executor_observed == true and
      .enforcement_boundary_available == true and .enforcement_boundary_observed == true and
      .path == "governed_adapter" and
      ($root.authorizations[.authorization_ref].state == "active") and
      ($root.authorizations[.authorization_ref].effect == .requested_effect)
    end)
  ) and
  (["raw_api", "alternate_registry", "direct_credential"] | all(.[];
    . as $path | any($root.cases[]; .path == $path and .expected_verdict == "block" and .effect_count == 0)
  )) and
  (["target-mutated-after-authorization", "arguments-mutated-after-authorization",
    "consumed-authorization-replay-blocked", "expired-authorization-blocked",
    "wrong-executor-identity-blocked", "enforcement-boundary-unavailable-fails-closed",
    "control-signal-observed-but-raw-bypass-blocked"] | all(.[];
    . as $id | any($root.cases[]; .id == $id and .expected_verdict == "block" and .effect_count == 0)
  )) and
  (.does_not_prove | any(.[]; contains("production")))
' "$fixture" >/dev/null
echo "effect-path-closure-v1: structural assertions passed (synthetic only)"
