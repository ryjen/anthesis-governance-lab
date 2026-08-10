# Governance Lab Full Verification Runbook

## Purpose

Use this runbook when the goal is to answer one question from a fresh checkout:

> Does the published Anthesis Governance Lab evaluator and every current public proof surface reproduce the expected results?

This is the exhaustive operator path. For a short stakeholder presentation, use [`docs/walkthroughs/five-minute-demo.md`](../walkthroughs/five-minute-demo.md) instead.

## What is being verified

Governance Lab intentionally contains three separate proof surfaces:

| Surface | Count | What it proves |
|---|---:|---|
| Canonical governance contract | 7 scenarios | Stable deterministic policy outcomes and expectation-drift detection. |
| General governance demo | 27 scenarios across 9 packs | Broader synthetic SDLC governance coverage without executing effects. |
| Inference-integrity contract | 24 scenarios | Deterministic evaluation of recorded provider-neutral inference evidence. |

The counts are independent. The 24 inference-integrity cases are not a subset of the 27 general demo scenarios.

## Prerequisites

Supported platform: Linux x86_64.

Required tools:

```text
git bash curl cosign sha256sum tar jq realpath
```

Network access is required to clone this repository and acquire the pinned public evaluator. No GitHub token, private Anthesis checkout, GPU, live model, provider credential, Dubnium service, or hosted Anthesis service is required.

## 1. Start from a fresh checkout

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab
```

Record the Governance Lab revision being verified:

```bash
git rev-parse HEAD
```

## 2. Inspect the immutable evaluator pin

```bash
cat .anthesis/cli-artifact.env
```

The pin binds the trial to a reviewed private Anthesis source commit, a source-derived public release tag, archive and binary SHA-256 digests, the CLI version, and mandatory Sigstore verification.

Do not replace the pin with a mutable `latest` release or mix identity values from different releases.

## 3. Acquire and verify the public evaluator

```bash
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
```

Acquisition must verify the release producer identity, protected workflow ref and SHA, GitHub Actions OIDC issuer, checksum, provenance, archive allowlist, packaged checksum, binary digest, CLI identity, supported contracts, and repository-contained installation before the binary is trusted.

Verify the installed CLI:

```bash
anthesis-lab version --format json | jq .
```

The supported contract set must contain exactly:

```text
anthesis.policy/v1
anthesis.lab-profile/v1
anthesis.scenario/v1
anthesis.decision/v1
anthesis.request-binding/v1
anthesis.evaluation-request/v1
anthesis.evidence-bundle/v1
anthesis.evidence-bundle-verification/v1
```

## 4. Verify the canonical governance contract — 7 scenarios

```bash
set -o pipefail
anthesis-lab test --repo . --format json |
  tee /tmp/anthesis-canonical.json |
  jq '{version, passed, total, passed_count, failed_count}'
```

Expected result:

```json
{
  "version": "anthesis.test-report/v1",
  "passed": true,
  "total": 7,
  "passed_count": 7,
  "failed_count": 0
}
```

Then run the canonical regression exercise:

```bash
bash scripts/validate-governance-lab.sh
```

Expected final output:

```text
Canonical suite: 7 passed, 0 failed
Intentional governance drift: detected with exit code 7
```

The exit-`7` negative control matters: it proves fixture expectations are assertions rather than evaluator inputs.

## 5. Verify the general governance demo — 9 packs / 27 scenarios

Confirm the cataloged pack IDs:

```bash
bash scripts/run-demo-pack.sh --list
```

Expected packs:

```text
documentation
source-code
ci-and-release
dependencies
secrets-and-evidence
network-and-tools
runtime-and-identity
deployment-and-administration
adversarial
```

Run every pack:

```bash
set -o pipefail
bash scripts/aggregate-demo-packs.sh |
  tee /tmp/anthesis-demo-packs.json |
  jq '{classification, pack_count, passed_packs, total_scenarios}'
