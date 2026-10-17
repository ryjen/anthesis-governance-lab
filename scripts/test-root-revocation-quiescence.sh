#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source="$root/fixtures/external-security/root-revocation-quiescence-v1.json"
validator="$root/scripts/validate-root-revocation-quiescence.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
count=0
for pair in \
  'cancellation-ack-only:QUIESCENT' \
  'durable-cut-unfenced-sink:QUIESCENT' \
  'stale-worker-retired-epoch:QUIESCENT' \
  'provider-enumeration-missing:QUIESCENT' \
  'duplicated-handoff-token:QUIESCENT' \
  'conflicting-certificate-revision:QUIESCENT' \
  'timeout-retry-exhaustion:QUIESCENT'; do
  id="${pair%%:*}"
  verdict="${pair#*:}"
  jq --arg id "$id" --arg verdict "$verdict" '(.cases[] | select(.id == $id) | .expected) = $verdict' "$source" > "$tmp/fixture.json"
  if bash "$validator" "$tmp/fixture.json" > "$tmp/out" 2> "$tmp/err"; then
    echo "invalid promotion accepted for $id" >&2
    exit 1
  fi
  grep -Fq 'root quiescence fixture invariants failed' "$tmp/err"
  count=$((count + 1))
done
echo "Root quiescence negative oracle: $count false promotions rejected"
