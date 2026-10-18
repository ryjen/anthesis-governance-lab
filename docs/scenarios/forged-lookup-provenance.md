# Forged historical lookup provenance (#87)

Five deterministic, network-free, synthetic no-effect cases model legitimate host-owned lookup/response/authorization/effect lineage, a forged historical claim in untrusted content, cross-call response substitution, missing host response, and a benign control.

The validator derives evidence state and admission from independently represented host call, response and authorization records. It separately derives the observed effect from the synthetic effect record. It does not infer any authority from the attacker-controlled text or the monitor flag. The mutation oracle rejects incorrect joins and expectations while accepting a payload-only change that leaves host observations intact.

**Evidence states:** `verified`, `mismatch`, and `insufficient`. The fixture's expected `allow` decision is a simulated admission, not actual execution; `observed_effect` is a synthetic declared terminal observation, not a proof of physical-world effect or prevention. Missing host evidence produces insufficient/deny/no observed effect. An alarm alone is not prevention.

This extends the external-security fixtures and does not replace `trace-integrity-v1.json` (local log alteration) or `effect-path-closure-v1.json` (alternate effect path reachability). The canonical seven-case policy suite is unchanged.

Research motivation: [Kekatos et al., Formal Runtime Verification for Tool-Using LLM Agents](https://arxiv.org/abs/2610.09793). Its offline detection and planted-line findings do not establish live runtime mediation here.

**Nonclaims:** No real host provenance, timestamps, cryptographic attestation, authorization freshness, live tools, model calls, network, credentials, external writes, telemetry store, policy engine, or production containment is tested.
