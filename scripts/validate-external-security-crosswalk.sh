#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
crosswalk="$repo_root/docs/scenarios/external-security-crosswalk.json"
demo_catalog="$repo_root/docs/scenarios/demo-catalog.json"
inference_catalog="$repo_root/.anthesis/catalogs/inference-integrity-scenarios.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

for file in "$crosswalk" "$demo_catalog" "$inference_catalog"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "required crosswalk input must be a regular file: $file"
done

jq -e '
  .version == "anthesis-governance-lab.external-security-crosswalk/v1" and
  .status == "non_normative_mapping" and
  .certification == false and
  .executes_effects == false and
  (.rows | length > 0) and
  ([.rows[].id] | length == (unique | length)) and
  all(.rows[];
    (.id | type == "string" and length > 0) and
    (.framework | type == "string" and length > 0) and
    (.external_ref | type == "string" and length > 0) and
    (.topic | type == "string" and length > 0) and
    (.coverage | IN("demonstrated", "partial", "runtime-dependent", "not-demonstrated", "not-applicable")) and
    (.scenario_refs | type == "array") and
    (.inference_scenario_refs | type == "array") and
    (.proves | type == "array") and
    (.does_not_prove | type == "array" and length > 0) and
    (.next_gap | type == "string" and length > 0) and
    ((.coverage != "demonstrated") or ((.scenario_refs | length) + (.inference_scenario_refs | length) > 0)) and
    ((.coverage != "not-applicable") or ((.scenario_refs | length) == 0 and (.inference_scenario_refs | length) == 0))
  )
' "$crosswalk" >/dev/null || fail "external security crosswalk contract is invalid"

mapfile -t demo_ids < <(jq -r '.packs[].scenarios[].id' "$demo_catalog" | sort -u)
mapfile -t inference_ids < <(jq -r '.scenarios[].id' "$inference_catalog" | sort -u)

contains_id() {
  local needle="$1"
  shift
  local candidate
  for candidate in "$@"; do
    [[ "$candidate" == "$needle" ]] && return 0
  done
  return 1
}

while IFS= read -r id; do
  contains_id "$id" "${demo_ids[@]}" || fail "crosswalk references unknown demo scenario: $id"
done < <(jq -r '.rows[].scenario_refs[]?' "$crosswalk")

while IFS= read -r id; do
  contains_id "$id" "${inference_ids[@]}" || fail "crosswalk references unknown inference scenario: $id"
done < <(jq -r '.rows[].inference_scenario_refs[]?' "$crosswalk")

for required in \
  cosai-mcp-complete-mediation \
  cosai-mcp-provenance-evidence \
  cosai-agentic-iam-delegation \
  owasp-llm-2026-excessive-agency \
  owasp-agentic-asi02-tool-misuse \
  owasp-agentic-asi03-identity-privilege \
  owasp-agentic-asi04-supply-chain \
  owasp-agentic-asi06-memory-context \
  owasp-agentic-asi07-inter-agent \
  owasp-aibom-artifact-identity \
  cosai-agent-manifest-action-binding; do
  jq -e --arg id "$required" 'any(.rows[]; .id == $id)' "$crosswalk" >/dev/null \
    || fail "required external security coverage row is missing: $required"
done

jq -e '
  any(.rows[]; .coverage == "demonstrated") and
  any(.rows[]; .coverage == "partial") and
  any(.rows[]; .coverage == "runtime-dependent") and
  any(.rows[]; .coverage == "not-demonstrated")
' "$crosswalk" >/dev/null || fail "crosswalk must preserve distinct coverage states"

jq -e '
  .rows[] |
  select(.id == "cosai-mcp-complete-mediation") |
  .coverage == "runtime-dependent" and
  any(.does_not_prove[]; contains("unreachable"))
' "$crosswalk" >/dev/null || fail "complete-mediation row must preserve runtime assurance limitation"

jq -e '
  .rows[] |
  select(.id == "owasp-aibom-artifact-identity") |
  .coverage == "not-demonstrated" and
  any(.does_not_prove[]; contains("authorizes"))
' "$crosswalk" >/dev/null || fail "AIBOM row must preserve evidence-versus-authority limitation"

echo "External agent-security crosswalk validation passed"
