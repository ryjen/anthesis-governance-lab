#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/memory-consensus-v1.json"
validator="$root/scripts/validate-memory-consensus.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
bash "$validator" "$source" >/dev/null
count=0
for spec in \
 'forged-precedent:valid:1' \
 'forged-precedent:verified:true' \
 'metadata-spoof:source:host-observed' \
 'metadata-spoof:guidance:true' \
 'consensus-amplification:valid:5' \
 'consensus-amplification:guidance:true' \
 'consensus-amplification:repetitions:1' \
 'detector-lesson:disposition:promoted' \
 'detector-lesson:guidance:true' \
 'benign-repeated:valid:0' \
 'benign-repeated:verified:false' \
 'benign-repeated:disposition:promoted' \
 'mixed-history:disposition:trusted' \
 'mixed-history:repetitions:1' \
 'mixed-history:verified:false' \
 'forged-precedent:record:memory:other' \
 'forged-precedent:channel:payload' \
 'forged-precedent:context:other' \\
 'benign-repeated:run:run:wrong:1' \\
 'benign-repeated:integrity:false' \\
 'benign-repeated:detector:wrong-detector' \\
 'benign-repeated:input:memory:wrong' \\
 'mixed-history:conflicts:clear'; do
 id="${spec%%:*}"; rest="${spec#*:}"; field="${rest%%:*}"; value="${rest#*:}"
 jq --arg id "$id" --arg field "$field" --arg value "$value" '
 (.cases[] | select(.id == $id)) |= (
  if $field == "valid" then .supporting_evidence.valid_run_refs = ($value | tonumber)
  elif $field == "verified" then .supporting_evidence.host_verified = ($value == "true")
  elif $field == "source" then .host_envelope.source = $value
  elif $field == "guidance" then .trusted_guidance_selected = ($value == "true")
  elif $field == "repetitions" then .consensus.observed_repetitions = ($value | tonumber)
  elif $field == "disposition" then .candidate_learning.disposition = $value
  elif $field == "record" then .record_id = $value
  elif $field == "channel" then .host_envelope.write_channel = $value
  elif $field == "context" then .consuming_context_revision = $value
  elif $field == "run" then .supporting_evidence.references[0].run_id = $value
  elif $field == "integrity" then .supporting_evidence.references[0].integrity_bound = ($value == "true")
  elif $field == "detector" then .candidate_learning.attribution.detector_id = $value
  elif $field == "input" then .candidate_learning.attribution.input_record_id = $value
  elif $field == "conflicts" then .supporting_evidence.conflicting_claim_ids = []
  else . end
 )' "$source" > "$tmp/mutated.json"
 if bash "$validator" "$tmp/mutated.json" >/dev/null 2>&1; then
  echo "accepted invalid mutation: $spec" >&2; exit 1
 fi
 count=$((count+1))
done
echo "Memory consensus negative oracle: $count mutations rejected"
