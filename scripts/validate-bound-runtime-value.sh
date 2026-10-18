#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/bound-runtime-value-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def verdict:
  if .authorized == true and .lookup.source == "trusted-structured" and
     .lookup.revision == .write.lookup_revision and
     .lookup.recipient == .write.recipient and
     .lookup.amount == .write.amount
  then "ALLOW" else "DENY" end;
 .version == "anthesis-governance-lab.bound-runtime-value/v1" and
 .synthetic == true and .executes_effects == false and
 .requires_network == false and .requires_credentials == false and
 .policy_revision == "policy:1" and
 (.cases | type == "array" and length == 6) and
 ([.cases[].id] | sort == (["exact-bound-write","changed-recipient","changed-amount","stale-lookup","untrusted-source","unrelated-state-change"] | sort)) and
 all(.cases[];
  (.authorized | type == "boolean") and
  (.lookup.source | IN("trusted-structured","untrusted-text")) and
  (.lookup.revision | type == "string" and length > 0) and
  (.write.lookup_revision | type == "string" and length > 0) and
  (.lookup.recipient | type == "string" and length > 0) and
  (.write.recipient | type == "string" and length > 0) and
  (.lookup.amount | type == "number") and
  (.write.amount | type == "number") and
  (.unrelated_state_revision | type == "string" and length > 0) and
  (.expected == verdict) and
  (if (.id == "exact-bound-write" or .id == "unrelated-state-change")
   then .expected == "ALLOW" else .expected == "DENY" end)) and
 (.proves | type == "array" and length > 0) and
 (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Bound runtime value: 6 synthetic cases passed"
