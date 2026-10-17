#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/verifier-collapse-controls-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || { echo "unsafe verifier fixture" >&2; exit 1; }
command -v jq >/dev/null || exit 1
jq -e '
  def valid_tag: (.actual_tag | test("^EVIDENCE:[0-9]+$"));
  def derived:
    if .kind == "grader" then
      if .anchor_available != true then "UNRESOLVED"
      elif .actual_verdict == .expected_verdict then "VALID"
      else "INVALID" end
    elif .kind == "auditor" then
      if .candidate == "generic-v1" then "INVALID"
      elif .candidate == "contract-aware-v1" and
           ((valid_tag and .actual_verdict == "pass") or
            ((valid_tag | not) and .actual_verdict == "fail"))
      then "VALID" else "INVALID" end
    else "INVALID" end;
  . as $root |
  .version == "anthesis-governance-lab.verifier-controls/v1" and
  .synthetic == true and .executes_effects == false and
  .requires_network == false and .requires_credentials == false and
  .requires_live_model == false and
  .reference_oracle == "fixture:locked-reference-v1" and
  .grader_selection_feedback_exposes_oracle == false and
  .subject_revision == "fixture:subject-v1" and
  .harness_revision == "fixture:harness-v1" and
  .evaluator_profile == "fixture:evaluator-profile-v1" and
  .downstream_agent_score == 0.94 and
  (.assumptions | length >= 3) and (.does_not_prove | length >= 3) and
  (.cases | length == 8) and
  ([.cases[].id] | length == (unique | length)) and
  all(.cases[];
    (.id | type == "string" and length > 0) and
    (.kind | IN("grader", "auditor")) and
    (.candidate | IN("anchored-v1","always-pass-v1","generic-v1","contract-aware-v1")) and
    (.actual_verdict | IN("pass","fail","abstain")) and
    (if .kind == "grader" then
      (.expected_verdict | IN("pass","fail","abstain")) and
      .anchor_available == true and
      (.candidate | IN("anchored-v1","always-pass-v1")) and
      (.actual_verdict == (if .candidate == "always-pass-v1" then "pass" else .expected_verdict end))
    else
      .contract_revision == "task-contract-v1" and
      .required_tag == "EVIDENCE:42" and
      (.candidate | IN("generic-v1","contract-aware-v1")) and
      (.actual_tag | type == "string") and
      (.actual_verdict == (if .candidate == "generic-v1" then "fail" elif valid_tag then "pass" else "fail" end))
    end) and
    (.expected_validity | IN("VALID","INVALID","UNRESOLVED")) and
    .expected_validity == derived
  ) and
  ([["anchored-known-good","VALID"],["anchored-known-bad","VALID"],
    ["anchored-abstain","VALID"],["always-pass-known-bad","INVALID"],
    ["always-pass-abstain","INVALID"],["generic-auditor-rejects-valid-tag","INVALID"],
    ["contract-aware-accepts-valid-tag","VALID"],
    ["contract-aware-rejects-missing-value","VALID"]] |
    all(.[]; . as $pair | any($root.cases[]; .id == $pair[0] and .expected_validity == $pair[1]))) and
  ([.cases[] | select(.candidate == "always-pass-v1") | .expected_validity] | all(. == "INVALID")) and
  ([.cases[] | select(.kind == "auditor") | .contract_revision] | all(. == "task-contract-v1"))
' "$fixture" >/dev/null || { echo "verifier control fixture invariants failed" >&2; exit 1; }
echo "Verifier-collapse and contract-aware auditor controls passed (8 synthetic cases)"
