#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/commit-recovery-v1.json"
validator="$root/scripts/validate-commit-recovery.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'committed-current:expected:DENY' \
 'committed-current:receipt:false' \
 'committed-current:status:proposed' \
 'committed-current:status:indeterminate' \
 'committed-current:run:run:2' \
 'committed-current:restart:2' \
 'committed-current:attempt:2' \
 'committed-current:policy:policy:2' \
 'proposed-not-committed:expected:ALLOW' \
 'indeterminate-not-committed:expected:ALLOW' \
 'unverified-commit:expected:ALLOW' \
 'retry-old-grant:expected:ALLOW' \
 'restart-old-grant:expected:ALLOW' \
 'new-run-old-grant:expected:ALLOW' \
 'policy-change-old-grant:expected:ALLOW'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
  (.cases[] | select(.id == $id)) |= (
   if $field == "expected" then .expected = $value
   elif $field == "receipt" then .prior_step.verified_receipt = ($value == "true")
   elif $field == "status" then .prior_step.status = $value
   elif $field == "run" then .context.run = $value
   elif $field == "restart" then .context.restart_epoch = ($value | tonumber)
   elif $field == "attempt" then .context.attempt = ($value | tonumber)
   elif $field == "policy" then .context.policy_revision = $value
   else . end
  )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
  echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
echo "Commit/recovery negative oracle: $count mutations rejected"
