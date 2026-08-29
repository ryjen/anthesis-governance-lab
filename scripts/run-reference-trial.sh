#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cli="${ANTHESIS_LAB:-$repo_root/.anthesis/bin/anthesis-lab}"
scenario="$repo_root/.anthesis/scenarios/01-allowed-docs-edit.yaml"
workspace="$repo_root/.anthesis/reference-trial"
marker="$workspace/.anthesis-reference-trial"
decision_file="$workspace/decision.json"
receipt_file="$workspace/reference-trial.json"

fail_boundary() {
  printf '%s\n' "$1" >&2
  exit 3
}

[[ -x "$cli" && ! -L "$cli" ]] || fail_boundary "verified anthesis-lab binary is required; run scripts/acquire-anthesis-lab.sh first"
[[ -f "$scenario" && ! -L "$scenario" ]] || fail_boundary "canonical allow scenario is missing or unsafe"
[[ -d "$repo_root/.anthesis" && ! -L "$repo_root/.anthesis" ]] || fail_boundary ".anthesis must be a real directory"
command -v git >/dev/null || fail_boundary "git is required for the disposable repository trial"
command -v jq >/dev/null || fail_boundary "jq is required for reference-trial evidence"

if [[ -e "$workspace" ]]; then
  [[ -d "$workspace" && ! -L "$workspace" && -f "$marker" && ! -L "$marker" ]] || \
    fail_boundary "refusing to replace an unrecognized reference-trial workspace"
  [[ "$(cat "$marker")" == "anthesis-reference-trial-v1" ]] || \
    fail_boundary "reference-trial workspace marker is invalid"
  rm -rf -- "$workspace"
fi

mkdir -p "$workspace/docs"
printf '%s\n' 'anthesis-reference-trial-v1' > "$marker"
printf '%s\n' 'Reference onboarding content before governed mutation.' > "$workspace/docs/onboarding.md"
git -C "$workspace" init --quiet
git -C "$workspace" add docs/onboarding.md
git -C "$workspace" \
  -c user.name='Anthesis Reference Trial' \
  -c user.email='reference-trial@invalid.example' \
  commit --quiet -m 'reference baseline'
before_sha256="$(sha256sum "$workspace/docs/onboarding.md" | awk '{print $1}')"

(
  cd "$repo_root"
  "$cli" evaluate \
    --repo . \
    --scenario .anthesis/scenarios/01-allowed-docs-edit.yaml \
    --format json
) > "$decision_file"

jq -e '
  .version == "anthesis.decision/v1" and
  .scenario_id == "01-allowed-docs-edit" and
  .decision == "allow" and
  .effect.action == "file.write" and
  .effect.resource.path == "docs/onboarding.md" and
  .decision_source == "policy_rule" and
  (.policy_rule_id | type == "string" and length > 0) and
  (.request_binding.request_digest | test("^sha256:[0-9a-f]{64}$"))
' "$decision_file" >/dev/null || fail_boundary "canonical evaluator did not authorize the exact reference effect"

expected_action="$(jq -r '.effect.action' "$decision_file")"
expected_path="$(jq -r '.effect.resource.path' "$decision_file")"

