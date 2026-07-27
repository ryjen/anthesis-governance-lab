# Governance Lab Operator Runbook

## Purpose

Demonstrate deterministic policy evaluation for declared AI-assisted SDLC actions using the public `anthesis-lab` CLI and repository-local synthetic fixtures.

The Governance Lab evaluates declarations. It does not execute file writes, commands, network requests, deployments, merges, releases, or repository-administration operations, and it does not persist approvals.

## Supported platform

Linux x86_64 with:

```text
bash curl sha256sum tar jq realpath
```

## 1. Clone and acquire the evaluator

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
```

Acquisition is anonymous and pinned to an immutable release in `hackelia-micrantha/anthesis-community`. The script validates the public distribution repository, source-bound tag, external tarball digest, published checksum, provenance manifest, archive members, packaged binary digest, CLI identity, version, and required contracts before installation.

Current immutable identity values are recorded together in `.anthesis/cli-artifact.env`. No private Anthesis checkout or repository secret is required.

## 2. Verify CLI identity and contracts

```bash
anthesis-lab version --format json | jq .
```

The report must identify `anthesis-lab`, match the pinned version, and support at least:

- `anthesis.policy/v1`;
- `anthesis.lab-profile/v1`;
- `anthesis.scenario/v1`;
- `anthesis.decision/v1`.

## 3. Run the canonical conformance suite

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

The canonical fixtures under `.anthesis/scenarios` are synchronized public-contract examples and remain separate from the expanding demo catalog.

## 4. Run the complete governance validation

```bash
bash scripts/validate-governance-lab.sh
```

Expected final output:

```text
Canonical suite: 7 passed, 0 failed
Intentional governance drift: detected with exit code 7
```

The drift exercise changes only a copied fixture expectation. The policy decision remains unchanged, the mismatch is reported, and the evaluator returns status `7`.

## 5. Run demo packs

```bash
bash scripts/run-demo-pack.sh --list
set -o pipefail
bash scripts/run-demo-pack.sh documentation | jq .
bash scripts/validate-demo-packs.sh
bash scripts/aggregate-demo-packs.sh | jq .
```

Available packs:

- `documentation`;
- `source-code`;
- `ci-and-release`;
- `dependencies`.

The runner accepts only exact cataloged IDs, rejects unsafe or divergent paths, preserves evaluator exit codes, and executes no declared effects.

## 6. Validate repository contracts

```bash
bash scripts/validate-docs-and-catalog.sh
bash scripts/validate-walkthroughs.sh
```

These checks validate canonical and demo catalog coverage, unique IDs and paths, documentation references, pack selection, the curated five-case showcase, and explicit evaluator-versus-executor limitations.

## 7. Interpret decisions

| Decision | Meaning |
|---|---|
| `allow` | The declaration matched an allow rule. No effect is executed by this repository. |
| `approval_required` | A separate governed integration must obtain and bind approval before execution. |
| `deny` from `policy_rule` | A named policy rule explicitly blocks the declaration. |
| `deny` from `engine_guard` | The evaluator fails closed independently of ordinary policy matching. |

Changing an expected result must not change the actual policy decision. Exit `7` means evaluation completed but at least one fixture expectation did not match.

## 8. Evaluator versus executor boundary

The lab proves that a pinned evaluator deterministically decides pinned declarations against pinned policy and runtime contracts. It does not prove that an agent cannot bypass evaluation.

Production enforcement requires effectful tools to be reachable only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent control:

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

Registering Anthesis beside unwrapped effectful tools is insufficient.

## 9. Troubleshooting

### Release acquisition fails

Confirm that all identity values in `.anthesis/cli-artifact.env` were changed together in a reviewed upgrade. Check HTTPS access, the exact immutable tag, all three release assets, provenance fields, tarball checksum, archive members, packaged binary checksum, and CLI identity. Never substitute `latest` or disable verification.

### Unsupported contract

```bash
anthesis-lab version --format json | jq .supported_contracts
```

Repin deliberately if the CLI and fixtures are incompatible. Do not weaken assertions.

### Test exits 7

Inspect report `mismatches`. Status `7` is expected only for the isolated drift exercise, not for canonical or demo-pack validation.

## 10. Deliberate upgrade procedure

1. Confirm the new public release is anonymously downloadable.
2. Confirm its provenance source commit and source ref.
3. Independently compute the tarball and packaged binary SHA-256 values.
4. Update every field in `.anthesis/cli-artifact.env` together.
5. Review archive members, CLI identity, supported contracts, platform, linkage, workflow, and toolchain assertions.
6. Run all structural and executable validations on the pull request.
7. Reject mutable tags, partial pin updates, or verification bypasses.

## 11. Cleanup

Temporary directories are repository-contained and removed automatically. Remove a locally installed evaluator with:

```bash
rm -rf .anthesis/bin
```

Do not remove the canonical policy, runtime profile, release pin, or scenario fixtures.
