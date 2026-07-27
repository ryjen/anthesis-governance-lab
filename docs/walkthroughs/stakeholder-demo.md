# Stakeholder Governance Lab Walkthrough

## Situation

AI-assisted software systems can propose useful changes quickly, but ordinary automation does not reliably distinguish low-risk work from workflow changes, dependency updates, secret access, merges, or releases. Teams need a reproducible way to show which actions are allowed, which require approval, and which must be denied.

## Task

Demonstrate a bounded governance layer using public Anthesis contracts and synthetic software-delivery scenarios. The demonstration must be deterministic, reviewable, safe to run, and honest about the boundary between policy evaluation and effect enforcement.

## Action

The Governance Lab combines:

- an immutable, anonymously downloadable Rust `anthesis-lab` release built from a reviewed Anthesis source commit;
- external and packaged SHA-256 verification plus machine-readable source and build provenance;
- seven canonical conformance scenarios;
- four themed packs covering documentation, source code, CI and release, and dependencies;
- a versioned aggregate report containing all 12 demo outcomes;
- a curated five-case showcase spanning allow, approval-required, policy deny, engine-guard deny, and expectation drift.

Run the evidence:

```bash
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
bash scripts/validate-governance-lab.sh
bash scripts/validate-demo-packs.sh
bash scripts/aggregate-demo-packs.sh | jq .
```

## Result

A successful run demonstrates that the same pinned evaluator, declarations, and governance contracts produce stable decisions and evidence:

- scoped documentation and source changes can be allowed;
- CI and dependency changes can be held for external approval;
- merge and release actions can be denied;
- unknown runtimes can fail closed independently of ordinary policy matching;
- altered expectations do not change the policy decision and are surfaced as exit code `7`;
- all four packs and 12 scenarios are reconciled against the catalog;
- external reviewers and pull requests can reproduce the real-binary validation without a private producer credential.

## What this proves

The lab demonstrates immutable evaluator acquisition, deterministic policy evaluation, bounded scenario selection, fail-closed catalog validation, explicit decision provenance, and reproducible reporting suitable for engineering and governance review.

## What this does not prove

The lab does not execute declared actions, persist approvals, sign production evidence, or prevent bypass through ungoverned tools. A deployed system must bind the decision to a governed executor, gateway, broker, supervisor dispatch boundary, sandbox, or comparable enforcement layer.

## Project relationships

- **Anthesis:** private evaluator implementation and trusted release producer.
- **Anthesis community:** public contracts and immutable binary distribution surface.
- **Anthesis Governance Lab:** reproducible public demonstration fixtures, validation, and walkthroughs.
- **Dubnium:** a potential governed-agent and execution environment where Anthesis decisions can be integrated with bounded tool access.
