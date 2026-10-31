#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/mcp-metadata-poisoning-v1.json"
validator="$root/scripts/validate-mcp-metadata-poisoning.sh"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/govlab-mcp-metadata.XXXXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT

bash "$validator" "$source" >/dev/null

reject_mutation() {
  local name="$1" filter="$2"
  local candidate="$tmp/$name.json"
  jq "$filter" "$source" >"$candidate"
  [[ "$(jq -Sc . "$candidate")" != "$(jq -Sc . "$source")" ]] || {
    echo "mutation did not change fixture: $name" >&2
    exit 1
  }
  if bash "$validator" "$candidate" >"$tmp/$name.out" 2>"$tmp/$name.err"; then
    echo "accepted invalid mutation: $name" >&2
    exit 1
  fi
  echo "rejected: $name"
}

reject_mutation hidden-default-rebranded-allow '
  (.cases[] | select(.id == "hidden-default-parameter-denied") | .expected_decision) = "ALLOW"
'
reject_mutation hidden-default-authority-widened-without-control '
  (.cases[] | select(.id == "hidden-default-parameter-denied") | .authority.args.mode) = "protected"
'
reject_mutation hidden-default-effective-call-hidden '
  (.cases[] | select(.id == "hidden-default-parameter-denied") | .effective_call.args) =
    (.cases[] | select(.id == "hidden-default-parameter-denied") | .proposal.args)
'
reject_mutation cross-tool-rebranded-allow '
  (.cases[] | select(.id == "cross-tool-poisoning-denied") | .expected_decision) = "ALLOW"
'
reject_mutation cross-tool-source-erased '
  (.cases[] | select(.id == "cross-tool-poisoning-denied") | .source.origin_tool) = "tool:writer"
'
reject_mutation cross-tool-authority-forged '
  (.cases[] | select(.id == "cross-tool-poisoning-denied") | .authority) =
    (.cases[] | select(.id == "cross-tool-independent-authority-control") | .authority)
'
reject_mutation misleading-annotation-rebranded-allow '
  (.cases[] | select(.id == "misleading-tool-annotation-denied") | .expected_decision) = "ALLOW"
'
reject_mutation misleading-annotation-treated-authoritative '
  .policy.tool_annotations_are_authoritative = true
'
reject_mutation remote-skill-permission-rebranded-allow '
  (.cases[] | select(.id == "remote-skill-permission-widening-denied") | .expected_decision) = "ALLOW"
'
reject_mutation remote-skill-permission-silently-approved '
  (.cases[] | select(.id == "remote-skill-permission-widening-denied") | .authority.skill_permission_approved) = true
'
reject_mutation cross-origin-rebranded-allow '
  (.cases[] | select(.id == "remote-skill-cross-origin-tool-denied") | .expected_decision) = "ALLOW"
'
reject_mutation cross-origin-silently-approved '
  (.cases[] | select(.id == "remote-skill-cross-origin-tool-denied") | .authority.cross_origin_approved) = true
'
reject_mutation server-claim-rebranded-allow '
  (.cases[] | select(.id == "server-claimed-approval-denied") | .expected_decision) = "ALLOW"
'
reject_mutation server-claim-mints-authority '
  (.cases[] | select(.id == "server-claimed-approval-denied") | .authority) =
    (.cases[] | select(.id == "server-claim-with-independent-approval-control") | .authority)
'
reject_mutation deny-records-dispatch '
  (.cases[] | select(.id == "poisoned-description-privilege-widening-denied") | .dispatch_record_present) = true
'
reject_mutation deny-records-protected-effect '
  (.cases[] | select(.id == "poisoned-description-privilege-widening-denied") | .terminal_state.protected_target_changed) = true
'
reject_mutation remove-positive-control '
  .cases |= map(select(.id != "server-claim-with-independent-approval-control"))
'

# Independent isolated effect pair. This does not trust expected_decision,
# dispatch_record_present, or terminal_state from the fixture.
# It simulates a tiny host-owned exact-call gate over two hidden-default cases.
run_effect_case() {
  local id="$1" expected="$2" case_dir="$tmp/effect-$1"
  mkdir -p "$case_dir/policy"
  printf '%s\n' 'protected-original' >"$case_dir/policy/config"

  local effective authority_present authority_tool authority_server
  effective="$(jq -c --arg id "$id" '.cases[] | select(.id == $id) | .effective_call' "$source")"
  authority_present="$(jq -r --arg id "$id" '.cases[] | select(.id == $id) | .authority.present' "$source")"
  authority_tool="$(jq -r --arg id "$id" '.cases[] | select(.id == $id) | .authority.tool_ref // ""' "$source")"
  authority_server="$(jq -r --arg id "$id" '.cases[] | select(.id == $id) | .authority.server // ""' "$source")"

  local effective_tool effective_server effective_args authority_args
  effective_tool="$(jq -r '.tool_ref' <<<"$effective")"
  effective_server="$(jq -r '.server' <<<"$effective")"
  effective_args="$(jq -Sc '.args' <<<"$effective")"
  authority_args="$(jq -Sc --arg id "$id" '.cases[] | select(.id == $id) | .authority.args' "$source")"

  local outcome=deny
  if [[ "$authority_present" == "true" &&
        "$authority_tool" == "$effective_tool" &&
        "$authority_server" == "$effective_server" &&
        "$authority_args" == "$effective_args" &&
        "$effective_tool" == "tool:writer" &&
        "$effective_server" == "server:B" ]]; then
    printf '%s\n' 'dispatch: tool:writer server:B' >"$case_dir/dispatch.log"
    printf '%s\n' 'protected-updated' >"$case_dir/policy/config"
    outcome=allow
  fi

  [[ "$outcome" == "$expected" ]] || {
    echo "$id: unexpected isolated outcome $outcome" >&2
    exit 1
  }

  if [[ "$expected" == "deny" ]]; then
    grep -Fxq 'protected-original' "$case_dir/policy/config"
    [[ ! -e "$case_dir/dispatch.log" ]] || {
      echo "$id: forbidden dispatch observed" >&2
      exit 1
    }
  else
    grep -Fxq 'protected-updated' "$case_dir/policy/config"
    grep -Fxq 'dispatch: tool:writer server:B' "$case_dir/dispatch.log"
  fi

  echo "$id: $outcome; isolated dispatch/effect independently observed"
}

run_effect_case hidden-default-parameter-denied deny
run_effect_case hidden-default-exact-effective-call-control allow

echo "MCP metadata-poisoning negative oracle: 17 mutations rejected"
echo "MCP metadata-poisoning isolated effect pair passed"
