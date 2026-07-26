#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
catalog="$repo_root/docs/scenarios/catalog.json"
demo_catalog="$repo_root/docs/scenarios/demo-catalog.json"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

for file in "$catalog" "$demo_catalog"; do
  [[ -f "$file" && ! -L "$file" ]] || fail "catalog must be a regular file: $file"
done

jq -e '
  .version == "anthesis-governance-lab.catalog/v1" and
  .collections.canonical.path == ".anthesis/scenarios" and
  .collections.canonical.mutable == false and
  .collections.canonical.executes_effects == false and
  .collections.demos.path == ".anthesis/demos" and
  .collections.demos.executes_effects == false and
  (.collections.canonical.scenarios | length == 7) and
  ([.collections.canonical.scenarios[].id] | length == (unique | length)) and
  ([.collections.canonical.scenarios[].path] | length == (unique | length)) and
  all(.collections.canonical.scenarios[];
    (.id | type == "string" and length > 0) and
    (.path | type == "string" and startswith(".anthesis/scenarios/") and endswith(".yaml")) and
    (.expected_decision | IN("allow", "approval_required", "deny")) and
    (.expected_source | IN("policy_rule", "engine_guard")) and
    (.purpose | type == "string" and length > 0)
  )
' "$catalog" >/dev/null || fail "scenario catalog contract is invalid"

jq -e '
  .version == "anthesis-governance-lab.demo-catalog/v1" and
  .executes_effects == false and
  (.packs | length == 4) and
  ([.packs[].id] | length == (unique | length)) and
  ([.packs[].path] | length == (unique | length)) and
  ([.packs[].scenarios[]] | length == 12) and
  ([.packs[].scenarios[].id] | length == (unique | length)) and
  ([.packs[].scenarios[].path] | length == (unique | length)) and
  all(.packs[];
    (.id | type == "string" and length > 0) and
    (.path | type == "string" and startswith(".anthesis/demos/") and (contains("..") | not)) and
    (.scenarios | length == 3) and
    all(.scenarios[];
      (.id | type == "string" and length > 0) and
      (.path | type == "string" and startswith(".anthesis/demos/") and endswith(".yaml") and (contains("..") | not)) and
      (.expected.decision | IN("allow", "approval_required", "deny")) and
      (.expected.source | IN("policy_rule", "policy_default")) and
      (.expected.reason | type == "string" and length > 0) and
      ((.expected.source != "policy_rule") or (.expected.rule_id | type == "string" and length > 0)) and
      (.use_case | type == "string" and length > 0) and
      (.threat | type == "string" and length > 0) and
      (.trust_assumption | type == "string" and length > 0) and
      .executes_effect == false
    )
  )
' "$demo_catalog" >/dev/null || fail "demo catalog contract is invalid"

mapfile -t catalog_paths < <(jq -r '.collections.canonical.scenarios[].path' "$catalog" | sort)
mapfile -t fixture_paths < <(cd "$repo_root" && find .anthesis/scenarios -maxdepth 1 -type f -name '*.yaml' -print | sort)
[[ "${#catalog_paths[@]}" -eq 7 ]] || fail "catalog must contain seven canonical scenarios"
[[ "${catalog_paths[*]}" == "${fixture_paths[*]}" ]] || fail "catalog and canonical fixture paths differ"

mapfile -t demo_catalog_paths < <(jq -r '.packs[].scenarios[].path' "$demo_catalog" | sort)
mapfile -t demo_fixture_paths < <(cd "$repo_root" && find .anthesis/demos -mindepth 2 -maxdepth 2 -type f -name '*.yaml' -print | sort)
[[ "${#demo_catalog_paths[@]}" -eq 12 ]] || fail "demo catalog must contain twelve scenarios"
[[ "${demo_catalog_paths[*]}" == "${demo_fixture_paths[*]}" ]] || fail "demo catalog and fixture paths differ"

for path in "${catalog_paths[@]}" "${demo_catalog_paths[@]}"; do
  [[ -f "$repo_root/$path" && ! -L "$repo_root/$path" ]] || fail "unsafe or missing scenario: $path"
done

for pack in documentation source-code ci-and-release dependencies; do
  [[ -d "$repo_root/.anthesis/demos/$pack" && ! -L "$repo_root/.anthesis/demos/$pack" ]] || fail "missing demo pack: $pack"
  [[ "$(find "$repo_root/.anthesis/demos/$pack" -maxdepth 1 -type f -name '*.yaml' | wc -l)" -eq 3 ]] || fail "demo pack must contain three scenarios: $pack"
done

required_docs=(
  README.md
  docs/runbooks/governance-lab-demo.md
  docs/scenarios/catalog.md
  docs/scenarios/catalog.json
  docs/scenarios/demo-catalog.json
  docs/scenarios/demo-packs.md
  docs/scenarios/authoring.md
  docs/scenarios/interpretation.md
  scripts/acquire-anthesis-lab.sh
  scripts/validate-governance-lab.sh
)
for path in "${required_docs[@]}"; do
  [[ -f "$repo_root/$path" && ! -L "$repo_root/$path" ]] || fail "missing documented path: $path"
done

grep -Fq 'docs/runbooks/governance-lab-demo.md' "$repo_root/README.md" || fail "README does not link the operator runbook"
grep -Fq 'docs/scenarios/demo-packs.md' "$repo_root/README.md" || fail "README does not link demo packs"
grep -Fq 'docs/scenarios/demo-catalog.json' "$repo_root/README.md" || fail "README does not link demo catalog"
grep -Fq 'scripts/acquire-anthesis-lab.sh' "$repo_root/docs/runbooks/governance-lab-demo.md" || fail "runbook acquisition command drifted"
grep -Fq 'scripts/validate-governance-lab.sh' "$repo_root/docs/runbooks/governance-lab-demo.md" || fail "runbook validation command drifted"
grep -Fiq 'issue #9' "$repo_root/docs/runbooks/governance-lab-demo.md" || fail "runbook must identify pending pack runner"

echo "Documentation and scenario catalog validation passed"
