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
for pair in \
  'cancellation-ack-only:provider_fenced' \
  'durable-cut-unfenced-sink:cut_durable' \
  'precut-accepted-late-settlement:precut_accepted_late_settlement' \
  'shared-worker-exact-rebind:independent_root_preserved' \
  'unrelated-root-preserved:provider_fenced'; do
  id="${pair%%:*}"
  field="${pair#*:}"
  jq --arg id "$id" --arg field "$field" '(.cases[] | select(.id == $id) | .[$field]) |= not' "$source" > "$tmp/fixture.json"
  if bash "$validator" "$tmp/fixture.json" > "$tmp/out" 2> "$tmp/err"; then
    echo "evidence drift accepted for $id/$field" >&2
    exit 1
  fi
  grep -Fq 'root quiescence fixture invariants failed' "$tmp/err"
  count=$((count + 1))
done
for pair in \
  'cut-plus-provider-fence:origin_root' \
  'cut-plus-provider-fence:delegation_epoch' \
  'cut-plus-provider-fence:cut_sequence' \
  'cut-plus-provider-fence:fence_sequence' \
  'cut-plus-provider-fence:frontier_sequence' \
  'shared-worker-exact-rebind:handoff_id' \
  'shared-worker-exact-rebind:retry_effect_id' \
  'cut-plus-provider-fence:terminal_disposition'; do
  id="${pair%%:*}"
  field="${pair#*:}"
  jq --arg id "$id" --arg field "$field" '(.cases[] | select(.id == $id) | .[$field]) = "tampered"' "$source" > "$tmp/fixture.json"
  if bash "$validator" "$tmp/fixture.json" > "$tmp/out" 2> "$tmp/err"; then
    echo "provenance or ordering mutation accepted for $id/$field" >&2
    exit 1
  fi
  count=$((count + 1))
done
echo "Root quiescence negative oracle: $count false promotions rejected"