```

Expected result:

```json
{
  "classification": "passed",
  "pack_count": 9,
  "passed_packs": 9,
  "total_scenarios": 27
}
```

These are declaration-evaluation scenarios. A passing result does not mean the repository performed file writes, commands, network calls, merges, releases, deployments, or repository-administration effects.

## 6. Verify the inference-integrity contract — 24 scenarios

Run the evaluator directly:

```bash
set -o pipefail
anthesis-lab inference-integrity --repo . --format json |
  tee /tmp/anthesis-inference-integrity.json |
  jq '{version, passed, total, passed_count, failed_count}'
```

Expected result:

```json
{
  "version": "anthesis.inference-integrity-report/v1alpha1",
  "passed": true,
  "total": 24,
  "passed_count": 24,
  "failed_count": 0
}
```

Run the executable regression validation:

```bash
bash scripts/validate-executable-inference-integrity.sh
```

Expected final output:

```text
Inference-integrity executable suite: 24 passed; mismatch exit 7 verified
```

This validation also requires byte-identical JSON across repeated evaluations, checks the YAML report for the expected version and passing markers, and requires exactly one failure when a copied expectation is intentionally changed. It does not parse the YAML report with a YAML-aware validator.

## 7. Generate and verify the inference evidence bundle

```bash
bash scripts/generate-inference-integrity-evidence.sh
```

Verify file integrity:

```bash
cd .anthesis/evidence/inference-integrity
sha256sum --check SHA256SUMS
jq . manifest.json
cd ../../..
```

The manifest must bind the reports to the 24-case report contract, Anthesis source revision, immutable release tag, Sigstore requirement, Governance Lab revision, controlled mismatch exit code, and report checksums.

## 8. Run structural and documentation validation

```bash
bash scripts/validate-docs-and-catalog.sh
bash scripts/validate-inference-integrity-fixtures.sh
bash scripts/validate-inference-capacity-fixtures.sh
bash scripts/validate-inference-final-catalog.sh
bash scripts/validate-inference-scenario-catalog.sh
bash scripts/validate-walkthroughs.sh
```

These checks confirm catalog/fixture parity, exact demo-pack selection, inference fixture structure, scenario-catalog parity, walkthrough references, and documented operator invariants.

## 9. CI-equivalent validation sequence

After the evaluator has been acquired, the main repository validation sequence is:

```bash
bash scripts/validate-governance-lab.sh
bash scripts/validate-demo-packs.sh
bash scripts/validate-executable-inference-integrity.sh
bash scripts/validate-docs-and-catalog.sh
bash scripts/validate-walkthroughs.sh
```

A successful local run should agree with the repository CI on the same Governance Lab revision and evaluator pin.

## 10. Interpret the result correctly

A complete successful verification establishes that:

- the pinned public evaluator was acquired through the documented trust chain;
- the 7 canonical governance scenarios reproduce their expected deterministic decisions;
- all 9 general demo packs / 27 scenarios reproduce their expected decisions;
- all 24 inference-integrity scenarios reproduce their expected verdicts, capability classes, and policy postures;
- controlled expectation drift is detected rather than silently accepted;
- generated inference evidence is reproducible and checksum-verifiable.

It does **not** establish that arbitrary agent traffic cannot bypass Anthesis, that effects are executed through a production enforcement point, or that live model inference is independently replayed and contained.

Production enforcement requires an authoritative runtime boundary:

```text
agent request
  -> Anthesis decision and capability boundary
  -> exact approval when required
  -> bounded executor or runtime enforcement
  -> attributable evidence and outcome
```

Dubnium owns the reference live-runtime surfaces for gateway metadata, seed and sampling evidence, replay, verifier execution, containment, and recovery.

## 11. Cleanup and repeatability

Remove generated artifacts and the acquired evaluator:

```bash
rm -rf .anthesis/evidence/inference-integrity
rm -rf .anthesis/bin
```

Then repeat from acquisition without changing repository fixtures or the immutable release pin.
