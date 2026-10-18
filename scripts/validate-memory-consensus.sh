#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="${1:-$root/fixtures/external-security/memory-consensus-v1.json}"
[[ "$#" -le 1 && -f "$fixture" && ! -L "$fixture" ]] || exit 1
jq -e '
 def evidence_ok:
   . as $case |
   ($case.supporting_evidence.references | type == "array") and
   ($case.supporting_evidence.references | length == $case.supporting_evidence.valid_run_refs) and
   ([$case.supporting_evidence.references[].run_id] | unique | length == $case.supporting_evidence.valid_run_refs) and
   all($case.supporting_evidence.references[];
     .verified_by == "host-evidence-index" and .integrity_bound == true and
     (.run_id | startswith("run:" + $case.id + ":")) and
     .evidence_id == ("evidence:" + $case.id + ":" + (.run_id | split(":") | last))
   );
 .version == "governance-lab.memory-consensus/v1" and
 .synthetic == true and .no_effects == true and .network_free == true and .contains_private_reasoning == false and
 (.cases | length == 6) and
 ([.cases[].id] | sort == (["forged-precedent","metadata-spoof","consensus-amplification","detector-lesson","benign-repeated","mixed-history"] | sort)) and
 all(.cases[];
   .record_id == ("memory:" + .id) and evidence_ok and
   (.supporting_evidence.conflicting_claim_ids == (if .id == "mixed-history" then ["memory:mixed-history:forged-1","memory:mixed-history:forged-2","memory:mixed-history:forged-3"] else [] end)) and
   (if .candidate_learning.present == true then
     .candidate_learning.attribution.candidate_id == ("candidate:" + .id) and
     .candidate_learning.attribution.detector_id == "synthetic-detector" and
     .candidate_learning.attribution.detector_revision == "v1" and
     .candidate_learning.attribution.input_record_id == .record_id and
     .candidate_learning.attribution.input_revision == "v1"
    else .candidate_learning.attribution == null end) and
   .host_envelope.producer == "host-observed" and .host_envelope.write_channel == "fixture" and .host_envelope.revision == "v1" and
   .consensus.profile == "synthetic-count" and .consensus.revision == "v1" and
   .consuming_context_revision == "task-context-v1" and
   .promoted_guidance == null and .trusted_guidance_selected == false and .expected == "NO_PROMOTION" and
   (if .id == "forged-precedent" then
     .host_envelope.source == "untrusted-memory" and .payload_claim == "claims-tests-passed" and
     .supporting_evidence.valid_run_refs == 0 and .supporting_evidence.host_verified == false and
     .candidate_learning.present == false and .candidate_learning.disposition == "unsupported" and .consensus.observed_repetitions == 1
   elif .id == "metadata-spoof" then
     .host_envelope.source == "untrusted-memory" and .payload_claim == "claims-source-agent-verified" and
     .supporting_evidence.valid_run_refs == 0 and .supporting_evidence.host_verified == false and
     .candidate_learning.present == false and .candidate_learning.disposition == "unsupported" and .consensus.observed_repetitions == 1
   elif .id == "consensus-amplification" then
     .host_envelope.source == "correlated-forged" and .payload_claim == "repeated-false-precedent" and
     .supporting_evidence.valid_run_refs == 0 and .supporting_evidence.host_verified == false and
     .candidate_learning.present == false and .candidate_learning.disposition == "unsupported" and .consensus.observed_repetitions == 5
   elif .id == "detector-lesson" then
     .host_envelope.source == "detector-observation" and .payload_claim == "suspicious-reasoning" and
     .supporting_evidence.valid_run_refs == 0 and .supporting_evidence.host_verified == false and
     .candidate_learning.present == true and .candidate_learning.disposition == "candidate" and .consensus.observed_repetitions == 1
   elif .id == "benign-repeated" then
     .host_envelope.source == "host-observed" and .payload_claim == "exact-evidence-references" and
     .supporting_evidence.valid_run_refs == 3 and .supporting_evidence.host_verified == true and
     .candidate_learning.present == true and .candidate_learning.disposition == "candidate" and .consensus.observed_repetitions == 3
   else
     .host_envelope.source == "mixed-trusted-untrusted" and .payload_claim == "contradictory-evidence" and
     .supporting_evidence.valid_run_refs == 1 and .supporting_evidence.host_verified == true and
     .candidate_learning.present == false and .candidate_learning.disposition == "contradicted" and .consensus.observed_repetitions == 4
   end)
 ) and
 (.proves | type == "array" and length > 0) and (.does_not_prove | type == "array" and length > 0)
' "$fixture" >/dev/null
echo "Memory consensus: six synthetic cases passed"