runtime_dispatch() {
  local tool="$1"
  local action="$2"
  local path="$3"
  local content="$4"

  case "$tool" in
    anthesis.repo_write)
      ;;
    *)
      printf 'tool_not_registered:%s\n' "$tool" >&2
      return 77
      ;;
  esac

  [[ "$action" == "$expected_action" ]] || {
    printf 'effect_action_mismatch:%s\n' "$action" >&2
    return 78
  }
  [[ "$path" == "$expected_path" ]] || {
    printf 'effect_scope_mismatch:%s\n' "$path" >&2
    return 78
  }
  [[ "$path" != /* && "$path" != *'..'* ]] || {
    printf 'unsafe_effect_path:%s\n' "$path" >&2
    return 78
  }

  local destination="$workspace/$path"
  local parent
  parent="$(dirname "$destination")"
  mkdir -p "$parent"
  [[ ! -L "$destination" && ! -L "$parent" ]] || {
    printf 'unsafe_effect_target:%s\n' "$path" >&2
    return 78
  }

  local tmp="$destination.tmp"
  printf '%s\n' "$content" > "$tmp"
  mv -- "$tmp" "$destination"
}

runtime_dispatch \
  anthesis.repo_write \
  file.write \
  docs/onboarding.md \
  'Governed reference edit applied through the registered Anthesis tool boundary.'

after_allow_sha256="$(sha256sum "$workspace/docs/onboarding.md" | awk '{print $1}')"
[[ "$after_allow_sha256" != "$before_sha256" ]] || fail_boundary "governed mutation did not change the reference repository state"
git -C "$workspace" diff --quiet --exit-code -- docs/onboarding.md && \
  fail_boundary "governed mutation produced no inspectable repository diff"

set +e
raw_denial="$(runtime_dispatch \
  raw.repo_write \
  file.write \
  docs/onboarding.md \
  'BYPASS MUST NOT EXECUTE' 2>&1)"
raw_status=$?
set -e
[[ "$raw_status" -eq 77 ]] || fail_boundary "raw bypass attempt was not hard-denied by the runtime registry"
[[ "$raw_denial" == 'tool_not_registered:raw.repo_write' ]] || fail_boundary "raw bypass denial reason changed unexpectedly"

after_raw_bypass_sha256="$(sha256sum "$workspace/docs/onboarding.md" | awk '{print $1}')"
[[ "$after_raw_bypass_sha256" == "$after_allow_sha256" ]] || fail_boundary "raw bypass attempt changed repository state"

set +e
scope_denial="$(runtime_dispatch \
  anthesis.repo_write \
  file.write \
  .github/workflows/ci.yml \
  'OUT OF SCOPE MUST NOT EXECUTE' 2>&1)"
scope_status=$?
set -e
[[ "$scope_status" -eq 78 ]] || fail_boundary "out-of-scope governed-tool attempt was not denied"
[[ "$scope_denial" == 'effect_scope_mismatch:.github/workflows/ci.yml' ]] || fail_boundary "scope denial reason changed unexpectedly"
[[ ! -e "$workspace/.github/workflows/ci.yml" ]] || fail_boundary "out-of-scope attempt created repository state"

final_diff_sha256="$(git -C "$workspace" diff -- docs/onboarding.md | sha256sum | awk '{print $1}')"
request_digest="$(jq -r '.request_binding.request_digest' "$decision_file")"
envelope_ref="reference-envelope:${request_digest#sha256:}"

jq -n \
  --arg workspace "$workspace" \
  --arg envelope_ref "$envelope_ref" \
  --arg before_sha256 "$before_sha256" \
  --arg after_sha256 "$after_allow_sha256" \
  --arg final_diff_sha256 "$final_diff_sha256" \
  --arg raw_denial "$raw_denial" \
  --arg scope_denial "$scope_denial" \
  --argjson decision "$(cat "$decision_file")" \
  '{
    reference_trial: true,
    non_normative: true,
    integration_mode: "tool-wrapper",
    enforcement_point: "reference runtime tool registry and exact-effect dispatcher",
    workflow: {
      supervisor: "reference-supervisor",
      specialist: "reference-repo-writer",
      runtime_identity: $decision.effect.runtime.id,
      envelope_ref: $envelope_ref,
      envelope_grants_authority: false
    },
    governed_effect: {
      action: $decision.effect.action,
      path: $decision.effect.resource.path,
      before_sha256: $before_sha256,
      after_sha256: $after_sha256,
      git_diff_sha256: $final_diff_sha256,
      result: "mutated"
    },
    authorization: {
      decision: $decision.decision,
      decision_source: $decision.decision_source,
      policy: $decision.policy,
      policy_digest: $decision.policy_digest,
      policy_rule_id: $decision.policy_rule_id,
      reason: $decision.reason,
      request_binding: $decision.request_binding,
      approval: null,
      capability: null
    },
    evidence: {
      decision_file: "decision.json",
      receipt_file: "reference-trial.json",
      workspace: $workspace,
      inspect_effect: "git -C .anthesis/reference-trial diff -- docs/onboarding.md"
    },
    bypass_attempts: [
      {
        attempted_tool: "raw.repo_write",
        attempted_effect: "file.write:docs/onboarding.md",
        result: "hard_denial",
        reason: $raw_denial,
        repository_state_unchanged: true
      },
      {
        attempted_tool: "anthesis.repo_write",
        attempted_effect: "file.write:.github/workflows/ci.yml",
        result: "hard_denial",
        reason: $scope_denial,
        repository_state_unchanged: true
      }
    ],
    runtime_restriction: "The reference agent-visible registry exposes only anthesis.repo_write. It exposes no raw repository writer, shell, filesystem, Git, network, or provider credential path; the dispatcher also binds execution to the exact evaluator-authorized action and path.",
    residual_trust: [
      "The reference runtime registry/dispatcher is trusted to be the only agent effect surface.",
      "anthesis-lab and the published policy/runtime inputs are trusted according to their documented acquisition and verification boundaries.",
      "This local reference harness does not claim containment against a hostile local OS user or administrator; granting the agent arbitrary shell/filesystem/network access would invalidate the non-bypassability claim."
    ]
  }' | tee "$receipt_file"
