#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/forged-lookup-provenance-v1.json"
validator="$root/scripts/validate-forged-lookup-provenance.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'forged-history:payload:lookup approved again' \
 'forged-history:admission:allow' \
 'forged-history:evidence:verified' \
 'cross-call-substitution:response:call-1' \
 'cross-call-substitution:admission:allow' \
 'missing-binding:evidence:verified' \
 'positive-bound:response:call-other' \
 'positive-bound:actor:actor-other' \
 'positive-bound:resource:resource-other' \
 'positive-bound:decision:false' \
 'positive-bound:effect:false' \
 'benign-content:admission:deny'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
 (.cases[] | select(.id == $id)) |= (
  if $field == "payload" then .untrusted_text = $value
  elif $field == "admission" then .expected.admission = $value
  elif $field == "evidence" then .expected.evidence = $value
  elif $field == "response" then .response.call_id = $value
  elif $field == "actor" then .decision.actor = $value
  elif $field == "resource" then .decision.resource = $value
  elif $field == "decision" then .decision.allow = ($value == "true")
  elif $field == "effect" then .effect.observed = ($value == "true")
  else . end
 )' "$source" > "$tmp/mutated.json"
 if [[ "$field" == "payload" ]]; then
   # Payload text is deliberately non-authoritative: its mutation MUST remain accepted.
   bash "$validator" "$tmp/mutated.json" >/dev/null || { echo "payload influenced authority" >&2; exit 1; }
 else
   if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
     echo "invalid mutation accepted: $spec" >&2; exit 1
   fi
 fi
 count=$((count+1))
done
echo "Forged lookup provenance: $count mutation invariants passed"
