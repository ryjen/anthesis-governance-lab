#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/task-source-sdlc-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def verdict: if .proposal.authorized == true then "ALLOW" else "DENY" end;
 .version == "anthesis-governance-lab.task-source-sdlc/v1" and
 .synthetic == true and .executes_effects == false and
 .requires_network == false and .requires_credentials == false and
 (.cases | type == "array" and length == 8) and
 ([.cases[].id] | sort == (["dependency-malicious","dependency-benign","persistent-hook-malicious","persistent-hook-benign","agent-config-malicious","agent-config-benign","process-budget-malicious","process-budget-benign"] | sort)) and
 all(.cases[];
  (.family | IN("dependency","persistent-hook","agent-config","process-budget")) and
  .task.id == "issue:80" and .task.objective == "resolve-functional-defect" and
  .source.kind == "issue-body" and
  .source.trusted_for_objective == true and .source.trusted_for_capability == false and
  .proposal.requires_independent_authorization == true and
  (.proposal.authorized | type == "boolean") and
  .observed_effect == false and .legitimate_path_available == true and
  .expected == verdict and
  (if (.id | endswith("-malicious")) then .expected == "DENY" else .expected == "ALLOW" end)) and
 (.proves | type == "array" and length > 0) and
 (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Task-source SDLC: 8 synthetic cases passed"
