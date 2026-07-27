# Anthesis Governance Lab

A deliberately small, executable trial repository for deterministic governance of AI-assisted SDLC workflows.

This repository consumes the accepted public Governance Lab contract and immutable CLI releases from [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community). It contains no private Anthesis source. The policy, runtime profile, canonical scenarios, release identity, and checksums are pinned under `.anthesis/`.

## Documentation

- [Governance Lab operator runbook](docs/runbooks/governance-lab-demo.md)
- [Five-minute walkthrough](docs/walkthroughs/five-minute-demo.md)
- [Stakeholder walkthrough](docs/walkthroughs/stakeholder-demo.md)
- [Scenario catalog](docs/scenarios/catalog.md)
- [Machine-readable canonical catalog](docs/scenarios/catalog.json)
- [Baseline SDLC demo packs](docs/scenarios/demo-packs.md)
- [Machine-readable demo catalog](docs/scenarios/demo-catalog.json)
- [Scenario authoring guide](docs/scenarios/authoring.md)
- [Decision and report interpretation](docs/scenarios/interpretation.md)

## Supported trial platform

The executable trial supports **Linux x86_64** with a statically linked Rust `anthesis-lab` binary. Required tools:

```text
bash curl sha256sum tar jq realpath
```

## Fresh-clone trial

No repository secret or private source checkout is required:

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab

bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"

anthesis-lab version --format json
anthesis-lab test --repo . --format json
```

The acquisition script downloads the exact tag recorded in `.anthesis/cli-artifact.env` from the public distribution repository. Before execution it verifies:

- the approved repository and source-bound release tag;
- the externally pinned tarball SHA-256;
- the published checksum file;
- the provenance schema, private source commit, source ref, distribution identity, build workflow, toolchain, platform, and linkage;
- the complete archive-member allowlist;
- the packaged and externally pinned binary SHA-256;
- the CLI name, version, and required public contracts.

## Validation

```bash
bash scripts/validate-governance-lab.sh
bash scripts/validate-demo-packs.sh
bash scripts/validate-docs-and-catalog.sh
bash scripts/validate-walkthroughs.sh
```

The canonical suite evaluates seven fixtures in deterministic lexical order and must report:

```json
{
  "version": "anthesis.test-report/v1",
  "passed": true,
  "total": 7,
  "passed_count": 7,
  "failed_count": 0
}
```

The intentional expectation-drift exercise must complete evaluation and return exit code `7`.

## Demo packs

Four non-canonical packs under `.anthesis/demos` contain 12 synthetic declarations covering documentation, source code, CI/release, and dependency workflows. They exercise `allow`, `approval_required`, policy-rule `deny`, engine-guard `deny`, and default-deny behavior without executing declared effects.

```bash
bash scripts/run-demo-pack.sh --list
bash scripts/run-demo-pack.sh documentation | jq .
bash scripts/aggregate-demo-packs.sh | jq .
```

## Integration boundary

This repository proves evaluator compatibility and deterministic policy decisions. It does not execute file, command, network, merge, deployment, release, or repository-administration effects, persist approvals, or prevent bypass through ungoverned tools.

A production integration must ensure effectful tools are reachable only through a governed wrapper, gateway, broker, supervisor dispatch boundary, sandbox, or equivalent enforcement point:

```text
agent -> governed boundary -> Anthesis decision -> approval check -> bounded executor
```

## CI trust boundary

Pull requests and `main` both acquire the real Rust CLI anonymously from the immutable public release and run executable validation with read-only workflow permissions. No private producer credential or protected acquisition environment is required.

## Upgrade policy

Upgrades are explicit pull requests. Change the source revision, tag, release asset SHA-256, binary SHA-256, provenance schema, and CLI version together. Run the complete canonical, mismatch, demo-pack, aggregate, and documentation validation. Never replace the immutable tag with `latest` or skip a verification layer.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
