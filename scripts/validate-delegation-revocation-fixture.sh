#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"
fixture="${DELEGATION_REVOCATION_FIXTURE:-$repo_root/fixtures/external-security/delegation-revocation-v1.json}"
fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"
[[ -f "$fixture" && ! -L "$fixture" ]] || fail "delegation revocation fixture must be a regular file"

# Derive all verdicts from edges, not expected_decision.
# This is a bounded, synthetic disjunctive graph oracle, not a policy server.
jq -e '
  def closure($edges; $start):
    reduce range(0; ($edges | length) + 1) as $i
      ([$start]; . as $known |
       ($known + [$edges[] | select(.from as $src | $known | index($src) != null) | .to]) | unique);
  def survivor_edges($w; $revoked):
    [$w.edges[] | select(.id as $g | $revoked | index($g) == null)];
  def authorized($w; $revoked; $actor):
    closure(survivor_edges($w; $revoked); "root") | index($actor) != null;
  def derived($case; $w; $epoch):
    if $case.proof_state != "verified" or $case.observed_epoch != $epoch
    then "indeterminate"
    elif authorized($w; $case.revoked_grants; $case.actor)
    then "allow" else "deny" end;
  . as $root |
  def world($id): first($root.worlds[] | select(.id == $id));
  # Scenario labels have binding obligations. A validator must not accept
  # a renamed test whose inputs and expected verdict were changed together.
  def required_case($id; $world; $cuts; $actor; $proof; $epoch; $verdict):
    any($root.cases[];
      .id == $id and
      .world == $world and
      .revoked_grants == $cuts and
      .actor == $actor and
      .proof_state == $proof and
      .observed_epoch == $epoch and
      .expected_decision == $verdict);
  # A grant ID alone is not provenance. Lock each synthetic world to the
  # exact grant identity and endpoints, not merely graph reachability.
  # Comparing exact, sorted edge objects also rejects extra or unknown grants.
  def exact_edges($world; $expected):
    (world($world).edges | sort_by(.id)) == ($expected | sort_by(.id));
  .version == "anthesis-governance-lab.external-security-delegation-revocation/v1" and
  .synthetic == true and .non_normative == true and
  .executes_effects == false and .requires_network == false and
  .requires_credentials == false and .requires_live_model == false and
  .model.root == "root" and
  .model.grant_semantics == "disjunctive-independent-paths" and
  .model.authority_epoch == "epoch-2" and
  .model.dispatch_requires_verified_current_authority == true and
  .model.effect_observation == "not_evaluated" and
  ([.worlds[].id] | sort == ["parallel-support", "shared", "single-support"]) and
  exact_edges("shared"; [
    {"id": "g-root-a", "from": "root", "to": "A"},
    {"id": "g-root-b", "from": "root", "to": "B"},
    {"id": "g-root-f", "from": "root", "to": "F"},
    {"id": "g-a-c", "from": "A", "to": "C"},
    {"id": "g-b-c", "from": "B", "to": "C"},
    {"id": "g-c-d", "from": "C", "to": "D"},
    {"id": "g-c-e", "from": "C", "to": "E"}
  ]) and
  exact_edges("single-support"; [
    {"id": "g-root-a", "from": "root", "to": "A"},
    {"id": "g-a-c-primary", "from": "A", "to": "C"}
  ]) and
  exact_edges("parallel-support"; [
    {"id": "g-root-a", "from": "root", "to": "A"},
    {"id": "g-a-c-primary", "from": "A", "to": "C"},
    {"id": "g-a-c-backup", "from": "A", "to": "C"}
  ]) and
  all(.worlds[];
    (.nodes | length >= 3 and (index("root") != null) and length == (unique | length)) and
    ([.edges[].id] | length == (unique | length)) and
    all(.edges[]; (.id | type == "string" and length > 0) and .from != .to)
  ) and
  all(.worlds[];
    . as $w | all(.edges[];
      (.from as $from | .to as $to |
       ($w.nodes | index($from) != null and index($to) != null)))
  ) and
  (.cases | length == 12) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    . as $case |
    ($case.id | type == "string" and length > 0) and
    ($case.world | IN("shared", "single-support", "parallel-support")) and
    ($case.actor as $actor | (world($case.world).nodes | index($actor) != null)) and
    ($case.revoked_grants | type == "array" and length == (unique | length)) and
    all($case.revoked_grants[]; . as $g | any(world($case.world).edges[]; .id == $g)) and
    ($case.proof_state | IN("verified", "untrusted", "incomplete", "unavailable")) and
    ($case.observed_epoch | IN("epoch-1", "epoch-2")) and
    ($case.cached_claim | IN("allow", "deny")) and
    ($case.expected_decision | IN("allow", "deny", "indeterminate")) and
    (derived($case; world($case.world); $root.model.authority_epoch) == $case.expected_decision) and
    ($case.expected_dispatch_eligible == ($case.expected_decision == "allow"))
  ) and
  (.matched_present_pair.worlds == ["single-support", "parallel-support"]) and
  (.matched_present_pair.revoked_grants == ["g-a-c-primary"]) and
  (.matched_present_pair.actor == "C") and
  (.matched_present_pair.expected_post_revocation == ["deny", "allow"]) and
  (world("single-support").nodes == world("parallel-support").nodes) and
  (all(world("single-support").nodes[];
    . as $actor |
    closure(world("single-support").edges; $actor) ==
    closure(world("parallel-support").edges; $actor))) and
  (authorized(world("single-support"); ["g-a-c-primary"]; "C") == false) and
  (authorized(world("parallel-support"); ["g-a-c-primary"]; "C") == true) and
  (authorized(world("shared"); ["g-a-c"]; "C") == true) and
  (authorized(world("shared"); ["g-b-c"]; "C") == true) and
  (authorized(world("shared"); ["g-a-c", "g-b-c"]; "C") == false) and
  (authorized(world("shared"); ["g-a-c", "g-b-c"]; "D") == false) and
  (authorized(world("shared"); ["g-a-c", "g-b-c"]; "E") == false) and
  (authorized(world("shared"); ["g-a-c", "g-b-c"]; "F") == true) and
  required_case("single-edge-a-retains-c"; "shared"; ["g-a-c"]; "C"; "verified"; "epoch-2"; "allow") and
  required_case("cached-deny-current-grant-wins"; "shared"; ["g-a-c"]; "C"; "verified"; "epoch-2"; "allow") and
  (first($root.cases[] | select(.id == "cached-deny-current-grant-wins")).cached_claim == "deny") and
  required_case("single-edge-b-retains-descendant"; "shared"; ["g-b-c"]; "D"; "verified"; "epoch-2"; "allow") and
  required_case("joint-edge-batch-revokes-shared"; "shared"; ["g-a-c", "g-b-c"]; "C"; "verified"; "epoch-2"; "deny") and
  required_case("joint-edge-batch-revokes-cross-domain-child"; "shared"; ["g-a-c", "g-b-c"]; "E"; "verified"; "epoch-2"; "deny") and
  required_case("joint-edge-batch-retains-unrelated-actor"; "shared"; ["g-a-c", "g-b-c"]; "F"; "verified"; "epoch-2"; "allow") and
  required_case("stale-cached-allow-after-batch"; "shared"; ["g-a-c", "g-b-c"]; "D"; "verified"; "epoch-1"; "indeterminate") and
  required_case("incomplete-survivor-edge-inventory"; "shared"; ["g-a-c"]; "C"; "incomplete"; "epoch-2"; "indeterminate") and
  required_case("forged-authority-observation"; "shared"; ["g-a-c"]; "C"; "untrusted"; "epoch-2"; "indeterminate") and
  required_case("authority-owner-unavailable"; "shared"; ["g-a-c", "g-b-c"]; "C"; "unavailable"; "epoch-2"; "indeterminate") and
  required_case("single-grant-future-deny"; "single-support"; ["g-a-c-primary"]; "C"; "verified"; "epoch-2"; "deny") and
  required_case("parallel-grant-future-allow"; "parallel-support"; ["g-a-c-primary"]; "C"; "verified"; "epoch-2"; "allow") and
  (.proves | type == "array" and length >= 3) and
  (.does_not_prove | type == "array" and length >= 3)
' "$fixture" >/dev/null || fail "delegation-revocation derived graph and evidence invariants are not preserved"

echo "delegation-revocation fixture: graph-derived positive, batch, stale, and residual-history cases verified (synthetic; no effects)"
