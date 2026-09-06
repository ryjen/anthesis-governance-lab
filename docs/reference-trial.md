# Governed repository reference trial

This walkthrough adds one runtime-enforcement layer around the existing deterministic `anthesis-lab` evaluator. It is intentionally small: one allowed repository mutation, one raw-tool bypass attempt, and one out-of-scope mutation attempt.

The trial does **not** introduce a new Anthesis authority contract. The evaluator still emits the published `anthesis.decision/v1` decision. The local harness is a reference composition showing how a runtime can make that decision consequential by exposing only a governed repository writer to the simulated agent.

## What the trial proves

```text
reference supervisor
  -> anthesis-lab evaluates exact file.write request
  -> reference runtime registry exposes anthesis.repo_write
  -> exact-effect dispatcher checks action + path
  -> disposable Git repository is mutated
  -> decision + mutation evidence recorded

bypass attempt
  -> raw.repo_write
  -> tool registry lookup
  -> HARD DENIAL: tool_not_registered
  -> repository state unchanged
```

The allowed effect is the canonical Governance Lab scenario `01-allowed-docs-edit`: `file.write` to `docs/onboarding.md`. The harness creates a disposable Git repository under `.anthesis/reference-trial`, commits a baseline, performs the governed edit, and leaves the resulting diff for inspection.

## Run it

Acquire the pinned, verified evaluator first:

```bash
bash scripts/acquire-anthesis-lab.sh
```

Then run the reference trial:

```bash
bash scripts/run-reference-trial.sh
```

Inspect the mutation and recorded evidence:

```bash
git -C .anthesis/reference-trial diff -- docs/onboarding.md
jq . .anthesis/reference-trial/decision.json
jq . .anthesis/reference-trial/reference-trial.json
```

Re-running the script safely replaces only a workspace carrying the harness's exact marker.

## Enforcement point

The selected integration mode is a **tool wrapper / constrained runtime registry**.

The simulated agent-visible registry contains only `anthesis.repo_write` for the governed repository effect. It does not expose `raw.repo_write`, shell, filesystem, Git, network, or provider credentials. The registered writer additionally binds execution to the exact action and path in the evaluator decision.

The deliberate raw bypass therefore fails at runtime dispatch with:

```text
tool_not_registered:raw.repo_write
```

The harness then verifies that the repository content hash is unchanged. It also attempts the registered writer against `.github/workflows/ci.yml`; that attempt fails with an exact-effect scope mismatch and creates no file.

This is a hard runtime denial inside the stated reference composition, not merely an advisory policy result.

## Evaluator output

`reference-trial.json` identifies:

- integration mode and enforcement point;
- exact governed action/path and before/after hashes;
- reference supervisor/specialist and evaluator runtime identity;
- policy decision, source, rule, reason, policy digest, and request binding;
- a non-authoritative lifecycle/Envelope correlation reference derived from the request digest;
- the Git diff digest and paths to the evaluator decision and trial record;
- both bypass attempts, denial reasons, and state-unchanged assertions;
- the exact runtime restriction and residual trust assumptions.

The correlation reference is not an authority grant. The public [Anthesis Envelope description](https://github.com/hackelia-micrantha/anthesis-community/blob/main/docs/product/envelope.md) remains the conceptual lifecycle/context boundary.

## Residual trust and non-claims

The reference runtime registry/dispatcher is trusted to be the simulated agent's only effect surface. `anthesis-lab` and its published policy/runtime inputs are trusted according to the Governance Lab acquisition and verification boundary.

This harness does **not** claim containment against a hostile local OS user or administrator. It also does not claim that arbitrary agent code with shell, filesystem, Git, network, or raw provider credentials would be non-bypassable. Giving those capabilities to the agent would invalidate this trial's runtime restriction.

A production trial must establish the equivalent restriction using the actual runtime, credential placement, tool/MCP registry, gateway, capability validator, or sandbox selected for that deployment. Use the public [trial criteria](https://github.com/hackelia-micrantha/anthesis-community/blob/main/docs/product/trial-criteria.md) to evaluate that boundary.
