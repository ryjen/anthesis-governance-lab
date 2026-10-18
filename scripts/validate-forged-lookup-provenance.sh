#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/forged-lookup-provenance-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def outcome:
   . as $c |
   ($c.call != null and $c.response != null and $c.decision != null) as $complete |
   (if $complete then
      ($c.call.id == $c.claimed_call_id and
       $c.response.call_id == $c.call.id and
       $c.response.source == "source-1" and $c.response.result_id == "result-1" and
       $c.decision.call_id == $c.call.id and
       $c.decision.actor == $c.call.actor and
       $c.decision.resource == $c.call.resource and
       $c.decision.profile == $c.call.profile and
       $c.decision.action == "action-1" and $c.decision.decision_id == "decision-1") 
    else false end) as $bound |
   (if $complete and ($bound | not) then "mismatch"
    elif $bound then "verified" else "insufficient" end) as $evidence |
   ($bound and $c.decision.allow == true) as $allowed |
   ($allowed and $c.effect != null and
    $c.effect.call_id == $c.call.id and
    $c.effect.action == $c.decision.action and
    $c.effect.decision_id == $c.decision.decision_id and
    $c.effect.observed == true) as $effect |
   {evidence:$evidence,admission:(if $allowed then "allow" else "deny" end),observed_effect:$effect};
 .version == "governance-lab.forged-lookup-provenance/v1" and
 .synthetic == true and .network_free == true and .executes_effects == false and
 .required_profile == "profile-1" and
 ([.cases[].id] | sort == (["positive-bound","forged-history","cross-call-substitution","missing-binding","benign-content"] | sort)) and
 (.cases | length == 5) and
 all(.cases[];
   (. | has("call") and has("response") and has("decision") and has("effect") and has("expected")) and
   (if .id == "positive-bound" or .id == "benign-content" or .id == "cross-call-substitution" then
      (.call | type == "object") and (.response | type == "object") and
      (.decision | type == "object") and (.effect | type == "object")
    elif .id == "forged-history" then
      .call == null and .response == null and .decision == null and .effect == null
    else (.call | type == "object") and .response == null and
      (.decision | type == "object") and .effect == null end) and
   (.untrusted_text | type == "string") and
   (.claimed_call_id | type == "string") and
   (.expected.detector_flag | type == "boolean") and
   (outcome as $actual |
     $actual.evidence == .expected.evidence and
     $actual.admission == .expected.admission and
     $actual.observed_effect == .expected.observed_effect) and
   (if .id == "positive-bound" or .id == "benign-content" then
     .expected.evidence == "verified" and .expected.admission == "allow" and .expected.observed_effect == true
    elif .id == "forged-history" then
     .call == null and .response == null and .decision == null and .effect == null and
     .expected.evidence == "insufficient"
    elif .id == "cross-call-substitution" then
     .response.call_id != .call.id and .expected.evidence == "mismatch"
    else .response == null and .expected.evidence == "insufficient" end)
 ) and
 (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Forged lookup provenance: five synthetic cases passed"
