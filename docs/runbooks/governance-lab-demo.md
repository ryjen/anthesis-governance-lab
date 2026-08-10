# Governance Lab Operator Runbook

## Purpose

This runbook demonstrates deterministic policy evaluation for declared AI-assisted SDLC actions using the public `anthesis-lab` CLI and repository-local synthetic fixtures.

The Governance Lab evaluates declarations. It does not execute file writes, network requests, deployments, merges, releases, or repository-administration operations, and it does not persist approvals.

For a single end-to-end verification procedure covering every proof surface, use [`full-verification.md`](full-verification.md).

## Proof surfaces

Governance Lab intentionally keeps three surfaces separate:

| Surface | Count | Primary command | Purpose |
|---|---:|---|---|
| Canonical governance contract | 7 scenarios | `anthesis-lab test --repo . --format json` | Stable public conformance fixtures. |
| General governance demo | 27 scenarios across 9 packs | `bash scripts/aggregate-demo-packs.sh` | Broader synthetic SDLC governance examples. |
| Inference-integrity contract | 24 scenarios | `anthesis-lab inference-integrity --repo . --format json` | Provider-neutral inference-evidence verification. |

The 24 inference-integrity cases are not part of the 27 general demo scenarios.

## Audience

- developers evaluating policy-as-code for agentic workflows;
- security and governance reviewers;
- platform engineers designing governed execution boundaries;
- stakeholders evaluating Anthesis and related integrations.

## Supported platform and prerequisites

The executable trial supports Linux x86_64.

Required tools:

```text
git bash curl cosign sha256sum tar jq realpath
```

Network access is required only to clone the repository and acquire the pinned public CLI. The scenario suites themselves use repository-local synthetic inputs.

## 1. Clone the repository

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab
```

## 2. Acquire the verified evaluator

```bash
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
```

No GitHub token, private repository access, workflow artifact ID, or trusted deployment environment is required.

The acquisition script downloads the immutable public release artifacts from `hackelia-micrantha/anthesis-community`:

- `anthesis-lab-linux-x86_64.tar.gz`;
- `anthesis-lab-linux-x86_64.tar.gz.sha256`;
- `anthesis-lab-provenance.json`;
- Sigstore bundles for the archive, checksum, and provenance assets.

Before installation it verifies:

1. the release repository and full source-commit-derived tag;
2. Sigstore producer identity, protected workflow ref, workflow SHA, and GitHub Actions OIDC issuer;
3. the externally pinned tarball SHA-256;
4. the published checksum asset;
5. the provenance source repository, source commit, distribution tag, artifact identity, platform, linkage, and workflow;
6. the exact archive member allowlist;
7. the packaged checksum file;
8. the independently pinned binary SHA-256;
9. CLI name and version;
10. the exact supported contract set;
11. repository-contained, non-symlinked installation.

Any mismatch fails closed before scenario execution.

## 3. Verify CLI identity and contracts

```bash
anthesis-lab version --format json | jq .
```

Expected identity:

```json
{
  "name": "anthesis-lab",
  "version": "0.1.0"
}
```

The supported contracts must be exactly:

- `anthesis.policy/v1`;
- `anthesis.lab-profile/v1`;
- `anthesis.scenario/v1`;
- `anthesis.decision/v1`;
- `anthesis.request-binding/v1`;
- `anthesis.evaluation-request/v1`;
- `anthesis.evidence-bundle/v1`;
- `anthesis.evidence-bundle-verification/v1`.

The exact version and immutable release identity are pinned in `.anthesis/cli-artifact.env`; do not substitute a mutable release.

## 4. Run the canonical conformance suite — 7 scenarios

Preserve the evaluator exit code when formatting JSON:

```bash
set -o pipefail
anthesis-lab test --repo . --format json | jq .
```

Expected summary:

```json
{
  "version": "anthesis.test-report/v1",
  "passed": true,
  "total": 7,
  "passed_count": 7,
  "failed_count": 0
}
```

The canonical fixtures under `.anthesis/scenarios` are synchronized public-contract examples and must not be repurposed as the expanding demo catalog.

Run the canonical validation plus intentional expectation drift:

```bash
bash scripts/validate-governance-lab.sh
```

Expected final output:

```text
Canonical suite: 7 passed, 0 failed
Intentional governance drift: detected with exit code 7
```

The drift exercise changes only a copied fixture expectation. The policy still returns the original decision, and `anthesis-lab test` exits `7` because the expected and actual decisions differ.

## 5. Run the general governance demo — 9 packs / 27 scenarios

List exact pack IDs:

```bash
bash scripts/run-demo-pack.sh --list
```

Available packs:

- `documentation`;
- `source-code`;
- `ci-and-release`;
- `dependencies`;
- `secrets-and-evidence`;
- `network-and-tools`;
- `runtime-and-identity`;
- `deployment-and-administration`;
- `adversarial`.

Run one pack while preserving the evaluator exit code:

```bash
set -o pipefail
bash scripts/run-demo-pack.sh documentation | jq .
```

Run all nine packs:

```bash
bash scripts/aggregate-demo-packs.sh |
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

