# Governance Lab Operator Runbook

## Purpose

This runbook demonstrates deterministic policy evaluation for declared AI-assisted SDLC actions using the public `anthesis-lab` CLI and repository-local synthetic fixtures.

The Governance Lab evaluates declarations. It does not execute file writes, network requests, deployments, merges, releases, or repository-administration operations, and it does not persist approvals.

## Audience

- developers evaluating policy-as-code for agentic workflows;
- security and governance reviewers;
- platform engineers designing governed execution boundaries;
- stakeholders evaluating Anthesis and related integrations.

## Supported platform

The executable trial supports Linux x86_64.

Required tools:

```text
bash curl sha256sum tar jq realpath
```

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

The acquisition script downloads three immutable public release assets from `hackelia-micrantha/anthesis-community`:

- `anthesis-lab-linux-x86_64.tar.gz`;
- `anthesis-lab-linux-x86_64.tar.gz.sha256`;
- `anthesis-lab-provenance.json`.

Before installation it verifies:

1. the release repository and full source-commit-derived tag;
2. the externally pinned tarball SHA-256;
3. the published checksum asset;
4. the provenance source repository, source commit, distribution tag, artifact identity, platform, linkage, and workflow;
5. the exact archive member allowlist;
6. the packaged checksum file;
7. the independently pinned binary SHA-256;
8. CLI name and version;
9. the exact supported contract set;
10. repository-contained, non-symlinked installation.

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
- `anthesis.evaluation-request/v1`.

## 4. Run the canonical conformance suite

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

## 5. Run the complete validation exercise

```bash
bash scripts/validate-governance-lab.sh
```

This validates the CLI contract, the seven canonical scenarios, and an isolated expectation-drift exercise.

Expected final output:

```text
Canonical suite: 7 passed, 0 failed
Intentional governance drift: detected with exit code 7
```

The drift exercise changes only a copied fixture expectation. The policy still returns the original decision, and `anthesis-lab test` exits `7` because the expected and actual decisions differ.

## 6. Validate documentation and catalog integrity

```bash
bash scripts/validate-docs-and-catalog.sh
```

This checks the canonical and demo catalogs, fixture coverage, required documentation, runner syntax, exact pack selection, and fail-closed handling of unsafe pack names.

## 7. Run a demo pack

List exact pack IDs:

```bash
bash scripts/run-demo-pack.sh --list
```

Run one pack while preserving the evaluator exit code:

```bash
set -o pipefail
bash scripts/run-demo-pack.sh documentation | jq .
```

Available packs:

- `documentation`;
- `source-code`;
- `ci-and-release`;
- `dependencies`.

The runner accepts only exact cataloged IDs and evaluates declarations only. It does not execute declared effects or persist approvals.

## 8. Upgrade the immutable release pin

The current identity is recorded in `.anthesis/cli-artifact.env`.

A release upgrade must be a reviewed pull request that changes all of these together:

- full Anthesis source commit;
- source-commit-derived public release tag;
- tarball name and SHA-256;
- packaged binary SHA-256;
- CLI version.

Validation must then pass on a pull request without secrets. Never use a mutable `latest` URL, omit provenance validation, weaken archive allowlisting, or update only one digest.

## 9. Evaluator versus executor boundary

The Governance Lab proves that a pinned evaluator can deterministically decide declared attempts against pinned policy and runtime contracts.

It does not prove that an agent cannot bypass the evaluator. A production integration must ensure the agent can reach effectful tools only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point.

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

Registering Anthesis beside unwrapped effectful tools is insufficient.

## 10. Troubleshooting

### Public release acquisition fails

Confirm the exact pin in `.anthesis/cli-artifact.env`, TLS availability, release asset presence, checksum, provenance fields, archive members, packaged checksum, binary digest, CLI version, and supported contracts. Do not substitute a mutable release.

### Unsupported contract

```bash
anthesis-lab version --format json | jq .supported_contracts
```

Repin deliberately if the CLI and fixtures are incompatible. Do not weaken assertions.

### Test exits 7

Exit status `7` means at least one actual decision did not match its fixture expectation. Inspect `mismatches`; this is not a successful canonical or demo-pack run.

### Demo pack is rejected

Run `bash scripts/run-demo-pack.sh --list` and use one exact cataloged ID. Do not pass paths, glob patterns, or ad hoc scenario directories.

## 11. Cleanup

```bash
rm -rf .anthesis/bin
```

Do not remove the canonical policy, runtime profile, metadata pin, or scenario fixtures.

## Five-minute walkthrough

1. Show the immutable release pin and acquisition checks.
2. Show `anthesis-lab version --format json`.
3. Run the canonical suite and show seven passes.
4. Run `scripts/run-demo-pack.sh documentation`.
5. Compare approval-required, policy denial, and unknown-runtime engine-guard denial.
6. Run the intentional drift exercise and explain exit code `7`.
7. Close by distinguishing deterministic evaluation from bypass-resistant effect enforcement.
