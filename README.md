# Anthesis Governance Lab

A deliberately small, executable trial repository for deterministic governance of AI-assisted SDLC workflows.

This repository consumes the accepted public Governance Lab contract from [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community/tree/main/specs/governance-lab). It does not contain private Anthesis source. The policy, runtime profile, and seven canonical scenarios are pinned public-contract fixtures under `.anthesis/`.

## Documentation

- [Governance Lab operator runbook](docs/runbooks/governance-lab-demo.md)
- [Five-minute walkthrough](docs/walkthroughs/five-minute-demo.md)
- [Stakeholder walkthrough](docs/walkthroughs/stakeholder-demo.md)
- [Scenario catalog](docs/scenarios/catalog.md)
- [Machine-readable canonical catalog](docs/scenarios/catalog.json)
- [Demo packs](docs/scenarios/demo-packs.md)
- [Machine-readable demo catalog](docs/scenarios/demo-catalog.json)
- [Scenario authoring guide](docs/scenarios/authoring.md)
- [Decision and report interpretation](docs/scenarios/interpretation.md)

## Supported trial platform

The executable trial supports **Linux x86_64**. It uses a statically linked Rust `anthesis-lab` release and requires:

```text
bash curl sha256sum tar jq realpath
```

The evaluator is downloaded anonymously from an immutable release in `hackelia-micrantha/anthesis-community`. `.anthesis/cli-artifact.env` pins the full Anthesis source commit, public release tag, tarball checksum, packaged binary checksum, CLI version, and supported contract set.

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

Run the complete validation:

```bash
bash scripts/validate-governance-lab.sh
bash scripts/validate-demo-packs.sh
bash scripts/validate-docs-and-catalog.sh
bash scripts/validate-walkthroughs.sh
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

Upgrades must change all identity values together in a reviewed pull request. Never replace this pin with a mutable `latest` URL or skip a verification layer.

## Canonical scenarios

`anthesis-lab test --repo . --format json` evaluates seven public-contract fixtures in deterministic lexical order. A passing report uses `anthesis.test-report/v1`, reports seven total and seven passed scenarios, and contains zero failures.

## Demo catalog

Nine non-canonical packs under `.anthesis/demos` contain 27 synthetic declarations:

- documentation;
- source code;
- CI and release;
- dependencies;
- secrets and evidence;
- network and tools;
- runtime and identity;
- deployment and administration;
- adversarial policy-bypass and capability-expansion attempts.

The catalog covers `allow`, `approval_required`, policy-rule `deny`, policy-default `deny`, and engine-guard `deny`. It never executes declared effects.

```bash
bash scripts/run-demo-pack.sh --list
bash scripts/run-demo-pack.sh adversarial | jq .
bash scripts/aggregate-demo-packs.sh | jq .
```

## Integration boundary

This repository proves evaluator compatibility and deterministic policy decisions. It does not execute file, command, network, merge, deployment, release, or repository-administration effects, persist approvals, or prevent bypass through ungoverned tools.

A production integration must ensure effectful tools are reachable only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point:

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

## CI trust boundary

Pull requests and `main` both run the real Rust CLI without secrets. CI downloads only the immutable public release pinned in `.anthesis/cli-artifact.env`, verifies its provenance and checksums before extraction, and fails closed before scenario execution on any identity mismatch.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
