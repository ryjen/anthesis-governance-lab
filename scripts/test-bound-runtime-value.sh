#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/bound-runtime-value-v1.json"
validator="$root/scripts/validate-bound-runtime-value.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'exact-bound-write:expected:DENY' \
 'exact-bound-write:authorized:false' \
 'exact-bound-write:write_recipient:recipient:B' \
 'exact-bound-write:write_amount:126' \
 'exact-bound-write:write_revision:lookup:2' \
 'exact-bound-write:lookup_source:untrusted-text' \
 'changed-recipient:expected:ALLOW' \
 'changed-amount:expected:ALLOW' \
 'stale-lookup:expected:ALLOW' \
 'untrusted-source:expected:ALLOW' \
 'unrelated-state-change:expected:DENY'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
  (.cases[] | select(.id == $id)) |= (
    if $field == "expected" then .expected = $value
    elif $field == "authorized" then .authorized = ($value == "true")
    elif $field == "write_recipient" then .write.recipient = $value
    elif $field == "write_amount" then .write.amount = ($value | tonumber)
    elif $field == "write_revision" then .write.lookup_revision = $value
    elif $field == "lookup_source" then .lookup.source = $value
    else . end
  )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
  echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
echo "Bound runtime value negative oracle: $count mutations rejected"
