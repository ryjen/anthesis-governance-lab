#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$repo_root/fixtures/external-security/evaluator-control-task-v1.json}"
fail() { echo "error: $*" >&2; exit 1; }
[[ "$#" -le 1 ]] || fail "expected zero or one fixture path"
command -v jq >/dev/null || fail "jq is required"
[[ -f "$fixture" && ! -L "$fixture" ]] || fail "fixture must be a regular, non-symlink file"

# Compute observed performance from locked toy inputs, not the fixture's
# expected score/verdict labels. This is synthetic evidence, not authority.
jq -e '
  def score($labels; $predictions):
    if $predictions == null then null
    else [range(0; ($labels | length)) as $i | select($labels[$i] == $predictions[$i]) | $i] | length end;
  def raw: score(.task_labels; .task_predictions);
  def control: score(.control_labels; .control_predictions);
  def differential:
    (control) as $ctrl |
    if $ctrl == null then null else raw - $ctrl end;
  def attribution:
    if (control) == null or (.conditions_matched | not) or (.control_oracle_valid | not) then "UNRESOLVED"
    elif (.mechanism_active | not) or (.source_requirement_covered | not) then "NOT_SUPPORTED"
    elif raw >= 8 and differential >= 4 then "SUPPORTED"
    else "NOT_SUPPORTED" end;

  . as $root |
  .version == "anthesis-governance-lab.evaluator-controls/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_network == false and .requires_credentials == false and
  .requires_live_model == false and
  (.assumptions | type == "array" and length >= 3) and
  (.does_not_prove | type == "array" and length >= 3) and
  (.proves | type == "array" and length >= 3) and
  (.cases | type == "array" and length == 10) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.candidate_revision | type == "string" and startswith("fixture:")) and
    (.evaluator_revision | type == "string" and startswith("fixture:")) and
    (.harness_revision | type == "string" and startswith("fixture:")) and
    (.condition_revision == ("fixture:condition-" + .id + "-v1")) and
    (.evidence_ref == ("fixture:evidence/" + .candidate_revision + "/" + .evaluator_revision + "/" + .harness_revision + "/" + .condition_revision)) and
    (.mechanism_active | type == "boolean") and
    (.conditions_matched | type == "boolean") and
    (.control_oracle_valid | type == "boolean") and
    (.source_requirement_covered | type == "boolean") and
    (.task_labels | type == "array" and length == 10 and all(.[]; type == "boolean")) and
    (.control_labels | type == "array" and length == 10 and all(.[]; type == "boolean")) and
    (.task_predictions | type == "array" and length == 10 and all(.[]; type == "boolean")) and
    ((.control_predictions == null) or
      (.control_predictions | type == "array" and length == 10 and all(.[]; type == "boolean"))) and
    ((.conditions_matched | not) or .task_labels == .control_labels) and
    (.expected | keys | sort == ["attribution", "control_correct", "differential", "raw_correct"]) and
    (.expected.attribution | IN("SUPPORTED", "NOT_SUPPORTED", "UNRESOLVED")) and
    (.expected.raw_correct | type == "number" and . >= 0 and . <= 10) and
    ((.expected.control_correct == null) or (.expected.control_correct | type == "number" and . >= 0 and . <= 10)) and
    ((.expected.differential == null) or (.expected.differential | type == "number" and . >= -10 and . <= 10)) and
    (. as $c |
      $c.expected.raw_correct == ($c | raw) and
      $c.expected.control_correct == ($c | control) and
      $c.expected.differential == ($c | differential) and
      $c.expected.attribution == ($c | attribution))
  ) and
  ([
    ["real-mechanism-treatment", 10, 5, 5, "SUPPORTED"],
    ["mechanism-absent", 5, 5, 0, "NOT_SUPPORTED"],
    ["placebo-irrelevant-mechanism", 10, 10, 0, "NOT_SUPPORTED"],
    ["overcapable-evaluator-confounder", 10, 10, 0, "NOT_SUPPORTED"],
    ["missing-independent-control", 10, null, null, "UNRESOLVED"],
    ["unmatched-control-population", 10, 5, 5, "UNRESOLVED"],
    ["always-pass-imbalanced-task", 9, 9, 0, "NOT_SUPPORTED"],
    ["proof-of-weakened-specification", 10, 5, 5, "NOT_SUPPORTED"],
    ["invalid-control-oracle", 10, 5, 5, "UNRESOLVED"],
    ["proof-with-strengthened-precondition", 10, 5, 5, "NOT_SUPPORTED"]
  ] | all(.[]; . as $e | any($root.cases[];
    .id == $e[0] and
    .expected.raw_correct == $e[1] and
    .expected.control_correct == $e[2] and
    .expected.differential == $e[3] and
    .expected.attribution == $e[4]
  ))) and
  any(.cases[]; .id == "overcapable-evaluator-confounder" and .mechanism_active == true) and
  any(.cases[]; .id == "always-pass-imbalanced-task" and ([.task_predictions[]] | all(. == true))) and
  any(.cases[]; .id == "proof-of-weakened-specification" and .source_requirement_covered == false) and
  any(.cases[]; .id == "proof-with-strengthened-precondition" and .source_requirement_covered == false) and
  any(.cases[]; .id == "invalid-control-oracle" and .control_oracle_valid == false)
' "$fixture" >/dev/null || fail "evaluator-control task fixture invariants failed"

echo "Evaluator control-task fixture validation passed (10 synthetic cases)"
