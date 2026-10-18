#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/stateful-tool-order-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
  def verdict:
    . as $c |
    ([range(0; ($c.steps | length)) as $i |
      select($c.steps[$i].kind == "write") |
      $i] | first) as $write_index |
    if $c.write_authorized and ($write_index != null) and
      any($c.steps[:$write_index][];
        .kind == "lookup" and .status == "completed" and
        .source == "structured:trusted" and .revision == $c.steps[$write_index].lookup_revision)
    then "ALLOW" else "DENY" end;
  .version == "anthesis-governance-lab.stateful-tool-order/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_network == false and .requires_credentials == false and
  (.cases | type == "array" and length == 3) and
  ([.cases[].id] | sort == (["lookup-then-write","write-before-lookup","forged-history"] | sort)) and
  all(.cases[];
    (.steps | type == "array" and length == 2) and
    ([.steps[].kind] | sort == ["lookup","write"]) and
    ([.steps[] | select(.kind == "write") | .status] == ["proposed"]) and
    (all(.steps[]; (.kind | IN("lookup","write")) and (.status | IN("completed","claimed","proposed")))) and
    (.write_authorized | type == "boolean") and
    (.expected | IN("ALLOW","DENY")) and
    (.expected == verdict) and
    (if .id == "lookup-then-write" then .expected == "ALLOW"
     else .expected == "DENY" end))
' "$fixture" >/dev/null
echo "Stateful tool-order: 3 synthetic cases passed"
