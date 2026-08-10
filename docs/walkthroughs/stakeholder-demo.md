# Stakeholder Governance Lab Walkthrough

## Situation

AI-assisted software systems can propose useful changes quickly, but ordinary automation does not reliably distinguish low-risk work from workflow changes, dependency updates, secret access, unrestricted tools, unknown runtimes, policy-bypass attempts, merges, deployments, or releases. Teams need a reproducible way to show which actions are allowed, which require approval, and which must be denied.

## Task

Demonstrate a bounded governance layer using public Anthesis contracts and synthetic software-delivery scenarios. The demonstration must be deterministic, reviewable, safe to run, and honest about the boundary between policy evaluation and effect enforcement.

This walkthrough focuses on the 7-scenario canonical governance contract and the 9 general demo packs / 27 scenarios. The separate 24-scenario inference-integrity contract can be added as an extension when inference verification is relevant. See the [inference-integrity runbook](../runbooks/inference-integrity-demo.md) or [full verification runbook](../runbooks/full-verification.md).

## Action

The Governance Lab combines:

- the promoted Rust `anthesis-lab` evaluator from the Anthesis repository;
- anonymous immutable release acquisition with Sigstore, provenance, and checksum verification;
- seven canonical conformance scenarios;
- nine themed packs spanning 27 documentation, source, CI/release, dependency, secret/evidence, network/tool, runtime/identity, deployment/administration, and adversarial declarations;
- a versioned aggregate report preserving each pack result;
- a curated five-case showcase spanning allow, approval-required, policy deny, engine-guard deny, and expectation drift.

Run the evidence:

```bash
bash scripts/validate-governance-lab.sh
bash scripts/validate-demo-packs.sh
bash scripts/aggregate-demo-packs.sh | jq .
```

Optional inference-integrity extension:

```bash
bash scripts/validate-executable-inference-integrity.sh
```

## Result

A successful general-governance run demonstrates that the same pinned declarations and governance contracts produce stable decisions and evidence:

- scoped documentation, source, read, and test declarations can be allowed;
- CI, dependency, and external-network declarations can be held for external approval;
- secret access, evidence mutation, unrestricted commands, absolute host paths, merge, deployment, and release declarations can be denied;
- policy-bypass wording does not alter deterministic rule matching;
- unknown runtimes fail closed independently of ordinary policy matching;
- altered expectations do not change the policy decision and are surfaced as exit code `7`;
- all nine packs and 27 scenarios are reconciled against the catalog.

When the inference-integrity extension is included, the expected aggregate result is 24 passing scenarios, zero failures, deterministic repeated JSON output, and a controlled mismatch detected with exit code `7`.

## What this proves

The lab demonstrates deterministic policy evaluation, bounded scenario selection, fail-closed catalog validation, explicit decision provenance, immutable public evaluator acquisition, and reproducible reporting suitable for engineering and governance review. The inference-integrity extension additionally demonstrates deterministic evaluation of recorded provider-neutral inference evidence.

## What this does not prove

The lab does not execute declared actions, persist approvals, invoke live model providers, perform independent live replay, execute containment, sign production evidence, or prevent bypass through ungoverned tools. A deployed system must bind the decision to a governed executor, gateway, broker, supervisor dispatch boundary, sandbox, or comparable enforcement layer.

## Project relationships

- **Anthesis:** policy authority, evaluator semantics, runtime/decision/scenario contracts, inference-integrity verification semantics, and reports.
- **Anthesis Governance Lab:** reproducible public demonstration fixtures, validation, reports, and walkthroughs.
- **Dubnium:** reference live-runtime integration for bounded tool access, gateway metadata, seed/sampling evidence, replay, verifier execution, containment, and recovery.
- **Anthesis community releases:** immutable public distribution of the reviewed evaluator used by this demo.
