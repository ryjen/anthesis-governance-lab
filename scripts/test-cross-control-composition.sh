#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/cross-control-composition-v1.json"
validator="$root/scripts/validate-cross-control-composition.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
count=0
for spec in \
  'provenance-drop:expected:SECURE' \
  'authority-drop:expected:SECURE' \
  'stale-state-delayed-effect:expected:SECURE' \
  'detected-without-containment:expected:SECURE' \
  'positive-composition:normalized_source_id:forged' \
  'positive-composition:decision_delegation_id:forged' \
  'positive-composition:consumed_memory_revision:forged' \
  'quarantined-recovery:contaminated_path_live:true' \
  'quarantined-recovery:recovery_attributable:false' \
  'quarantined-recovery:independent_root_continues:false' \
  'positive-composition:effect_id:delete' \
  'positive-composition:local_authority_pass:string' \
  'positive-composition:modeled_security_gate_pass:false' \
  'positive-composition:terminal_effects:delete' \
  'quarantined-recovery:open_contaminated_effect_ids:delete' \
  'positive-composition:utility_observation:delete' \
  'positive-composition:origin_root:forged' \
  'positive-composition:expected:INSECURE' \
  'positive-composition:effect_id:forged' \
  'positive-composition:terminal_effects:empty' \
  'detected-without-containment:open_contaminated_effect_ids:empty' \
  'positive-composition:modeled_security_gate_pass:delete'; do
  id="${spec%%:*}"; remainder="${spec#*:}"; field="${remainder%%:*}"; value="${remainder#*:}"
  jq --arg id "$id" --arg field "$field" --arg value "$value" '
    (.cases[] | select(.id == $id)) |= (
      if $value == "delete" then del(.[$field])
      elif $value == "empty" then .[$field] = []
      elif $value == "true" then .[$field] = true
      elif $value == "false" then .[$field] = false
      elif $value == "string" then .[$field] = "invalid"
      else .[$field] = $value end
    )' "$source" > "$tmp/mutated.json"
  if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
    echo "composition mutation accepted: $spec" >&2
    exit 1
  fi
  count=$((count+1))
done
echo "Cross-control negative oracle: $count mutations rejected"

