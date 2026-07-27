# Anthesis Governance Lab

A deliberately small, executable trial repository for deterministic governance of AI-assisted SDLC workflows.

This repository consumes the accepted public Governance Lab contract from [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community/tree/main/specs/governance-lab). It does not contain private Anthesis source. The policy, runtime profile, and seven canonical scenarios are pinned public-contract fixtures under `.anthesis/`.

## Documentation

- [Governance Lab operator runbook](docs/runbooks/governance-lab-demo.md)
- [Scenario catalog](docs/scenarios/catalog.md)
- [Machine-readable canonical catalog](docs/scenarios/catalog.json)
- [Baseline SDLC demo packs](docs/scenarios/demo-packs.md)
- [Machine-readable demo catalog](docs/scenarios/demo-catalog.json)
- [Scenario authoring guide](docs/scenarios/authoring.md)
- [Decision and report interpretation](docs/scenarios/interpretation.md)

The runbook is the primary entry point for fresh-clone setup, verified evaluator acquisition, canonical execution, troubleshooting, and the five-minute walkthrough.

## Supported trial platform

The executable trial currently supports **Linux x86_64**. It uses a statically linked Rust `anthesis-lab` release and requires:

```text
bash curl sha256sum tar jq realpath
```

The evaluator is downloaded anonymously from an immutable release in `hackelia-micrantha/anthesis-community`. `.anthesis/cli-artifact.env` pins the full private Anthesis source commit, public release tag, tarball checksum, packaged binary checksum, CLI version, and supported contract set.

## Fresh-clone trial

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab

bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"

anthesis-lab version --format json
anthesis-lab test --repo . --format json
```

No GitHub token or private Anthesis checkout is required.

For the complete canonical and governance-drift validation:

```bash
bash scripts/validate-governance-lab.sh
```

For repository documentation and catalog contract validation:

```bash
bash scripts/validate-docs-and-catalog.sh
```

## Immutable release pin

Current release identity:

```text
source commit: 01540df98e08dc5fa7a01e29c07132a67b5cb59a
release tag: anthesis-lab-01540df98e08dc5fa7a01e29c07132a67b5cb59a
tarball SHA-256: 7539a368acf22c2e7293a0edbefddb33236a16d3c1eabab80c20176666ba1e15
binary SHA-256: 63a213315f1940675700493fcedda6a1854c6792b6f74eebd5c7f7203f34e70a
CLI version: 0.1.0
```

Upgrades must change all identity values together in a reviewed pull request. The acquisition script must then verify the release checksum asset, provenance manifest, archive allowlist, packaged binary checksum, explicit binary checksum, CLI version, and exact supported contract set. Never replace this pin with a mutable `latest` URL.

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

## Baseline SDLC demo packs

Four non-canonical packs under `.anthesis/demos` add 12 synthetic declarations for documentation, source-code, CI/release, and dependency workflows. They cover `allow`, `approval_required`, policy-rule `deny`, and default `deny` outcomes without changing the accepted policy.

These fixtures are cataloged and structurally validated. Issue #9 tracks the stable pack runner and real executable pack selection. No declared effect is executed by this repository.

The evaluator parses and decides declared attempts. It does **not** execute file, command, network, merge, deployment, release, or repository-administration effects, and it does not persist approvals.

## Integration boundary

This repository proves evaluator compatibility and deterministic policy decisions. It does not by itself prove bypass-resistant effect enforcement.

A production integration must ensure effectful tools are reachable only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point:

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

Registering Anthesis beside unwrapped effectful tools is insufficient.

## CI trust boundary

Pull requests and `main` both run the real Rust CLI without secrets. CI downloads only the immutable public release pinned in `.anthesis/cli-artifact.env`, verifies its provenance and checksums before extraction, and fails closed before scenario execution on any identity mismatch.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
