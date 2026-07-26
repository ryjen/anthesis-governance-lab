# Anthesis Governance Lab

A deliberately small, executable trial repository for deterministic governance of AI-assisted SDLC workflows.

This repository consumes the accepted public Governance Lab contract from [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community/tree/main/specs/governance-lab). It does not contain private Anthesis source. The policy, runtime profile, and seven scenarios are pinned public-contract fixtures under `.anthesis/`.

## Supported trial platform

The executable trial currently supports **Linux x86_64**. It uses the statically linked Rust `anthesis-lab` artifact promoted by `hackelia-micrantha/anthesis#80` and exercised by the Rust-native `test` command merged in `hackelia-micrantha/anthesis#82`.

The exact artifact identity is recorded in `.anthesis/cli-artifact.env`:

- Anthesis revision: `799b297a54c31ac23649ebe5bb5b736131847b71`
- successful workflow run: `30081640756`
- artifact ID: `8592392312`
- GitHub artifact archive SHA-256: `8864b47c6cbb010a84ad1df36ac02b4e9ef92476a60dbac8c6249975eb2fef4c`
- artifact expiry: `2026-10-22T09:11:11Z`

GitHub Actions artifacts are immutable for their retention lifetime but are not permanent releases. After the recorded expiry, this repository must be repinned to a new promoted immutable artifact or a durable release asset; it must not fall back to a mutable `latest` download.

## Fresh-clone trial

Requirements:

- Linux x86_64
- `bash`, `curl`, `sha256sum`, `unzip`, `tar`, and `jq`
- a GitHub token able to download the pinned public-repository Actions artifact, exported as `GITHUB_TOKEN`

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab

export GITHUB_TOKEN=... # token is sent only to api.github.com
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"

anthesis-lab version --format json
anthesis-lab test --repo . --format json
```

The acquisition script performs verification in this order:

1. downloads only the pinned artifact URL over HTTPS;
2. verifies the downloaded ZIP against the GitHub-recorded SHA-256 digest;
3. extracts the single promoted tarball into a repository-contained temporary directory;
4. verifies the binary against the packaged `anthesis-lab.sha256` file;
5. installs the executable under `.anthesis/bin/` only after both checks pass.

A checksum mismatch is fatal. There is no fallback download or execution path.

For the complete canonical and drift exercise used by CI:

```bash
bash scripts/validate-governance-lab.sh
```

## Public contract check

`anthesis-lab version --format json` must identify `anthesis-lab` and advertise support for:

- `anthesis.policy/v1`
- `anthesis.lab-profile/v1`
- `anthesis.scenario/v1`
- `anthesis.decision/v1`

An absent contract is treated as an unsupported CLI/fixture combination. Repin deliberately; do not weaken the assertions.

## Canonical scenarios

`anthesis-lab test --repo . --format json` discovers `.anthesis/scenarios` by default and evaluates these fixtures in deterministic lexical order:

| Scenario | Expected result | What it demonstrates |
|---|---|---|
| `01-allowed-docs-edit` | `allow` | A scoped documentation write is allowed by the explicit write rule. |
| `02-block-ci-change` | `approval_required` | CI workflow mutation crosses a higher-impact boundary and requires approval. |
| `03-require-network-approval` | `approval_required` | External network access is approval-gated. |
| `04-block-secret-access` | `deny` | Secret-like paths are denied before broad repository-read permission can match. |
| `05-require-dependency-approval` | `approval_required` | Dependency manifest changes require approval. |
| `06-fail-unknown-runtime` | `deny` from `engine_guard` | An unregistered runtime fails closed independently of normal policy-rule matching. |
| `07-block-evidence-tamper` | `deny` | Writes to the evidence namespace are denied before broader write rules. |

The passing report contract is:

```json
{
  "version": "anthesis.test-report/v1",
  "passed": true,
  "total": 7,
  "passed_count": 7,
  "failed_count": 0
}
```

CI also verifies that all seven per-scenario entries have `passed: true` and preserves the CLI process status. A canonical-suite status other than `0` fails validation.

The evaluator parses and decides on declared attempts. It does **not** execute file, command, network, merge, deployment, or release effects.

## Intentional governance-drift exercise

`scripts/validate-governance-lab.sh` creates a temporary fixture below `.anthesis/validation.*`, copies the canonical policy/profile/scenarios, and changes only scenario 01's copied expected decision from `allow` to `deny`. It then runs the same zero-configuration command against that temporary repository.

Expected behavior:

- canonical checked-in fixtures remain unchanged;
- the actual policy decision remains `allow`;
- the copied expectation mismatches that decision;
- the report contains `6` passed and `1` failed scenario;
- `anthesis-lab test` exits with **status `7`**.

This demonstrates detection of governance expectation drift without weakening production policy or executing any declared effect.

## Integration mode and trust boundary

This repository uses the **direct CLI / tool-wrapper integration mode**: a trusted workflow invokes a checksum-verified `anthesis-lab` executable before any real effect executor is permitted to act.

Policy evaluation and structural enforcement are distinct:

- **Policy evaluation** answers whether a declared attempt is allowed, denied, or approval-gated and explains the matching rule or engine guard.
- **Structural enforcement** ensures there is no alternate path from an agent to the real tool, MCP server, command runner, credential, merge API, deployment API, or release system that bypasses that decision.

This lab proves the evaluation contract only. It does not, by itself, prove bypass resistance. A production direct-wrapper integration requires an invariant such as:

> The agent-visible registry contains only the governed wrapper, and only that wrapper holds reachability or credentials for effectful tools after an allow decision or satisfied approval.

Equivalent real integrations may enforce the invariant at an MCP gateway, supervisor dispatch boundary, capability broker, sandbox syscall boundary, or isolated execution service. Registering Anthesis alongside unwrapped effectful tools is not sufficient, because an agent could call those tools directly.

Trust assumptions for this trial:

- the checked-out repository, pinned artifact metadata, shell scripts, runner image, and GitHub API response path are trusted;
- the artifact remains available and unexpired;
- the token can read the pinned artifact but is not exposed to scenario content;
- the local administrator and workflow maintainer are not hostile;
- no production effect credentials are present in the evaluator process.

The trial criteria and required enforcement invariants are tracked in [`hackelia-micrantha/anthesis#59`](https://github.com/hackelia-micrantha/anthesis/issues/59).

## Troubleshooting

### Artifact or checksum failure

Confirm Linux x86_64, the artifact expiry, token access, and the exact values in `.anthesis/cli-artifact.env`. Never substitute `latest`, skip either digest check, or execute a partially downloaded file. Repinning requires recording a new Anthesis revision, workflow run, artifact ID, archive digest, and expiry together.

### Unsupported contract

Run `anthesis-lab version --format json`. The four contract identifiers above must all be present. A newer CLI or fixture revision may require a deliberate coordinated update rather than relaxed assertions.

### Scenario failure

Run:

```bash
anthesis-lab test --repo . --format json | jq .
```

Inspect each failing scenario's `expected`, `actual`, and `mismatches` fields. Preserve the original exit code while capturing output; status `7` means expectation mismatch, while invalid or unsupported inputs use different failure categories.

### Temporary fixture safety

The validation scripts require installation and temporary paths to remain below the canonical repository root. The Rust CLI independently rejects absolute scenario collection paths, repository escapes, and symlinked scenario paths.

## License

Licensed under the Apache License 2.0. See [LICENSE](./LICENSE).
