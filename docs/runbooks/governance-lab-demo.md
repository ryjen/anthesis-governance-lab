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

The current executable trial supports Linux x86_64.

Required tools:

```text
bash curl sha256sum unzip tar jq realpath
```

## 1. Clone the repository

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab
```

## 2. Acquire the verified evaluator

### Current transitional path

The current `main` branch uses a checksum-pinned GitHub Actions artifact from the private Anthesis producer. It requires a token with permission to download that exact artifact:

```bash
export GITHUB_TOKEN=...
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
```

The script verifies the outer archive checksum, allowlists archive members, verifies the packaged binary checksum, confines installation to the repository workspace, and fails closed on metadata or identity mismatch.

### Target durable path

Issue #4 tracks migration to an anonymously downloadable immutable release in `hackelia-micrantha/anthesis-community`. Do not claim secretless acquisition until that release, its provenance, and both archive and binary hashes have been independently verified and recorded.

## 3. Verify CLI identity and contracts

```bash
anthesis-lab version --format json | jq .
```

The report must identify `anthesis-lab` and support:

- `anthesis.policy/v1`;
- `anthesis.lab-profile/v1`;
- `anthesis.scenario/v1`;
- `anthesis.decision/v1`.

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

## 5. Interpret decisions

| Decision | Meaning |
|---|---|
| `allow` | The declared attempt matched an allow rule. No effect is executed by this repository. |
| `approval_required` | Policy requires an external approval before a separate governed executor may act. The lab does not collect or persist that approval. |
| `deny` from `policy_rule` | A policy rule explicitly blocks the declaration. |
| `deny` from `engine_guard` | The evaluator rejects the declaration independently of normal rule matching, such as an unregistered runtime. |

For each scenario inspect the actual decision, source, rule ID, stable reason, expected result, and mismatch details.

Expected fixture data is an assertion about the decision. Changing an expected result must not change the actual policy decision.

## 6. Run the complete validation exercise

```bash
bash scripts/validate-governance-lab.sh
```

This validates the CLI contract, the seven canonical scenarios, and an isolated expectation-drift exercise.

Expected final output:

```text
Canonical suite: 7 passed, 0 failed
Intentional governance drift: detected with exit code 7
```

## 7. Validate documentation and catalog integrity

```bash
bash scripts/validate-docs-and-catalog.sh
```

This checks:

- the machine-readable catalog contract;
- one-to-one coverage of all seven canonical fixtures;
- unique scenario IDs and paths;
- required documentation and script paths;
- README links to the runbook and scenario guides;
- runbook command references;
- explicit separation of canonical and planned demo collections.

## 8. Understand expectation drift

The validation script copies the canonical fixtures into a repository-contained temporary directory and changes only scenario 01's expected decision from `allow` to `deny`.

The policy still returns `allow`. The test report detects the mismatch and exits with status `7`. This proves that fixture expectations do not alter evaluator behavior.

## 9. Evaluator versus executor boundary

The Governance Lab proves that a pinned evaluator can deterministically decide declared attempts against pinned policy and runtime contracts.

It does not prove that an agent cannot bypass the evaluator. A production integration must ensure the agent can reach effectful tools only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point.

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

Registering Anthesis beside unwrapped effectful tools is insufficient.

## 10. Safe scenario authoring

Before adding a scenario:

1. use synthetic paths, identities, tokens, and payloads;
2. declare only capabilities represented by the accepted public contract;
3. state the expected decision, source, rule, and reason;
4. state the threat or control being demonstrated;
5. state explicitly that no real effect executes;
6. keep paths repository-relative and portable;
7. place non-canonical scenarios in the separate demo collection;
8. run structural and executable validation.

See:

- `docs/scenarios/authoring.md`;
- `docs/scenarios/catalog.md`;
- `docs/scenarios/catalog.json`;
- `docs/scenarios/interpretation.md`.

## Pending demo-pack tooling

The canonical suite can be run today. Commands for selecting one additional demo scenario or a themed demo pack are intentionally not documented as available yet.

They are tracked by:

- issue #8 for the use-case scenario packs;
- issue #9 for `scripts/run-demo-pack.sh` and catalog validation.

Until those issues land, do not copy canonical fixtures into ad hoc directories or treat planned `.anthesis/demos` paths as executable interfaces.

## 11. Troubleshooting

### Artifact acquisition fails

Confirm the exact pinned metadata, token permission for the transitional artifact, artifact expiry, TLS availability, archive checksum, and packaged checksum. Never substitute a mutable `latest` asset or skip verification.

### Unsupported contract

```bash
anthesis-lab version --format json | jq .supported_contracts
```

Repin deliberately if the CLI and fixtures are incompatible. Do not weaken assertions.

### Scenario input is rejected

Use repository-relative, non-symlinked paths. The CLI rejects absolute paths, home-relative paths, repository escapes, and unsafe scenario collections.

### Test exits 7

Exit status `7` means at least one actual decision did not match its fixture expectation. Inspect the `mismatches` entries. It is not a successful canonical run.

## 12. Cleanup

The validation script cleans its repository-contained temporary fixture automatically. Remove a locally acquired evaluator with:

```bash
rm -rf .anthesis/bin
```

Do not remove the canonical policy, runtime profile, or scenario fixtures.

## Five-minute walkthrough

1. Show the pinned CLI identity with `anthesis-lab version --format json`.
2. Run the canonical suite and show seven passes.
3. Compare one allowed documentation declaration with one approval-gated CI change.
4. Show the secret-access policy denial and unknown-runtime engine-guard denial.
5. Run the intentional drift exercise and explain exit code `7`.
6. Close by distinguishing deterministic evaluation from bypass-resistant effect enforcement.
