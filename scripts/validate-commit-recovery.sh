#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/commit-recovery-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def verdict:
  if .prior_step.status == "committed" and
     .prior_step.verified_receipt == true and
     .context.run == .grant.run and
     .context.restart_epoch == .grant.restart_epoch and
     .context.policy_revision == .grant.policy_revision and
     .context.attempt == .grant.attempt
  then "ALLOW" else "DENY" end;
 .version == "anthesis-governance-lab.commit-recovery/v1" and
 .synthetic == true and .executes_effects == false and
 .requires_network == false and .requires_credentials == false and
 .policy_revision == "policy:1" and
 (.cases | type == "array" and length == 8) and
 ([.cases[].id] | sort == (["committed-current","proposed-not-committed","indeterminate-not-committed","unverified-commit","retry-old-grant","restart-old-grant","new-run-old-grant","policy-change-old-grant"] | sort)) and
 all(.cases[];
  (.prior_step.status | IN("committed","proposed","indeterminate")) and
  (.prior_step.verified_receipt | type == "boolean") and
  (.context.run | type == "string" and length > 0) and
  (.grant.run | type == "string" and length > 0) and
  (.context.restart_epoch | type == "number") and
  (.grant.restart_epoch | type == "number") and
  (.context.attempt | type == "number") and
  (.grant.attempt | type == "number") and
  (.context.policy_revision | type == "string" and length > 0) and
  (.grant.policy_revision | type == "string" and length > 0) and
  .proposed_step == "advance-sequence" and
  .observed_effect == false and
  .expected == verdict and
  (if .id == "committed-current" then .expected == "ALLOW" else .expected == "DENY" end)) and
 (.proves | type == "array" and length > 0) and
 (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Commit/recovery: 8 synthetic cases passed"
