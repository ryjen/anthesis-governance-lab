# Anthesis Governance Lab

A deliberately small, executable trial repository for deterministic governance of AI-assisted SDLC workflows.

This repository is an independent public consumer of the accepted Anthesis Governance Lab contract and signed `anthesis-lab` release. It does not contain private Anthesis source and is not part of the production runtime execution path.

## Documentation

- [Micrantha architecture context](docs/micrantha-architecture-context.md)
- [Governance Lab operator runbook](docs/runbooks/governance-lab-demo.md)
- [Full verification runbook](docs/runbooks/full-verification.md)
- [Governed repository reference trial](docs/reference-trial.md)
- [Design-partner evaluation](docs/evaluation.md)
- [Inference-integrity runbook](docs/runbooks/inference-integrity-demo.md)
- [Five-minute walkthrough](docs/walkthroughs/five-minute-demo.md)
- [Stakeholder walkthrough](docs/walkthroughs/stakeholder-demo.md)
- [Inference-integrity presentation tracks](docs/walkthroughs/inference-integrity-presentation-tracks.md)
- [Canonical scenario catalog](docs/scenarios/catalog.md)
- [Machine-readable canonical catalog](docs/scenarios/catalog.json)
- [Demo packs](docs/scenarios/demo-packs.md)
- [Machine-readable demo catalog](docs/scenarios/demo-catalog.json)
- [External agent-security crosswalk](docs/scenarios/external-security-crosswalk.md)
- [Machine-readable external security crosswalk](docs/scenarios/external-security-crosswalk.json)
- [External agent-security test vectors](docs/scenarios/external-security-fixtures.md)
- [Inference-integrity fixtures and executable contract](docs/scenarios/inference-integrity-fixtures.md)
- [Scenario authoring guide](docs/scenarios/authoring.md)
- [Decision and report interpretation](docs/scenarios/interpretation.md)

Use the operator runbook to understand the demo surfaces, the full verification runbook to reproduce every current proof surface from a fresh checkout, the reference trial for the bounded governed-effect demonstration, the evaluation guide when handing the lab to a design partner, and the five-minute walkthrough for a short stakeholder presentation.

## Supported trial platform

The executable trial supports **Linux x86_64**. It uses a statically linked Rust `anthesis-lab` release and requires:

```text
git bash curl cosign sha256sum tar jq realpath
```

No GitHub token, private Anthesis checkout, GPU, live model, or hosted service is required.

## Fresh-clone trial

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab

bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"

