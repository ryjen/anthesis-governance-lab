# Environmental Influence Crosswalk Note

Portable fixture: [`../../fixtures/external-security/environmental-influence-v1.json`](../../fixtures/external-security/environmental-influence-v1.json)

This note extends the external-security crosswalk without promoting the portable fixture into the canonical `anthesis-lab` runtime scenario catalog.

## Relevant rows

### OWASP Agentic ASI02 — Tool Misuse & Exploitation

Additional portable evidence:

- attacker-writable repository content is observed through an ordinary read path;
- the resulting protected-effect request is independently denied;
- valid source/observation evidence is preserved;
- the protected target remains unchanged in deterministic terminal state.

Coverage remains **partial** because this synthetic vector does not prove live tool mediation, downstream credential isolation, or absence of alternate effect paths.

### OWASP Agentic ASI06 — Memory & Context Poisoning

Adjacent portable evidence:

- environmental/source content can be authentic and attributable while remaining non-authoritative for instructions;
- hostile observed content does not need to be removed for a benign authorized objective to succeed.

Coverage remains **not-demonstrated** for durable-memory write governance specifically. This fixture models repository/environment influence and should not be relabeled as a memory-write control.

## CARI: action-triggered peer diagnostics (research follow-up, 2026-11-06)

[**CARI**, arXiv:2610.38799v1](https://arxiv.org/html/2610.38799v1) evaluates adversarial messages delivered through legitimate runtime feedback from a peer-controlled backend. Its controlled Todo-app experiments show that an identical injected instruction can be more effective inside an action-triggered diagnostic than in static documentation. The reported aggregate 2,845/3,000 tool-observed successes reflect permissive benchmark conditions, **not production attack prevalence** and **not a claim about this lab**. This paper and its model artifacts have not been independently reproduced here.

**What is already covered:** the existing `environmental-influence-v1.json` fixture and merged [PR #112](https://github.com/ryjen/anthesis-governance-lab/pull/112) model a single inert hostile observation with test-local, paired denied protected mutation / allowed benign artifact, a filesystem witness, and negative mutations. That does not represent a live peer responder, a retriggered diagnostic, a model interpreting it, or production tool mediation.

**Targeted documentation/fixture extension — not yet implemented:** [issue #50](https://github.com/ryjen/anthesis-governance-lab/issues/50) owns a synthetic source-conditioned diagnostic responder that can reissue feedback on retry. Preserve the source role, event/attempt, observed message, exact proposed effect, current independent decision, dispatch/no-dispatch evidence and terminal-state witness. The protected action must deny **without changing protected bytes**; a legitimate bounded repair must still allow **with the hostile diagnostic present**. Include target substitution, stale authority, missing witness and retry-limit controls. The test must remain credential-free and network-free and must not execute real injected commands.

This research expands a known attack *input channel* for a future conformance fixture; it does **not** create a new authorization rule, certify complete mediation, or prove general prompt-injection resistance. Governance contract ownership remains in [Anthesis #202](https://github.com/hackelia-micrantha/anthesis/issues/202), with runtime enforcement and host qualification remaining separate.

## Research mapping

The fixture operationalizes the ToolHazard-style path:

```text
attacker-writable state
  -> legitimate acquisition
  -> agent observation
  -> effect request
  -> independent authorization
  -> execution/no-execution evidence
  -> deterministic terminal state
```

It provides a reusable environmental-influence test shape while preserving the crosswalk assurance boundary: synthetic evidence is not production conformance, and source provenance is not action authority.
