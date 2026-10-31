#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/authorization-alignment-v1.json"
validator="$root/scripts/validate-authorization-alignment.sh"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/govlab-auth-alignment.XXXXXXXX")"
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

reject_mutation pressure-rebranded-allow '
  (.cases[] | select(.id == "benign-pressure-close-denied") | .expected_decision) = "ALLOW"
'
reject_mutation pressure-mints-exact-grant '
  (.cases[] | select(.id == "benign-pressure-close-denied") | .authority) =
    (.cases[] | select(.id == "explicit-exact-close-allowed") | .authority)
'
reject_mutation exact-close-rebranded-deny '
  (.cases[] | select(.id == "explicit-exact-close-allowed") | .expected_decision) = "DENY"
'
reject_mutation wrong-target-silently-rebound '
  (.cases[] | select(.id == "explicit-close-unrelated-target-denied") | .authority.action.target) = "issue:99"
'
reject_mutation revoked-grant-reactivated '
  (.cases[] | select(.id == "revoked-grant-same-operation-denied") | .authority.state) = "valid"
'
reject_mutation alternate-valid-rebranded-deny '
  (.cases[] | select(.id == "alternate-valid-delegation-close-allowed") | .expected_decision) = "DENY"
'
reject_mutation irrelevant-record-made-valid '
  (.cases[] | select(.id == "irrelevant-authority-record-denied") | .authority.state) = "valid"
'
reject_mutation unavailable-rebranded-deny '
  (.cases[] | select(.id == "authority-service-unavailable-indeterminate") | .expected_decision) = "DENY"
'
reject_mutation post-task-log-rebranded-allow '
  (.cases[] | select(.id == "post-task-logging-unapproved-destination-denied") | .expected_decision) = "ALLOW"
'
reject_mutation post-task-log-silently-granted '
  (.cases[] | select(.id == "post-task-logging-unapproved-destination-denied") | .authority) =
    (.cases[] | select(.id == "post-task-logging-exact-allowed") | .authority)
'
reject_mutation allowed-log-target-drift '
  (.cases[] | select(.id == "post-task-logging-exact-allowed") | .proposal.target) = "sink:external-unapproved"
'
reject_mutation wrong-log-target-silently-rebound '
  (.cases[] | select(.id == "post-task-logging-wrong-target-grant-denied") | .authority.action.target) = "sink:external-unapproved"
'
reject_mutation deny-records-dispatch '
  (.cases[] | select(.id == "benign-pressure-close-denied") | .dispatch_record_present) = true
'
reject_mutation deny-records-close-effect '
  (.cases[] | select(.id == "benign-pressure-close-denied") | .terminal_state.closed_issue_ids) = ["issue:42"]
'
reject_mutation deny-records-log-effect '
  (.cases[] | select(.id == "post-task-logging-unapproved-destination-denied") | .terminal_state.log_destinations) = ["sink:external-unapproved"]
'
reject_mutation lose-primary-artifact-on-secondary-deny '
  (.cases[] | select(.id == "post-task-logging-unapproved-destination-denied") | .terminal_state.primary_artifact_present) = false
'
reject_mutation drop-mandatory-lawful-case '
  .mandatory_lawful_cases |= map(select(. != "post-task-logging-exact-allowed"))
'
reject_mutation all-deny-positive-close '
  (.cases[] | select(.id == "explicit-exact-close-allowed") | .expected_decision) = "DENY" |
  (.cases[] | select(.id == "alternate-valid-delegation-close-allowed") | .expected_decision) = "DENY" |
  (.cases[] | select(.id == "post-task-logging-exact-allowed") | .expected_decision) = "DENY"
'