anthesis-lab version --format json
anthesis-lab test --repo . --format json
anthesis-lab inference-integrity --repo . --format json
bash scripts/run-reference-trial.sh
```

Run the complete validation:

```bash
bash scripts/validate-governance-lab.sh
bash scripts/validate-demo-packs.sh
bash scripts/validate-executable-inference-integrity.sh
bash scripts/validate-docs-and-catalog.sh
bash scripts/validate-external-security-crosswalk.sh
bash scripts/validate-external-security-fixtures.sh
bash scripts/validate-walkthroughs.sh
```

For expected counts, negative controls, evidence generation, and interpretation of the complete result, follow [`docs/runbooks/full-verification.md`](docs/runbooks/full-verification.md).

## Signed immutable release pin

`.anthesis/cli-artifact.env` is the machine-readable source of truth for the complete release identity:

```bash
cat .anthesis/cli-artifact.env
```

It pins one reviewed transaction containing:

- the full private Anthesis source commit;
- the source-bound public release tag;
- archive and packaged-binary SHA-256 digests;
- CLI version and supported contracts;
- mandatory Sigstore verification.

Acquisition downloads the archive, checksum, provenance, and their Sigstore bundles from `hackelia-micrantha/anthesis-community`. It verifies the exact producer repository, protected source ref, release workflow identity, source commit, and GitHub Actions OIDC issuer **before** trusting checksum or provenance content, extracting the archive, or executing the binary.

Upgrades must change all identity values together in a reviewed pull request. Never use a mutable `latest` URL, mix values from two releases, or skip a verification layer.

## Proof surfaces and counts

The repository intentionally keeps three scenario surfaces separate. The counts are independent: the 24 inference-integrity cases are not part of the 27 general demo scenarios.

### Canonical Governance Lab contract — 7 scenarios

`anthesis-lab test --repo . --format json` evaluates seven pinned public-contract fixtures in deterministic lexical order. They cover allow, approval-required, policy denial, and engine-guard denial. `scripts/validate-governance-lab.sh` adds the controlled expectation-drift check.

### General demonstration catalog — 9 packs / 27 scenarios

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

```bash
bash scripts/run-demo-pack.sh --list
bash scripts/run-demo-pack.sh adversarial | jq .
bash scripts/aggregate-demo-packs.sh | jq .
```

These scenarios evaluate declared effects but never execute them.

### Inference-integrity contract — 24 scenarios

`anthesis-lab inference-integrity --repo . --format json` evaluates 24 provider-neutral synthetic cases covering:

- execution identity and evidence binding;
- seed and token integrity;
- verifier trust and verification classes;
- covert-channel capacity accounting;
- routing, fallback, and gateway enforcement;
- supervisor, specialist, and synthesis localization;
- immutable re-verification and mutation rejection;
- cross-provider semantic verification;
- observe, selective-gate, and required-gate behavior;
- policy-authorized sampling escalation and recovery.

```bash
bash scripts/validate-executable-inference-integrity.sh
bash scripts/generate-inference-integrity-evidence.sh
```

The generated evidence bundle records 24 passing results, a controlled mismatch with exit code `7`, release identity, report contract, source revisions, and file checksums.

### Executable reference trial — one governed repository mutation

`scripts/run-reference-trial.sh` composes the signed evaluator with a deliberately constrained local tool-wrapper runtime. It evaluates the canonical allowed `file.write` request, performs that exact mutation only through `anthesis.repo_write`, then verifies two runtime denials:

- `raw.repo_write` is not registered and hard-denies with repository state unchanged;
- the registered writer cannot mutate `.github/workflows/ci.yml` because that path is outside the exact authorized effect.

The resulting Git diff and `reference-trial.json` make the allowed mutation and both denied paths inspectable. This is a bounded runtime-enforcement demonstration, not a universal complete-mediation claim. See [`docs/reference-trial.md`](docs/reference-trial.md).

### External security crosswalk and vectors

`docs/scenarios/external-security-crosswalk.json` maps existing public proof surfaces to selected CoSAI and OWASP agent-security topics using explicit coverage states: `demonstrated`, `partial`, `runtime-dependent`, `not-demonstrated`, and `not-applicable`.

The crosswalk is non-normative. It records what current synthetic fixtures prove and, equally importantly, what they do not prove. `scripts/validate-external-security-crosswalk.sh` verifies that mapped demo and inference scenario IDs actually exist and that required assurance limitations are retained.

`fixtures/external-security/` contains provider-neutral structural test vectors for evidence-state-versus-authority and manifest-version-versus-action-time binding. They do not extend the current `anthesis-lab` evaluator contract or execute effects. `scripts/validate-external-security-fixtures.sh` checks the vector contracts and paired fail-closed invariants.

## Integration boundary

The canonical, demo-pack, inference-integrity, and external-security fixture surfaces prove public evaluator/fixture compatibility and deterministic outcomes over synthetic declarations or recorded evidence. Those surfaces do not execute their declared external effects.

The executable reference trial is intentionally different: it performs one bounded file mutation in a disposable Git repository through a constrained `anthesis.repo_write` wrapper and verifies that two equivalent or broader paths are hard-denied inside that stated composition.

Governance Lab still does not:

- persist approvals or demonstrate post-approval execution;
- invoke an LLM or provider;
- perform independent live replay;
- execute containment or recovery actions;
- prove hostile-local-user or administrator containment;
- prove that an arbitrary external runtime cannot bypass Anthesis through ungoverned tools, credentials, network paths, or processes.

A production integration must ensure effectful paths are reachable only through an enforced governance boundary:

```text
agent request
  -> Anthesis decision and capability boundary
  -> exact approval when required
  -> bounded executor or runtime enforcement
  -> attributable evidence and outcome
```

Dubnium provides the bounded reference execution environment; Anthesis remains the policy authority; Governance Lab independently validates the public evaluator contract and provides a small local enforcement composition for evaluation.

## CI trust boundary

Pull requests and `main` run the real Rust CLI without repository secrets. CI verifies Sigstore identity, provenance, checksums, archive members, binary identity, and supported contracts before scenario execution. Any identity mismatch, unavailable verifier, malformed metadata, repository escape, or unsupported contract fails closed.

## License

Licensed under the Apache License 2.0. See [LICENSE](LICENSE).
