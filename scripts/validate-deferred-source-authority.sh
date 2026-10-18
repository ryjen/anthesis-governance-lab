#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/deferred-source-authority-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def verdict:
  if (.independent_grant != null) and .independent_grant.current == true and
     .independent_grant.kind == .request.kind and
     .independent_grant.scope == .request.scope
  then "ALLOW" else "DENY" end;
 .version == "anthesis-governance-lab.deferred-source-authority/v1" and
 .synthetic == true and .executes_effects == false and
 .requires_network == false and .requires_credentials == false and .requires_live_model == false and
 .policy_revision == "policy:1" and
 (.cases | type == "array" and length == 5) and
 ([.cases[].id] | sort == (["authorized-fetch-only","hostile-page-protected-write","source-authenticity-not-authority","benign-delegated-scope","stale-independent-grant"] | sort)) and
 all(.cases[];
  .source.kind == "mutable-todo" and
  (.source.authenticated | type == "boolean") and
  (.source.contains_hostile_instruction | type == "boolean") and
  (.request.kind | IN("fetch","protected-write","delegated-read")) and
  (.request.scope | IN("read:todo","write:protected","read:task")) and
  (.protected_effect == false) and
  (.independent_grant == null or
    ((.independent_grant.current | type == "boolean") and
     (.independent_grant.kind | type == "string") and
     (.independent_grant.scope | type == "string"))) and
  (.expected == verdict) and
  (if (.id == "authorized-fetch-only" or .id == "benign-delegated-scope")
   then .expected == "ALLOW" else .expected == "DENY" end)) and
 (.proves | type == "array" and length > 0) and
 (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Deferred-source authority: 5 synthetic cases passed"
