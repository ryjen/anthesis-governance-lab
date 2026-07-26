# Anthesis Governance Lab

A deliberately small, executable trial repository for deterministic governance of AI-assisted SDLC workflows.

This repository consumes the accepted public Governance Lab contract from [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community/tree/main/specs/governance-lab). It does not contain private Anthesis source. The policy, runtime profile, and seven canonical scenarios are pinned public-contract fixtures under `.anthesis/`.

## Documentation

- [Governance Lab operator runbook](docs/runbooks/governance-lab-demo.md)
- [Scenario catalog](docs/scenarios/catalog.md)
- [Machine-readable catalog](docs/scenarios/catalog.json)
- [Scenario authoring guide](docs/scenarios/authoring.md)
- [Decision and report interpretation](docs/scenarios/interpretation.md)

The runbook is the primary entry point for fresh-clone setup, verified evaluator acquisition, canonical execution, troubleshooting, and the five-minute walkthrough.

## Supported trial platform

The executable trial currently supports **Linux x86_64**. It uses a statically linked Rust `anthesis-lab` artifact and requires:

```text
bash curl sha256sum unzip tar jq realpath
```

The current acquisition path is transitional: it uses a checksum-pinned GitHub Actions artifact that requires `GITHUB_TOKEN`. Issue #4 tracks migration to an anonymously downloadable immutable public release. Do not describe the current path as secretless.

## Fresh-clone trial

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab

export GITHUB_TOKEN=... # required by the current transitional artifact path
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"

anthesis-lab version --format json
anthesis-lab test --repo . --format json
```

For the complete canonical and governance-drift validation:

```bash
bash scripts/validate-governance-lab.sh
```

For repository documentation and catalog contract validation:

```bash
bash scripts/validate-docs-and-catalog.sh
```

## Canonical scenarios

`anthesis-lab test --repo . --format json` discovers `.anthesis/scenarios` and evaluates seven fixtures in deterministic lexical order:

| Scenario | Expected result | What it demonstrates |
|---|---|---|
| `01-allowed-docs-edit` | `allow` | Scoped documentation write. |
| `02-block-ci-change` | `approval_required` | CI workflow mutation requires approval. |
| `03-require-network-approval` | `approval_required` | External network access requires approval. |
| `04-block-secret-access` | `deny` | Secret-like path protection takes precedence. |
| `05-require-dependency-approval` | `approval_required` | Dependency changes require approval. |
| `06-fail-unknown-runtime` | `deny` from `engine_guard` | Unregistered runtime fails closed. |
| `07-block-evidence-tamper` | `deny` | Evidence mutation is blocked. |

The canonical suite must report:

```json
{
  "version": "anthesis.test-report/v1",
  "passed": true,
  "total": 7,
  "passed_count": 7,
  "failed_count": 0
}
```

The evaluator parses and decides declared attempts. It does **not** execute file, command, network, merge, deployment, release, or repository-administration effects, and it does not persist approvals.

## Integration boundary

This repository proves evaluator compatibility and deterministic policy decisions. It does not by itself prove bypass-resistant effect enforcement.

A production integration must ensure effectful tools are reachable only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point:

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

Registering Anthesis beside unwrapped effectful tools is insufficient.

## CI trust boundary

Pull requests run secretless structural validation. Trusted executable validation currently runs only on `main` with the pinned artifact credential. The planned immutable public release will allow executable validation without a private producer token once issue #4 is complete.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
