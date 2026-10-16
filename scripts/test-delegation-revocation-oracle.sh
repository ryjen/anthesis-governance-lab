#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$repo_root/fixtures/external-security/delegation-revocation-v1.json"
validator="$repo_root/scripts/validate-delegation-revocation-fixture.sh"
command -v jq >/dev/null || { echo "jq required" >&2; exit 1; }
[[ -f "$fixture" && -f "$validator" ]] || { echo "fixture or validator missing" >&2; exit 1; }

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
bash -n "$validator"
bash "$validator" >/dev/null

reject_mutation() {
  local id="$1" filter="$2"
  local candidate="$work/$id.json"
  jq "$filter" "$fixture" > "$candidate"
  [[ -s "$candidate" ]] || { echo "mutation empty: $id" >&2; exit 1; }
  if [[ "$(jq -S -c . "$fixture")" == "$(jq -S -c . "$candidate")" ]]; then
    echo "mutation not applied: $id" >&2
    exit 1
  fi
  if DELEGATION_REVOCATION_FIXTURE="$candidate" bash "$validator" > "$work/$id.out" 2>&1; then
    echo "validator incorrectly accepted $id" >&2
    cat "$work/$id.out" >&2
    exit 1
  fi
  echo "rejected: $id"
}

# Couple scenario inputs to the label so an attacker cannot rewrite the
# scenario and its expected result together and still get a green check.
reject_mutation named-batch-masked '
  (.cases[] | select(.id == "joint-edge-batch-revokes-shared") | .revoked_grants) = ["g-a-c"] |
  (.cases[] | select(.id == "joint-edge-batch-revokes-shared") | .expected_decision) = "allow" |
  (.cases[] | select(.id == "joint-edge-batch-revokes-shared") | .expected_dispatch_eligible) = true
'
reject_mutation forged-proof-laundered '
  (.cases[] | select(.id == "forged-authority-observation") | .proof_state) = "verified" |
  (.cases[] | select(.id == "forged-authority-observation") | .expected_decision) = "allow" |
  (.cases[] | select(.id == "forged-authority-observation") | .expected_dispatch_eligible) = true
'
reject_mutation stale-epoch-laundered '
  (.cases[] | select(.id == "stale-cached-allow-after-batch") | .observed_epoch) = "epoch-2" |
  (.cases[] | select(.id == "stale-cached-allow-after-batch") | .expected_decision) = "deny" |
  (.cases[] | select(.id == "stale-cached-allow-after-batch") | .expected_dispatch_eligible) = false
'
reject_mutation misleading-label '
  (.cases[] | select(.id == "single-edge-a-retains-c") | .actor) = "F"
'
reject_mutation dropped-alternate-grant '
  (.worlds[] | select(.id == "parallel-support") | .edges) |= map(select(.id != "g-a-c-backup")) |
  (.cases[] | select(.id == "parallel-grant-future-allow") | .expected_decision) = "deny" |
  (.cases[] | select(.id == "parallel-grant-future-allow") | .expected_dispatch_eligible) = false
'
# Mutations preserve modeled reachability and decisions, but falsify
# the named grant's provenance. The original graph-only oracle accepted them.
reject_mutation swapped-shared-edge-origins '
  (.worlds[] | select(.id == "shared") | .edges) |=
    map(if .id == "g-a-c" then .from = "B"
        elif .id == "g-b-c" then .from = "A"
        else . end)
'
reject_mutation rerouted-parallel-backup '
  (.worlds[] | select(.id == "parallel-support") | .edges[] |
    select(.id == "g-a-c-backup") | .from) = "root"
'
# Cached claims are scenario identity, not merely inert model data: removing
# an allow from either named stale/history counterexample must fail closed.
reject_mutation stale-cached-allow-relabeled '
  (.cases[] | select(.id == "stale-cached-allow-after-batch") | .cached_claim) = "deny"
'
reject_mutation future-single-grant-cached-allow-relabeled '
  (.cases[] | select(.id == "single-grant-future-deny") | .cached_claim) = "deny"
'
reject_mutation cached-deny-positive-removed '
  (.cases[] | select(.id == "cached-deny-current-grant-wins") | .cached_claim) = "allow"
'
reject_mutation false-result '
  (.cases[] | select(.id == "joint-edge-batch-revokes-shared") | .expected_decision) = "allow" |
  (.cases[] | select(.id == "joint-edge-batch-revokes-shared") | .expected_dispatch_eligible) = true
'

echo "delegation-revocation oracle mutation regressions passed (11 rejected)"
