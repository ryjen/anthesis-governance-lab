#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/root-revocation-quiescence-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || { echo "invalid root quiescence fixture path" >&2; exit 1; }
command -v jq >/dev/null || exit 1
jq -e '
  def derived:
    if .old_root_new_commit or .old_root_support_live or (.retired_epoch_rejected | not) or
       (.independent_root_preserved | not) then "NOT_QUIESCENT"
    elif (.cut_durable | not) or (.provider_enumerated | not) or (.provider_fenced | not) or
         (.frontier_known | not) or (.handoff_matched | not) or
         (.certificate_consistent | not) or .retries_exhausted then "INDETERMINATE"
    else "QUIESCENT" end;
  . as $root |
  .version == "anthesis-governance-lab.root-quiescence/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_credentials == false and .requires_network == false and
  .source == "arxiv:2609.21284v1" and
  (.assumptions | type == "array" and length >= 3) and
  (.cases | type == "array" and length == 12) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.root | type == "string" and startswith("root:")) and
    (.epoch | type == "number" and . >= 0) and
    (.cut_generation | type == "number" and . > 0) and
    (.carrier | type == "string" and startswith("carrier:")) and
    (.provider | type == "string" and startswith("provider:")) and
    (.sink | type == "string" and startswith("sink:")) and
    (.effect_id | type == "string" and startswith("effect:")) and
    (.cut_durable | type == "boolean") and
    (.provider_enumerated | type == "boolean") and
    (.provider_fenced | type == "boolean") and
    (.frontier_known | type == "boolean") and
    (.old_root_new_commit | type == "boolean") and
    (.old_root_support_live | type == "boolean") and
    (.precut_accepted_late_settlement | type == "boolean") and
    (.retired_epoch_rejected | type == "boolean") and
    (.independent_root_preserved | type == "boolean") and
    (.handoff_matched | type == "boolean") and
    (.certificate_consistent | type == "boolean") and
    (.retries_exhausted | type == "boolean") and
    (.expected | IN("QUIESCENT","NOT_QUIESCENT","INDETERMINATE")) and
    (.expected == derived)
  ) and
  ([
    ["cancellation-ack-only","NOT_QUIESCENT"],
    ["process-token-revocation-only","NOT_QUIESCENT"],
    ["durable-cut-unfenced-sink","NOT_QUIESCENT"],
    ["cut-plus-provider-fence","QUIESCENT"],
    ["precut-accepted-late-settlement","QUIESCENT"],
    ["stale-worker-retired-epoch","NOT_QUIESCENT"],
    ["shared-worker-exact-rebind","QUIESCENT"],
    ["provider-enumeration-missing","INDETERMINATE"],
    ["duplicated-handoff-token","INDETERMINATE"],
    ["conflicting-certificate-revision","INDETERMINATE"],
    ["timeout-retry-exhaustion","INDETERMINATE"],
    ["unrelated-root-preserved","QUIESCENT"]
  ] | all(.[]; . as $pair | any($root.cases[]; .id == $pair[0] and .expected == $pair[1]))) and
  ([.cases[] | {id,cut_durable,provider_enumerated,provider_fenced,frontier_known,old_root_new_commit,old_root_support_live,precut_accepted_late_settlement,retired_epoch_rejected,independent_root_preserved,handoff_matched,certificate_consistent,retries_exhausted}] | sort_by(.id)) ==
  ([
    ["cancellation-ack-only",false,true,false,true,true,false,false,true,true,true,true,false],
    ["process-token-revocation-only",false,true,true,true,false,true,false,true,true,true,true,false],
    ["durable-cut-unfenced-sink",true,true,false,true,true,false,false,true,true,true,true,false],
    ["cut-plus-provider-fence",true,true,true,true,false,false,false,true,true,true,true,false],
    ["precut-accepted-late-settlement",true,true,true,true,false,false,true,true,true,true,true,false],
    ["stale-worker-retired-epoch",true,true,true,true,true,false,false,false,true,true,true,false],
    ["shared-worker-exact-rebind",true,true,true,true,false,false,false,true,true,true,true,false],
    ["provider-enumeration-missing",true,false,true,true,false,false,false,true,true,true,true,false],
    ["duplicated-handoff-token",true,true,true,true,false,false,false,true,true,false,true,false],
    ["conflicting-certificate-revision",true,true,true,true,false,false,false,true,true,true,false,false],
    ["timeout-retry-exhaustion",true,true,true,true,false,false,false,true,true,true,true,true],
    ["unrelated-root-preserved",true,true,true,true,false,false,false,true,true,true,true,false]
  ] | map({
    id:.[0],cut_durable:.[1],provider_enumerated:.[2],provider_fenced:.[3],
    frontier_known:.[4],old_root_new_commit:.[5],old_root_support_live:.[6],
    precut_accepted_late_settlement:.[7],retired_epoch_rejected:.[8],
    independent_root_preserved:.[9],handoff_matched:.[10],
    certificate_consistent:.[11],retries_exhausted:.[12]
  }) | sort_by(.id)) and
  any(.cases[]; .id == "precut-accepted-late-settlement" and .precut_accepted_late_settlement == true and .old_root_new_commit == false) and
  any(.cases[]; .id == "shared-worker-exact-rebind" and .carrier == "carrier:shared-1" and .independent_root_preserved == true)
' "$fixture" >/dev/null || { echo "root quiescence fixture invariants failed" >&2; exit 1; }
echo "Root quiescence fixtures passed (12 synthetic cases)"
