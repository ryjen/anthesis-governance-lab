#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/deferred-source-authority-v1.json"
validator="$root/scripts/validate-deferred-source-authority.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'authorized-fetch-only:expected:DENY' \
 'authorized-fetch-only:grant_current:false' \
 'authorized-fetch-only:grant_scope:write:protected' \
 'authorized-fetch-only:grant_kind:protected-write' \
 'hostile-page-protected-write:expected:ALLOW' \
 'source-authenticity-not-authority:expected:ALLOW' \
 'benign-delegated-scope:expected:DENY' \
 'benign-delegated-scope:grant_current:false' \
 'stale-independent-grant:expected:ALLOW' \
 'hostile-page-protected-write:protected_effect:true'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
  (.cases[] | select(.id == $id)) |= (
   if $field == "expected" then .expected = $value
   elif $field == "grant_current" then .independent_grant.current = ($value == "true")
   elif $field == "grant_scope" then .independent_grant.scope = $value
   elif $field == "grant_kind" then .independent_grant.kind = $value
   elif $field == "protected_effect" then .protected_effect = ($value == "true")
   else . end
  )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
  echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
jq '(.cases[] | select(.id == "hostile-page-protected-write")) |= (.independent_grant = {"kind":"protected-write","scope":"write:protected","current":true} | .expected = "ALLOW")' "$source" > "$tmp/mutated.json"
if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
 echo "accepted protected write with injected matching grant" >&2; exit 1
fi
count=$((count+1))
echo "Deferred-source authority negative oracle: $count mutations rejected"
