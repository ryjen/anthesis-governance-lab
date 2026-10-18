#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/stateful-tool-order-v1.json"
validator="$root/scripts/validate-stateful-tool-order.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'lookup-then-write:expected:DENY' \
 'lookup-then-write:write_authorized:false' \
 'lookup-then-write:lookup_status:claimed' \
 'lookup-then-write:lookup_source:untrusted' \
 'lookup-then-write:lookup_revision:stale' \
 'lookup-then-write:write_revision:rev:2' \
 'write-before-lookup:expected:ALLOW' \
 'forged-history:expected:ALLOW' \
 'forged-history:lookup_status:completed'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
  (.cases[] | select(.id == $id)) |= (
    if $field == "expected" then .expected = $value
    elif $field == "write_authorized" then .write_authorized = ($value == "true")
    elif $field == "lookup_status" then (.steps[] | select(.kind == "lookup") | .status) = $value
    elif $field == "lookup_source" then (.steps[] | select(.kind == "lookup") | .source) = $value
    elif $field == "lookup_revision" then (.steps[] | select(.kind == "lookup") | .revision) = $value
    elif $field == "write_revision" then (.steps[] | select(.kind == "write") | .lookup_revision) = $value
    else . end
  )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
   echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
echo "Stateful tool-order negative oracle: $count mutations rejected"
