# Inference-Integrity Governance Lab Runbook

## Purpose

This runbook demonstrates how Anthesis evaluates synthetic inference evidence for seed integrity, token substitution, route and fallback governance, verifier trust, covert-channel capacity, supervisor/specialist localization, immutable re-verification, verification-class honesty, operating modes, sampling escalation, and authorized recovery.

The default demonstration is provider-neutral and does not require a GPU, network access after evaluator acquisition, a live model, provider credentials, or Dubnium services.

This is the **24-scenario inference-integrity proof surface**. It is separate from the 7 canonical governance scenarios and the 9 general governance demo packs / 27 scenarios. For one end-to-end procedure covering all three surfaces, use [`full-verification.md`](full-verification.md).

## Responsibility boundary

| Component | Responsibility |
| --- | --- |
| Anthesis | Verification classes, evaluator semantics, verdicts, policy postures, reports, and exit codes |
| Governance Lab | Portable fixtures, execution packaging, reproducible evidence bundles, and presentation guidance |
| Dubnium | Live gateway metadata, seed and sampling evidence, replay production, verifier execution, and platform actions |

Verifier output is evidence. It does not directly authorize release, quarantine, suspension, isolation, sampling changes, or recovery.

## Prerequisites

Supported platform: Linux x86_64.

Required tools:

```text
bash curl cosign sha256sum tar jq realpath
```

Network access is required only when initially acquiring the pinned public CLI.

Acquire the signed, checksum-verified public CLI:

```bash
bash scripts/acquire-anthesis-lab.sh
```

Acquisition verifies the Sigstore identity of the archive, checksum, and provenance assets before trusting their contents, then validates the pinned checksums, provenance fields, archive-member allowlist, packaged binary, CLI identity, and supported contract set.

## Quick start

Run the complete canonical 24-case suite:

```bash
.anthesis/bin/anthesis-lab inference-integrity \
  --repo . \
  --format json | jq .
```

Expected result:

- report version: `anthesis.inference-integrity-report/v1alpha1`
- total scenarios: `24`
- passed scenarios: `24`
- failed scenarios: `0`
- exit code: `0`

Run the executable regression validation:

```bash
bash scripts/validate-executable-inference-integrity.sh
```

Expected final output:

```text
Inference-integrity executable suite: 24 passed; mismatch exit 7 verified
```

Generate the complete reproducible evidence bundle:

```bash
bash scripts/generate-inference-integrity-evidence.sh
```

The default output is:

```text
.anthesis/evidence/inference-integrity/
├── manifest.json
├── passing-report.json
├── passing-report.yaml
├── mismatch-report.json
└── SHA256SUMS
```

The manifest binds the reports to:

- the 24-case report contract;
- the Anthesis source revision;
- the immutable public release tag;
- archive and binary digests;
- mandatory Sigstore verification;
- the Governance Lab revision that generated the bundle.

Verify the bundle:

```bash
cd .anthesis/evidence/inference-integrity
sha256sum --check SHA256SUMS
```

## Running one scenario

The v1alpha1 evaluator executes the canonical suite as one contract. To inspect one scenario from the deterministic report:

```bash
.anthesis/bin/anthesis-lab inference-integrity \
  --repo . \
  --format json |
  jq '.scenarios[] | select(.scenario_id == "detect-token-substitution")'
```

Use the same pattern for any scenario ID in:

```text
fixtures/inference-integrity/scenario-suite-v1alpha1.yaml
```

## Reading the report

Each scenario reports:

- `expected`: the Anthesis-owned expected verdict, capability class, and policy posture;
- `actual`: the outcome computed independently from the recorded evidence;
- `passed`: whether the computed and expected outcomes match.

### Verification classes

| Class | Meaning |
| --- | --- |
| `fixed_seed` | Exact replay claim within one pinned execution identity and committed seed |
| `bounded_consistency` | Accepted-token, rank, probability, or bounded nondeterministic comparison |
| `semantic_only` | Content or task consistency without token-equivalence claims |
| `governance_only` | Route, role, evidence, authority, or lifecycle assertions only |
| `unsupported` | Evidence cannot support a stronger verification claim |

A weaker class must never be presented as deterministic token equivalence. Cross-provider comparison is semantic or governance verification, not fixed-seed equivalence.

### Verdicts

