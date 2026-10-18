#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/semantic-judge-narrowing-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def verdict:
  if .semantic_judge == "ALLOW" and
     .deterministic.scope == true and
     .deterministic.target == true and
     .deterministic.sequence == true and
     .deterministic.approval == true
  then "ALLOW" else "DENY" end;
 .version == "anthesis-governance-lab.semantic-judge-narrowing/v1" and
 .synthetic == true and .executes_effects == false and
 .requires_network == false and .requires_credentials == false and .requires_live_model == false and
 .policy_revision == "policy:1" and
 (.cases | type == "array" and length == 8) and
 ([.cases[].id] | sort == (["all-allow","judge-narrows","scope-denied","target-denied","sequence-denied","approval-denied","multiple-constraints-denied","unknown-judge-denied"] | sort)) and
 all(.cases[];
  (.semantic_judge | IN("ALLOW","DENY","UNKNOWN")) and
  (.deterministic | keys | sort == (["scope","target","sequence","approval"] | sort)) and
  all(.deterministic[]; type == "boolean") and
  .proposed_effect == false and
  .expected == verdict and
  (if .id == "all-allow" then .expected == "ALLOW" else .expected == "DENY" end)) and
 (.proves | type == "array" and length > 0) and
 (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Semantic judge narrowing: 8 synthetic cases passed"
