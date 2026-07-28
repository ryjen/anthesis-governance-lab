# Inference-Integrity Presentation Tracks

## Developer track — 10 minutes

### Goal

Show that the evaluator is deterministic, portable, provider-neutral, independently computes outcomes from recorded evidence, and is consumed through a signed immutable release.

### Flow

1. Explain the repository boundary: Anthesis owns semantics, Governance Lab owns portable proof packaging, and Dubnium owns live runtime evidence.
2. Acquire the signed and checksum-verified public CLI.
3. Run the 24-case suite in JSON.
4. Inspect `detect-token-substitution`, `reject-cross-provider-fixed-seed-claim`, and `required-gate-fails-closed-on-verifier-outage`.
5. Generate the evidence bundle.
6. Inspect the release identity recorded in `manifest.json`.
7. Verify `SHA256SUMS`.
8. Show the controlled expectation mismatch returning exit code `7`.

### Commands

```bash
bash scripts/acquire-anthesis-lab.sh
.anthesis/bin/anthesis-lab inference-integrity --repo . --format json > /tmp/report.json
jq '{total, passed_count, failed_count}' /tmp/report.json
jq '.scenarios[] | select(.scenario_id == "detect-token-substitution")' /tmp/report.json
bash scripts/generate-inference-integrity-evidence.sh
jq '.release, .scenario_count, .report_version' .anthesis/evidence/inference-integrity/manifest.json
(cd .anthesis/evidence/inference-integrity && sha256sum --check SHA256SUMS)
```

### Message

The expected values are test assertions, not evaluator inputs. The Rust evaluator computes outcomes from synthetic evidence, reports contract drift with stable exit codes, and is bound to one reviewed signed release identity.

## Security and governance track — 15 minutes

### Goal

Demonstrate that observations, verification evidence, governance signals, policy decisions, operator approvals, and platform actions remain separate authorities.

### Flow

1. Introduce the token-selection covert-channel threat and explicit non-goals.
2. Show the five verification classes and why downgrade behavior matters.
3. Inspect runtime-selected seed rejection and verifier common-root rejection.
4. Show cumulative low-rate capacity aggregation and policy-authorized sampling escalation.
5. Compare specialist-localized tampering with synthesis tampering.
6. Show immutable re-verification plus mutation rejection.
7. Contrast a rejected cross-provider fixed-seed claim with an accepted semantic-only comparison.
8. Compare observe, selective-gate, and required-gate behavior.
9. Show that suspended-route recovery requires policy authorization and operator approval.
10. Explain that policy posture is evaluated but no containment action is executed by the fixture evaluator.

### Recommended scenarios

- `reject-runtime-selected-seed`
- `reject-untrusted-verifier`
- `aggregate-low-rate-leakage`
- `escalate-sampling-after-suspicious-evidence`
- `localize-specialist-tamper`
- `detect-synthesis-tamper`
- `reject-reverification-mutation`
- `reject-cross-provider-fixed-seed-claim`
- `required-gate-fails-closed-on-verifier-outage`
- `recover-route-after-approved-reverification`

### Message

The verifier is not a control plane. Evidence flows into Anthesis policy authority, which determines whether release, increased sampling, quarantine, route suspension, specialist isolation, forensic preservation, or recovery is authorized.

## Investor or employer track — 7 minutes

### Goal

Communicate the practical product value without overstating what a synthetic test proves.

### Flow

1. State the problem: agentic systems increasingly depend on nondeterministic inference services whose identity, routing, evidence, and assurance claims can drift.
2. Show one passing suite command and the 24/24 result.
3. Show one detected token substitution, one localized specialist failure, and one fail-closed verifier outage.
4. Show the reproducible evidence bundle, release identity, and checksums.
5. Explain the separation between Anthesis governance policy, Governance Lab proof packaging, and live Dubnium runtime integration.
6. Close with the roadmap from fixture-only evaluation to optional live Dubnium replay, verification, containment, and recovery.

### Message

Anthesis provides a deterministic governance boundary around nondeterministic AI-assisted work. Governance Lab makes the public evaluator contract demonstrable, repeatable, and inspectable without requiring proprietary infrastructure or model access.

### Avoid overclaiming

Do not claim that this suite:

- prevents every exfiltration channel;
- proves a live provider is uncompromised;
- performs real containment actions;
- validates production thresholds;
- replaces runtime isolation, monitoring, or incident response;
- proves that ungoverned traffic cannot bypass an external runtime boundary.

It demonstrates the governance contract, authority boundaries, deterministic evaluator behavior, signed consumer path, and portable evidence model.
