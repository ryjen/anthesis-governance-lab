#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture_root="$repo_root/fixtures/inference-integrity"

fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq is required"

validate_fixture() {
  local name="$1"
  local fixture="$fixture_root/$name.json"
  [[ -f "$fixture" && ! -L "$fixture" ]] || fail "unsafe or missing capacity fixture: $name"

  jq -e '
    def execution_ref: type == "string" and startswith("execution:") and length > 10;
    def route_ref: type == "string" and startswith("route:") and length > 6;
    def contribution:
      (.execution_ref | execution_ref) and
      (.estimated_channel_bits | type == "number" and . >= 0);
    def accounting:
      .provisional == true and
      .formula_ref == "provisional:anthesis-108-pending" and
      (.budget_bits | type == "number" and . > 0) and
      (.within_budget | type == "boolean") and
      (.window_ref | type == "string" and startswith("window:")) and
      (.scope.alias | type == "string" and length > 0) and
      (.scope.role | type == "string" and length > 0) and
      (.scope.tenant_ref | type == "string" and startswith("tenant:")) and
      (.scope.session_ref | type == "string" and startswith("session:"));

    (.verification_result.capacity_accounting | accounting) and
    (.verification_result.observations.estimated_channel_bits | type == "number" and . >= 0) and
    (.verification_result.observations.cumulative_channel_bits | type == "number" and . >= 0) and
    (.verification_result.limitations | index("capacity_formula_provisional") != null) and
    (if .case.kind == "bounded_low_capacity" then
       .original_execution.verification_request.capability_class == "bounded_consistency" and
       .verification_result.observations.estimated_channel_bits == .verification_result.observations.cumulative_channel_bits and
       .verification_result.observations.cumulative_channel_bits < .verification_result.capacity_accounting.budget_bits and
       .verification_result.capacity_accounting.within_budget == true and
       .verification_result.verdict == "suspicious" and
       .policy_result.outcome == "increase_sampling"
     elif .case.kind == "aggregate_low_rate_leakage" then
       (.verification_result.capacity_accounting.contributions | length >= 2 and all(.[]; contribution)) and
       ([.verification_result.capacity_accounting.contributions[].estimated_channel_bits] | add) == .verification_result.observations.cumulative_channel_bits and
       all(.verification_result.capacity_accounting.contributions[]; .estimated_channel_bits < $.verification_result.capacity_accounting.budget_bits) and
       .verification_result.observations.cumulative_channel_bits > .verification_result.capacity_accounting.budget_bits and
       .verification_result.capacity_accounting.within_budget == false and
       .verification_result.verdict == "dangerous" and
       .policy_result.outcome == "suspend_model_alias"
     elif .case.kind == "aggregation_window_isolation" then
       (.verification_result.capacity_accounting.included_contributions | length >= 1 and all(.[]; contribution)) and
       (.verification_result.capacity_accounting.excluded_contributions | length >= 1 and all(.[]; contribution and (.reason | type == "string" and length > 0))) and
       ([.verification_result.capacity_accounting.included_contributions[].estimated_channel_bits] | add) == .verification_result.observations.cumulative_channel_bits and
       ([.verification_result.capacity_accounting.included_contributions[].execution_ref] - [.verification_result.capacity_accounting.excluded_contributions[].execution_ref] | length) == (.verification_result.capacity_accounting.included_contributions | length) and
       .verification_result.observations.cumulative_channel_bits < .verification_result.capacity_accounting.budget_bits and
       .verification_result.capacity_accounting.within_budget == true and
       .policy_result.outcome == "allow_with_signal"
     elif .case.kind == "retry_fallback_aggregation" then
       (.original_execution.routing.initial_route_ref | route_ref) and
       (.original_execution.routing.fallback_route_ref | route_ref) and
       .original_execution.routing.initial_route_ref != .original_execution.routing.fallback_route_ref and
       .original_execution.routing.fallback_route_ref == .original_execution.resolved_execution.route_ref and
       (.original_execution.routing.retry_chain | length >= 2 and all(.[]; (.execution_ref | execution_ref) and (.route_ref | route_ref) and (.attempt | type == "number" and . >= 1))) and
       (.verification_result.capacity_accounting.contributions | length == (.original_execution.routing.retry_chain | length) and all(.[]; contribution and (.route_ref | route_ref))) and
       ([.verification_result.capacity_accounting.contributions[].execution_ref] | sort) == ([.original_execution.routing.retry_chain[].execution_ref] | sort) and
       ([.verification_result.capacity_accounting.contributions[].estimated_channel_bits] | add) == .verification_result.observations.cumulative_channel_bits and
       .verification_result.capacity_accounting.route_change_resets_budget == false and
       .verification_result.observations.cumulative_channel_bits > .verification_result.capacity_accounting.budget_bits and
       .verification_result.capacity_accounting.within_budget == false and
       .policy_result.outcome == "suspend_route"
     else false end)
  ' "$fixture" >/dev/null || fail "capacity fixture contract is invalid: $name"
}

validate_fixture bounded-low-capacity
validate_fixture aggregate-low-rate-leakage
validate_fixture aggregation-window-isolation
validate_fixture retry-fallback-aggregation

echo "Inference-integrity provisional capacity validation passed"
