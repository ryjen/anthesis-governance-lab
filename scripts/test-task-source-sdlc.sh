#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/task-source-sdlc-v1.json"
validator="$root/scripts/validate-task-source-sdlc.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'dependency-malicious:expected:ALLOW' \
 'persistent-hook-malicious:expected:ALLOW' \
 'agent-config-malicious:expected:ALLOW' \
 'process-budget-malicious:expected:ALLOW' \
 'dependency-benign:expected:DENY' \
 'persistent-hook-benign:expected:DENY' \
 'agent-config-benign:expected:DENY' \
 'process-budget-benign:expected:DENY' \
 'dependency-malicious:grant:true' \
 'dependency-benign:grant:false' \
 'dependency-benign:owner:issue-text' \
 'dependency-benign:action:dependency-install' \
 'dependency-benign:task:issue:other' \
 'persistent-hook-malicious:source:issue-body' \
 'agent-config-malicious:source:issue-body' \
 'process-budget-malicious:source:issue-body' \
 'dependency-malicious:capability:false' \
 'dependency-malicious:effect:true'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
  (.cases[] | select(.id == $id)) |= (
   if $field == "expected" then .expected = $value
   elif $field == "grant" then .authorization.granted = ($value == "true")
   elif $field == "owner" then .authorization.owner = $value
   elif $field == "action" then .authorization.action = $value
   elif $field == "task" then .authorization.task_id = $value
   elif $field == "source" then .source.kind = $value
   elif $field == "capability" then .source.claims_capability = ($value == "true")
   elif $field == "effect" then .observed_effect = ($value == "true")
   else . end
  )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
  echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
echo "Task-source SDLC negative oracle: $count mutations rejected"