| Verdict | Interpretation |
| --- | --- |
| `conformant` | Evidence supports the declared verification claim |
| `suspicious` | Evidence warrants increased scrutiny or sampling |
| `dangerous` | Evidence supports quarantine, suspension, isolation, or forensic preservation through policy |
| `indeterminate` | Required evidence or verifier independence is unavailable or insufficient |

### Policy postures

Policy posture is the normalized expected governance response, not a platform action performed by the evaluator. Examples include:

- `allow`
- `allow_with_signal`
- `increase_sampling`
- `quarantine_response`
- `suspend_route`
- `isolate_specialist`
- `suspend_model_alias`
- `preserve_forensics`
- `fail_closed`

## Demonstration sequences

### Seed and token integrity

Inspect:

- `reject-runtime-selected-seed`
- `detect-token-substitution`
- `detect-seed-evidence-rewrite`

Key point: a runtime-controlled seed cannot support a fixed-seed claim, and rewritten seed evidence is preserved as a forensic event rather than silently replacing the original.

### Verifier trust

Inspect `reject-untrusted-verifier`.

Key point: a verifier sharing a common compromise root cannot establish independent assurance. The result becomes `indeterminate` and follows fail-closed policy.

### Capacity accounting and sampling

Inspect:

- `budget-low-capacity-discrepancy`
- `quarantine-dangerous-token`
- `aggregate-low-rate-leakage`
- `escalate-sampling-after-suspicious-evidence`

Key point: individually small discrepancies may remain below a per-execution threshold while cumulative correlated observations exceed the governed window. Sampling changes require policy authority rather than verifier self-escalation.

### Route and fallback enforcement

Inspect:

- `detect-plano-route-change`
- `block-fallback-to-unverifiable-route`
- `block-direct-runtime-bypass`

Key point: requested aliases do not replace resolved execution identity, fallback is visible, and governed traffic cannot silently bypass the stable gateway.

### Supervisor and specialist localization

Inspect:

- `localize-specialist-tamper`
- `detect-synthesis-tamper`

Key point: Anthesis can distinguish a suspicious specialist sub-run from synthesis-stage tampering and select a narrower policy posture.

### Immutable re-verification

Inspect:

- `preserve-original-on-reverification`
- `reject-reverification-mutation`
- `downgrade-unsupported-replay`

Key point: re-verification appends a linked result without rewriting original evidence. Mutation attempts preserve the original for forensics, and unsupported replay explicitly downgrades the verification claim.

### Cross-provider verification honesty

Inspect:

- `reject-cross-provider-fixed-seed-claim`
- `accept-semantic-only-provider-check`

Key point: heterogeneous-provider comparison may support a semantic claim but cannot truthfully claim deterministic token equivalence.

### Operating modes and recovery

Inspect:

- `observe-mode-releases-before-verification`
- `selective-gate-holds-high-risk-response`
- `required-gate-fails-closed-on-verifier-outage`
- `recover-route-after-approved-reverification`

Key point: observe, selective-gate, and required-gate modes have distinct release behavior. Recovery after suspension requires conformant re-verification, policy authorization, and operator approval.

## Controlled failure demonstration

The executable validator and evidence generator create a temporary copy of the suite and change one expected policy posture. The evaluator must return exit code `7` and produce a report with exactly one failed scenario.

This demonstrates that expected outcomes are assertions rather than trusted computed outcomes.

## Exit codes

| Code | Meaning |
| --- | --- |
| `0` | All computed outcomes match expectations |
| `3` | Invalid, malformed, missing, or repository-escaping contract |
| `7` | One or more computed outcomes differ from expectations |
| `8` | Unsupported contract version |
| `10` | Internal output failure |

## Reset

Remove generated evidence and the acquired CLI:

```bash
rm -rf .anthesis/evidence/inference-integrity
rm -rf .anthesis/bin
```

Reacquire and regenerate when needed:

```bash
bash scripts/acquire-anthesis-lab.sh
bash scripts/generate-inference-integrity-evidence.sh
```

## Current limitations

The released v1alpha1 evaluator processes 24 canonical synthetic scenarios over recorded provider-neutral evidence. It does not invoke providers, generate seeds, capture live token streams, perform independent replay, execute containment, or prove that arbitrary traffic cannot bypass an ungoverned runtime path.

The optional live Dubnium profile remains pending runtime evidence, replay, verifier, containment, and recovery work in `ryjen/dubnium#381`.
