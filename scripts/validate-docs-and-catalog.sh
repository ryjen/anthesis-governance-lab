#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
catalog="$repo_root/docs/scenarios/catalog.json"

fail() {
  echo "error: $*" >&2
  exit 1
}

command -v jq >/dev/null || fail "jq is required"
[[ -f "$catalog" && ! -L "$catalog" ]] || fail "catalog must be a regular file"

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

mapfile -t catalog_paths < <(jq -r '.collections.canonical.scenarios[].path' "$catalog" | sort)
mapfile -t fixture_paths < <(
  cd "$repo_root"
  find .anthesis/scenarios -maxdepth 1 -type f -name '*.yaml' -print | sort
)

[[ "${#catalog_paths[@]}" -eq 7 ]] || fail "catalog must contain seven canonical scenarios"
[[ "${catalog_paths[*]}" == "${fixture_paths[*]}" ]] || fail "catalog and canonical fixture paths differ"

for path in "${catalog_paths[@]}"; do
  [[ -f "$repo_root/$path" && ! -L "$repo_root/$path" ]] || fail "unsafe or missing scenario: $path"
done

required_docs=(
  README.md
  docs/runbooks/governance-lab-demo.md
  docs/scenarios/catalog.md
  docs/scenarios/catalog.json
  docs/scenarios/authoring.md
  docs/scenarios/interpretation.md
  scripts/acquire-anthesis-lab.sh
  scripts/validate-governance-lab.sh
)
for path in "${required_docs[@]}"; do
  [[ -f "$repo_root/$path" && ! -L "$repo_root/$path" ]] || fail "missing documented path: $path"
done

grep -Fq 'docs/runbooks/governance-lab-demo.md' "$repo_root/README.md" || fail "README does not link the operator runbook"
grep -Fq 'docs/scenarios/catalog.md' "$repo_root/README.md" || fail "README does not link the scenario catalog"
grep -Fq 'docs/scenarios/authoring.md' "$repo_root/README.md" || fail "README does not link the authoring guide"
grep -Fq 'docs/scenarios/interpretation.md' "$repo_root/README.md" || fail "README does not link the interpretation guide"

grep -Fq 'scripts/acquire-anthesis-lab.sh' "$repo_root/docs/runbooks/governance-lab-demo.md" || fail "runbook acquisition command drifted"
grep -Fq 'scripts/validate-governance-lab.sh' "$repo_root/docs/runbooks/governance-lab-demo.md" || fail "runbook validation command drifted"
grep -Fq 'Pending demo-pack tooling' "$repo_root/docs/runbooks/governance-lab-demo.md" || fail "runbook must mark demo-pack commands as pending"

echo "Documentation and scenario catalog validation passed"
