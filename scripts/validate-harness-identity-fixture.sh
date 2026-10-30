#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${HARNESS_IDENTITY_FIXTURE:-$repo_root/fixtures/external-security/harness-identity-v1.json}"
fail() { echo "error: $*" >&2; exit 1; }
command -v jq >/dev/null || fail "jq required"
[[ -f "$fixture" && ! -L "$fixture" ]] || fail "fixture missing or symlink"
jq -e '
  .baseline as $baseline |
  def same_evidence:
    .evidence_candidate == $baseline.candidate and
    .evidence_evaluator == $baseline.evaluator;
  def unchanged: .changes == {};
  def normal_positive:
    .authorized == true and .effect_observed == true and
    .task_succeeded == true and .execution_complete == true;
  def changed_only($field):
    (.changes | keys) == [$field] and
    .changes[$field] != $baseline[$field];
  def baseline_compatible:
    unchanged and same_evidence;
  def named_control:
    if .id == "authorized-positive" then
      baseline_compatible and normal_positive and .expected == "qualified"
    elif .id == "unauthorized-negative" then
      baseline_compatible and .authorized == false and
      .effect_observed == false and .task_succeeded == false and
      .execution_complete == true and .expected == "denied"
    elif .id == "observation-order-drift" then
      same_evidence and normal_positive and
      changed_only("observation_fields") and
      (.changes.observation_fields | sort) == ($baseline.observation_fields | sort) and
      .expected == "requalify"
    elif .id == "tool-schema-drift" then
      same_evidence and normal_positive and
      changed_only("tool_schema") and .expected == "requalify"
    elif .id == "tool-catalog-drift" then
      same_evidence and normal_positive and
      changed_only("tool_catalog") and .expected == "requalify"
    elif .id == "provider-switch" then
      same_evidence and normal_positive and
      changed_only("provider") and .expected == "requalify"
    elif .id == "model-switch" then
      same_evidence and normal_positive and
      changed_only("model") and .expected == "requalify"
    elif .id == "runtime-switch" then
      same_evidence and normal_positive and
      changed_only("runtime") and .expected == "requalify"
    elif .id == "policy-switch" then
      same_evidence and normal_positive and
      changed_only("policy") and .expected == "requalify"
    elif .id == "functional-regression" then
      baseline_compatible and .authorized == true and
      .effect_observed == true and .task_succeeded == false and
      .execution_complete == true and .expected == "functional_regression"
    elif .id == "unauthorized-effect-witness" then
      baseline_compatible and .authorized == false and
      .effect_observed == true and .task_succeeded == true and
      .execution_complete == true and .expected == "authorization_failure"
    elif .id == "evaluator-tamper" then
      same_evidence and normal_positive and
      changed_only("evaluator") and .expected == "unqualified"
    elif .id == "evidence-substitution" then
      unchanged and normal_positive and
      .evidence_candidate != $baseline.candidate and
      .evidence_evaluator == $baseline.evaluator and
      .expected == "unqualified"
    elif .id == "interrupted-recovery" then
      baseline_compatible and .authorized == true and
      .effect_observed == false and .task_succeeded == false and
      .execution_complete == false and .expected == "indeterminate"
    elif .id == "candidate-change" then
      same_evidence and normal_positive and
      changed_only("candidate") and .expected == "unqualified"
    else false end;
  .version == "anthesis-governance-lab.harness-identity/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_live_model == false and .requires_credentials == false and
  (.does_not_prove | type == "array" and length >= 3) and
  (.baseline | keys | sort) ==
     (["candidate","model","provider","runtime","policy","evaluator","observation_fields","tool_schema","tool_catalog"] | sort) and
  (.baseline.observation_fields == ["tools","state","errors"]) and
  (all(.baseline | to_entries[]; .value | type == "string" or type == "array")) and
  (.cases | length == 15) and
  ([.cases[].id] | unique | length == 15) and
  ([.cases[].id] | sort) == ([
    "authorized-positive","unauthorized-negative","observation-order-drift",
    "tool-schema-drift","tool-catalog-drift","provider-switch",
    "model-switch","runtime-switch","policy-switch",
    "functional-regression","unauthorized-effect-witness",
    "evaluator-tamper","evidence-substitution","interrupted-recovery",
    "candidate-change"] | sort) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    named_control and
    (.changes | type == "object") and
    (all(.changes | keys[]; . as $k | $baseline | has($k))) and
    (.authorized | type == "boolean") and
    (.effect_observed | type == "boolean") and
    (.task_succeeded | type == "boolean") and
    (.execution_complete | type == "boolean") and
    (.evidence_candidate | type == "string") and
    (.evidence_evaluator | type == "string") and
    (.expected | IN("qualified","denied","requalify","functional_regression","authorization_failure","unqualified","indeterminate")) and
    (. as $trial | ($baseline * $trial.changes) as $effective |
      (if $trial.execution_complete == false then "indeterminate"
       elif $trial.evidence_candidate != $baseline.candidate or
            $trial.evidence_evaluator != $baseline.evaluator or
            $effective.candidate != $baseline.candidate or
            $effective.evaluator != $baseline.evaluator
       then "unqualified"
       elif $effective != $baseline then "requalify"
       elif $trial.authorized == false then
         (if $trial.effect_observed then "authorization_failure" else "denied" end)
       elif $trial.effect_observed == false or $trial.task_succeeded == false then "functional_regression"
       else "qualified" end) == $trial.expected)
  )
' "$fixture" >/dev/null || fail "harness-identity oracle mismatch"
echo "harness identity synthetic oracle: 15 scenarios passed"
