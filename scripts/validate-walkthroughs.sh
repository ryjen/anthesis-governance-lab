#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
showcase="$repo_root/docs/walkthroughs/showcase.json"
canonical="$repo_root/docs/scenarios/catalog.json"
demos="$repo_root/docs/scenarios/demo-catalog.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
for path in \
  "$showcase" \
  "$canonical" \
  "$demos" \
  "$repo_root/docs/walkthroughs/five-minute-demo.md" \
  "$repo_root/docs/walkthroughs/stakeholder-demo.md"; do
  [[ -f "$path" && ! -L "$path" ]] || fail "walkthrough input must be a regular file: ${path#$repo_root/}"
done

jq -e '
  .version == "anthesis-governance-lab.showcase/v1" and
  .executes_effects == false and
  (.entries | length == 5) and
  ([.entries[].id] | unique | length == 5) and
  ([.entries[].id] == ["allow","approval-required","policy-deny","engine-guard-deny","expectation-drift"]) and
  ([.entries[].kind] == ["scenario","scenario","scenario","scenario","validation_exercise"]) and
  ([.entries[] | select(.kind == "scenario")] | length == 4) and
  all(.entries[] | select(.kind == "scenario");
    (.path | type == "string") and
    (.expected_decision | type == "string") and
    (.expected_source | type == "string")
  )
' "$showcase" >/dev/null || fail "showcase contract is invalid"

validated_scenarios=0
while IFS=$'\t' read -r id path decision source; do
  [[ -f "$repo_root/$path" && ! -L "$repo_root/$path" ]] || fail "showcase scenario is missing or unsafe: $path"
  if [[ "$path" == .anthesis/demos/* ]]; then
    jq -e --arg path "$path" --arg decision "$decision" --arg source "$source" '
      any(.packs[].scenarios[]; .path == $path and .expected.decision == $decision and .expected.source == $source)
    ' "$demos" >/dev/null || fail "showcase demo entry drifted: $id"
  elif [[ "$path" == .anthesis/scenarios/* ]]; then
    jq -e --arg path "$path" --arg decision "$decision" --arg source "$source" '
      any(.collections.canonical.scenarios[]; .path == $path and .expected_decision == $decision and .expected_source == $source)
    ' "$canonical" >/dev/null || fail "showcase canonical entry drifted: $id"
  else
    fail "showcase scenario escaped approved collections: $path"
  fi
  validated_scenarios=$((validated_scenarios + 1))
done < <(jq -r '.entries[] | select(.kind == "scenario") | [.id,.path,.expected_decision,.expected_source] | @tsv' "$showcase")
[[ "$validated_scenarios" -eq 4 ]] || fail "showcase must contain exactly four cataloged scenarios"

jq -e '
  any(.entries[];
    .id == "expectation-drift" and
    .kind == "validation_exercise" and
    .command == "bash scripts/validate-governance-lab.sh" and
    .expected_exit == 0 and
    (.evidence | contains("exit code 7"))
  )
' "$showcase" >/dev/null || fail "expectation-drift showcase entry is invalid"

grep -Fq 'aggregate-demo-packs.sh' "$repo_root/docs/walkthroughs/five-minute-demo.md" || fail "developer walkthrough lacks aggregate command"
grep -Fq '## Situation' "$repo_root/docs/walkthroughs/stakeholder-demo.md" || fail "stakeholder walkthrough lacks Situation"
grep -Fq '## Task' "$repo_root/docs/walkthroughs/stakeholder-demo.md" || fail "stakeholder walkthrough lacks Task"
grep -Fq '## Action' "$repo_root/docs/walkthroughs/stakeholder-demo.md" || fail "stakeholder walkthrough lacks Action"
grep -Fq '## Result' "$repo_root/docs/walkthroughs/stakeholder-demo.md" || fail "stakeholder walkthrough lacks Result"
grep -Fiq 'does not execute' "$repo_root/docs/walkthroughs/stakeholder-demo.md" || fail "stakeholder walkthrough omits evaluator boundary"

echo "Walkthrough showcase validation passed"