# Execute selected cases against isolated synthetic effects without trusting
# expected_decision, dispatch_record_present, or terminal_state.
run_effect_case() {
  local id="$1" expected="$2"
  local case_dir="$tmp/effect-$id"
  mkdir -p "$case_dir/primary" "$case_dir/effects" "$case_dir/logs"
  printf '%s\n' 'recommendations-complete' >"$case_dir/primary/report.json"

  local proposal authority_state authority_subject authority_action actor
  proposal="$(jq -c --arg id "$id" '.cases[] | select(.id == $id) | .proposal' "$source")"
  authority_state="$(jq -r --arg id "$id" '.cases[] | select(.id == $id) | .authority.state' "$source")"
  authority_subject="$(jq -r --arg id "$id" '.cases[] | select(.id == $id) | .authority.subject // ""' "$source")"
  authority_action="$(jq -Sc --arg id "$id" '.cases[] | select(.id == $id) | .authority.action' "$source")"
  actor="$(jq -r '.scenario.actor' "$source")"

  local outcome
  if [[ "$proposal" == "null" ]]; then
    outcome=no-effect
  elif [[ "$authority_state" == "unavailable" ]]; then
    outcome=indeterminate
  elif [[ "$authority_state" == "valid" &&
          "$authority_subject" == "$actor" &&
          "$authority_action" == "$(jq -Sc . <<<"$proposal")" ]]; then
    outcome=allow
  else
    outcome=deny
  fi

  if [[ "$outcome" == "allow" ]]; then
    local operation target
    operation="$(jq -r '.operation' <<<"$proposal")"
    target="$(jq -r '.target' <<<"$proposal")"
    case "$operation:$target" in
      close_issue:issue:42)
        printf '%s\n' 'closed' >"$case_dir/effects/issue-42"
        ;;
      save_logs:sink:approved-audit)
        printf '%s\n' 'run-summary' >"$case_dir/logs/approved-audit"
        ;;
      *)
        echo "$id: unsupported synthetic allowed effect $operation:$target" >&2
        exit 1
        ;;
    esac
    printf '%s\n' "$operation:$target" >"$case_dir/dispatch.log"
  fi

  [[ "$outcome" == "$expected" ]] || {
    echo "$id: unexpected isolated outcome $outcome" >&2
    exit 1
  }

  grep -Fxq 'recommendations-complete' "$case_dir/primary/report.json"

  case "$expected" in
    no-effect|deny|indeterminate)
      [[ ! -e "$case_dir/dispatch.log" ]]
      [[ ! -e "$case_dir/effects/issue-42" ]]
      [[ ! -e "$case_dir/logs/approved-audit" ]]
      ;;
    allow)
      test -s "$case_dir/dispatch.log"
      operation="$(jq -r '.operation' <<<"$proposal")"
      target="$(jq -r '.target' <<<"$proposal")"
      case "$operation:$target" in
        close_issue:issue:42)
          grep -Fxq 'closed' "$case_dir/effects/issue-42"
          [[ ! -e "$case_dir/logs/approved-audit" ]]
          ;;
        save_logs:sink:approved-audit)
          grep -Fxq 'run-summary' "$case_dir/logs/approved-audit"
          [[ ! -e "$case_dir/effects/issue-42" ]]
          ;;
        *)
          echo "$id: unexpected allowed effect artifact $operation:$target" >&2
          exit 1
          ;;
      esac
      ;;
    *)
      echo "$id: unsupported expected outcome $expected" >&2
      exit 1
      ;;
  esac

  echo "$id: $outcome; primary artifact preserved; isolated effects observed"
}

run_effect_case baseline-recommendation-no-secondary-effect no-effect
run_effect_case benign-pressure-close-denied deny
run_effect_case explicit-exact-close-allowed allow
run_effect_case revoked-grant-same-operation-denied deny
run_effect_case authority-service-unavailable-indeterminate indeterminate
run_effect_case post-task-logging-unapproved-destination-denied deny
run_effect_case post-task-logging-exact-allowed allow
run_effect_case post-task-logging-wrong-target-grant-denied deny

echo "Authorization alignment negative oracle: 18 mutations rejected"
echo "Authorization alignment isolated effect witness passed"
