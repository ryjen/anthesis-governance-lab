#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/semantic-judge-narrowing-v1.json"
validator="$root/scripts/validate-semantic-judge-narrowing.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'all-allow:expected:DENY' \
 'all-allow:judge:DENY' \
 'all-allow:judge:UNKNOWN' \
 'all-allow:scope:false' \
 'all-allow:target:false' \
 'all-allow:sequence:false' \
 'all-allow:approval:false' \
 'judge-narrows:expected:ALLOW' \
 'scope-denied:expected:ALLOW' \
 'target-denied:expected:ALLOW' \
 'sequence-denied:expected:ALLOW' \
 'approval-denied:expected:ALLOW' \
 'multiple-constraints-denied:expected:ALLOW' \
 'unknown-judge-denied:expected:ALLOW' \
 'all-allow:effect:true'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
  (.cases[] | select(.id == $id)) |= (
   if $field == "expected" then .expected = $value
   elif $field == "judge" then .semantic_judge = $value
   elif $field == "effect" then .proposed_effect = ($value == "true")
   elif ($field | IN("scope","target","sequence","approval")) then .deterministic[$field] = ($value == "true")
   else . end
  )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
  echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
echo "Semantic judge narrowing negative oracle: $count mutations rejected"