The runner accepts only exact cataloged IDs and evaluates declarations only. It does not execute declared effects or persist approvals.

## 6. Run the inference-integrity extension — 24 scenarios

The inference-integrity suite is a separate provider-neutral contract over recorded synthetic evidence:

```bash
set -o pipefail
anthesis-lab inference-integrity --repo . --format json |
  jq '{passed, total, passed_count, failed_count}'
```

Expected result:

```json
{
  "passed": true,
  "total": 24,
  "passed_count": 24,
  "failed_count": 0
}
```

Run the executable validation, including deterministic-report comparison and a controlled mismatch that must exit `7`:

```bash
bash scripts/validate-executable-inference-integrity.sh
```

Expected final output:

```text
Inference-integrity executable suite: 24 passed; mismatch exit 7 verified
```

For scenario interpretation, evidence generation, verification classes, operating modes, and limitations, see [`inference-integrity-demo.md`](inference-integrity-demo.md).

## 7. Validate documentation and catalog integrity

```bash
bash scripts/validate-docs-and-catalog.sh
```

This checks the canonical and demo catalogs, fixture coverage, required documentation, runner syntax, exact pack selection, fail-closed handling of unsafe pack names, and key operator-document invariants.

## 8. Upgrade the immutable release pin

The current identity is recorded in `.anthesis/cli-artifact.env`.

A release upgrade must be a reviewed pull request that changes all of these together:

- full Anthesis source commit;
- source-commit-derived public release tag;
- tarball name and SHA-256;
- packaged binary SHA-256;
- CLI version.

Validation must then pass on a pull request without secrets. Never use a mutable `latest` URL, omit Sigstore or provenance validation, weaken archive allowlisting, or update only one digest.

## 9. Evaluator versus executor boundary

The Governance Lab proves that a pinned evaluator can deterministically decide declared attempts against pinned policy and runtime contracts, and can evaluate recorded inference-integrity evidence against a pinned verification contract.

It does not prove that an agent cannot bypass the evaluator. A production integration must ensure the agent can reach effectful tools only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point.

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

Registering Anthesis beside unwrapped effectful tools is insufficient.

The inference-integrity fixture suite likewise does not invoke a live provider, capture live token streams, perform independent replay, or execute containment. Dubnium owns those live-runtime integration surfaces.

## 10. Troubleshooting

### Public release acquisition fails

Confirm the exact pin in `.anthesis/cli-artifact.env`, TLS availability, `cosign`, release asset presence, Sigstore identity, checksum, provenance fields, archive members, packaged checksum, binary digest, CLI version, and supported contracts. Do not substitute a mutable release.

### Unsupported contract

```bash
anthesis-lab version --format json | jq .supported_contracts
```

Repin deliberately if the CLI and fixtures are incompatible. Do not weaken assertions.

### Test exits 7

Exit status `7` means at least one actual decision did not match its fixture expectation. Inspect the report mismatches; this is not a successful canonical, demo-pack, or inference-integrity run.

### Demo pack is rejected

Run `bash scripts/run-demo-pack.sh --list` and use one exact cataloged ID. Do not pass paths, glob patterns, or ad hoc scenario directories.

## 11. Cleanup

```bash
rm -rf .anthesis/bin
rm -rf .anthesis/evidence/inference-integrity
```

Do not remove the canonical policy, runtime profile, metadata pin, or scenario fixtures.

## Five-minute walkthrough

For a short stakeholder presentation, use [`docs/walkthroughs/five-minute-demo.md`](../walkthroughs/five-minute-demo.md). It intentionally focuses on the 7-case contract and 27-case governance demo rather than attempting to present all 24 inference-integrity cases.

A concise inference-integrity extension can then show:

1. the 24/24 aggregate result;
2. one representative scenario such as `detect-token-substitution`;
3. the controlled mismatch with exit code `7`;
4. the live-runtime limitation and Dubnium integration boundary.
