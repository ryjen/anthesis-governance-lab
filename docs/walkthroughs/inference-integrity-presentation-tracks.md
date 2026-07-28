# Inference-Integrity Presentation Tracks

## Developer track — 10 minutes

### Goal

Show that the evaluator is deterministic, portable, provider-neutral, and independently computes outcomes from recorded evidence.

### Flow

1. Explain the repository boundary: Anthesis owns semantics, Governance Lab owns fixtures and packaging, Dubnium owns live runtime evidence.
2. Acquire the checksum-verified public CLI.
3. Run the 16-case suite in JSON.
4. Inspect `detect-token-substitution` and `block-fallback-to-unverifiable-route`.
5. Generate the evidence bundle.
6. Verify `SHA256SUMS`.
7. Show the controlled expectation mismatch returning exit code `7`.

### Commands

```bash
bash scripts/acquire-anthesis-lab.sh
.anthesis/bin/anthesis-lab inference-integrity --repo . --format json > /tmp/report.json
jq '.scenarios[] | select(.scenario_id == "detect-token-substitution")' /tmp/report.json
bash scripts/generate-inference-integrity-evidence.sh
(cd .anthesis/evidence/inference-integrity && sha256sum --check SHA256SUMS)
```

### Message

The expected values are test assertions, not evaluator inputs. The Rust evaluator computes outcomes from synthetic evidence and reports contract drift with a stable non-zero exit code.

## Security and governance track — 15 minutes

### Goal

Demonstrate that observations, governance signals, policy decisions, and platform actions remain separate authorities.

### Flow

1. Introduce the token-selection covert-channel threat and explicit non-goals.
2. Show the five verification classes and why downgrade behavior matters.
3. Inspect runtime-selected seed rejection and verifier common-root rejection.
4. Show cumulative low-rate capacity aggregation.
5. Compare specialist-localized tampering with synthesis tampering.
6. Show immutable re-verification linkage.
7. Explain that policy posture is evaluated but no containment action is executed by the fixture evaluator.

### Recommended scenarios

- `reject-runtime-selected-seed`
- `reject-untrusted-verifier`
- `aggregate-low-rate-leakage`
- `localize-specialist-tamper`
- `detect-synthesis-tamper`
- `preserve-original-on-reverification`

### Message

The verifier is not a control plane. Evidence flows into Anthesis policy authority, which determines whether release, increased sampling, quarantine, route suspension, specialist isolation, or forensic preservation is appropriate.

## Investor or employer track — 7 minutes

### Goal

Communicate the practical product value without overstating what a synthetic test proves.

### Flow

1. State the problem: agentic systems increasingly depend on nondeterministic inference services whose identity, routing, and evidence can drift.
2. Show one passing suite command and the 16/16 result.
3. Show one detected token substitution and one localized specialist failure.
4. Show the reproducible evidence bundle and checksums.
5. Explain the separation between governance policy, portable test fixtures, and live runtime integration.
6. Close with the roadmap from fixture-only evaluation to optional live Dubnium replay.

### Message

Anthesis provides a deterministic governance layer around nondeterministic AI-assisted work. The Governance Lab makes those controls demonstrable, repeatable, and inspectable without requiring proprietary infrastructure or model access.

### Avoid overclaiming

Do not claim that this suite:

- prevents every exfiltration channel;
- proves a live provider is uncompromised;
- performs real containment actions;
- validates production thresholds;
- replaces runtime isolation, monitoring, or incident response.

It demonstrates the governance contract, authority boundaries, deterministic evaluator behavior, and portable evidence model.
