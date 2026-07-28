# Inference-Integrity Governance Lab Runbook

## Purpose

This runbook demonstrates how Anthesis evaluates synthetic inference evidence for seed integrity, token substitution, route and fallback governance, verifier trust, covert-channel capacity, supervisor/specialist localization, and immutable re-verification.

The default demonstration is provider-neutral and does not require a GPU, network access, a live model, or Dubnium services.

## Responsibility boundary

| Component | Responsibility |
| --- | --- |
| Anthesis | Verification classes, evaluator semantics, verdicts, policy postures, reports, and exit codes |
| Governance Lab | Portable fixtures, execution packaging, reproducible evidence bundles, and presentation guidance |
| Dubnium | Live gateway metadata, seed and sampling evidence, replay production, verifier execution, and platform actions |

Verifier output is evidence. It does not directly authorize release, quarantine, suspension, isolation, or recovery.

## Prerequisites

- Linux x86_64
- `bash`
- `jq`
- `sha256sum`
- network access only when initially acquiring the published CLI

Acquire the checksum-verified public CLI:

```bash
bash scripts/acquire-anthesis-lab.sh
```

## Quick start

Run the complete canonical 16-case suite:

```bash
.anthesis/bin/anthesis-lab inference-integrity \
  --repo . \
  --format json | jq .
```

Expected result:

- report version: `anthesis.inference-integrity-report/v1alpha1`
- total scenarios: `16`
- passed scenarios: `16`
- exit code: `0`

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

A weaker class must never be presented as deterministic token equivalence.

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

### Capacity accounting

Inspect:

- `budget-low-capacity-discrepancy`
- `quarantine-dangerous-token`
- `aggregate-low-rate-leakage`

Key point: individually small discrepancies may remain below a per-execution threshold while cumulative correlated observations exceed the governed window.

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
- `downgrade-unsupported-replay`

Key point: re-verification appends a linked result without rewriting original evidence, and unsupported replay explicitly downgrades the verification claim.

## Controlled failure demonstration

The evidence generator creates a temporary copy of the suite and changes one expected policy posture. The evaluator must return exit code `7` and produce a report with exactly one failed scenario.

This demonstrates that expected outcomes are not trusted as computed outcomes.

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

The released v1alpha1 evaluator executes 16 canonical scenarios. The broader Governance Lab catalog contains 24 provisional records. Observe/selective/required gate transitions, semantic-only cross-provider acceptance, explicit recovery authorization, and several extended aggregation cases remain pending a canonical Anthesis evaluator extension.

The optional live Dubnium profile remains pending stabilization of runtime evidence and replay support in `ryjen/dubnium#381`.
