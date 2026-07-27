#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
catalog="$repo_root/docs/scenarios/demo-catalog.json"
binary="${ANTHESIS_LAB_BIN:-$repo_root/.anthesis/bin/anthesis-lab}"

fail() { echo "error: $*" >&2; exit 1; }
usage() {
  cat <<'EOF'
Usage:
  scripts/run-demo-pack.sh --list
  scripts/run-demo-pack.sh <pack>

Runs one cataloged non-canonical demo pack through the verified anthesis-lab
binary. Declared effects are evaluated only and are never executed.
EOF
}

command -v jq >/dev/null || fail "jq is required"
[[ -f "$catalog" && ! -L "$catalog" ]] || fail "demo catalog must be a regular file"

if [[ "${1:-}" == "--list" ]]; then
  [[ "$#" -eq 1 ]] || fail "--list accepts no additional arguments"
  jq -r '.packs[].id' "$catalog"
  exit 0
fi

[[ "$#" -eq 1 ]] || { usage >&2; exit 2; }
pack="$1"
[[ "$pack" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "invalid pack name: $pack"

pack_count="$(jq -r --arg pack "$pack" '[.packs[] | select(.id == $pack)] | length' "$catalog")"
[[ "$pack_count" == "1" ]] || fail "unknown or duplicate demo pack: $pack"

pack_path="$(jq -er --arg pack "$pack" '.packs[] | select(.id == $pack) | .path' "$catalog")"
[[ "$pack_path" == ".anthesis/demos/$pack" ]] || fail "catalog pack path is not canonical: $pack_path"
[[ "$pack_path" != *".."* && "$pack_path" != /* && "$pack_path" != ~* ]] || fail "unsafe pack path: $pack_path"
[[ -d "$repo_root/$pack_path" && ! -L "$repo_root/$pack_path" ]] || fail "demo pack directory is missing or unsafe: $pack_path"

mapfile -t catalog_scenarios < <(jq -r --arg pack "$pack" '.packs[] | select(.id == $pack) | .scenarios[].path' "$catalog" | sort)
mapfile -t fixture_scenarios < <(cd "$repo_root" && find "$pack_path" -maxdepth 1 -type f -name '*.yaml' -print | sort)
[[ "${#catalog_scenarios[@]}" -gt 0 ]] || fail "demo pack contains no cataloged scenarios: $pack"
[[ "${catalog_scenarios[*]}" == "${fixture_scenarios[*]}" ]] || fail "catalog and fixture paths differ for pack: $pack"

for scenario in "${catalog_scenarios[@]}"; do
  [[ "$scenario" == "$pack_path/"*.yaml ]] || fail "scenario is outside selected pack: $scenario"
  [[ -f "$repo_root/$scenario" && ! -L "$repo_root/$scenario" ]] || fail "scenario is missing or unsafe: $scenario"
done

[[ -x "$binary" ]] || fail "verified anthesis-lab binary not found: $binary"

work_dir="$(mktemp -d "$repo_root/.anthesis/demo-pack.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
report="$work_dir/report.json"

set +e
"$binary" test \
  --repo "$repo_root" \
  --scenarios "$pack_path" \
  --format json >"$report"
status=$?
set -e

if [[ ! -s "$report" ]]; then
  fail "anthesis-lab produced no report for pack $pack (exit $status)"
fi

jq -e \
  --argjson expected_total "${#catalog_scenarios[@]}" \
  '.version == "anthesis.test-report/v1" and
   .total == $expected_total and
   (.scenarios | length == $expected_total)' \
  "$report" >/dev/null || fail "invalid or incomplete demo-pack report"

mapfile -t expected_ids < <(jq -r --arg pack "$pack" '.packs[] | select(.id == $pack) | .scenarios[].id' "$catalog" | sort)
mapfile -t actual_ids < <(jq -r '.scenarios[].scenario_id' "$report" | sort)
[[ "${expected_ids[*]}" == "${actual_ids[*]}" ]] || fail "report scenario IDs differ from catalog"

cat "$report"
[[ "$status" -eq 0 ]] || exit "$status"
