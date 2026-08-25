# External Agent-Security Test Vectors

These fixtures are provider-neutral, synthetic conformance vectors derived from the gaps recorded in [`external-security-crosswalk.md`](external-security-crosswalk.md).

They are intentionally **not** new Anthesis policy rules and are not evaluated by the current `anthesis-lab` declaration contract. Their purpose is to make cross-system security boundaries reproducible in a small data format that can be discussed or adapted upstream without depending on Anthesis.

## Evidence state versus action authority

Fixture: [`../../fixtures/external-security/evidence-authority-v1.json`](../../fixtures/external-security/evidence-authority-v1.json)

The fixture defines a policy that requires both:

1. current verified artifact evidence; and
2. independent action authorization.

The central pair is:

```text
verified evidence + authorized action   -> allow
verified evidence + unauthorized action -> deny
```

This prevents a valid signature, SBOM, AIBOM, model identity, or attestation from being interpreted as a runtime permission.

The same fixture distinguishes:

- `verified`
- `missing`
- `stale`
- `mismatch`
- `contradictory`
- `unverifiable`

For this synthetic policy, current verified evidence is a required precondition, so every non-verified state denies. That is a property of the declared fixture policy, not a universal requirement that every deployment must use the same response. The important portable property is that the evidence state remains explicit and is not silently converted into authority.

## Manifest version versus action-time authority

Fixture: [`../../fixtures/external-security/manifest-action-binding-v1.json`](../../fixtures/external-security/manifest-action-binding-v1.json)

The fixture separates four properties:

```text
admitted deployment state
  -> exact action-time decision
  -> dispatch eligibility
  -> later execution/effect evidence
```

A valid manifest is necessary only where policy says it is necessary; it is never sufficient to authorize the exact action in this vector.

The fixture includes:

- an exact action decision bound to manifest `M1` that is allowed;
- drift to manifest `M2` before dispatch, causing the `M1`-bound decision to fail;
- changed normalized action arguments;
- changed actor context;
- expired decision;
- revoked decision;
- valid manifest with no action-time decision;
- fresh `M2` decision after drift.

The vector is intentionally structural. It does not claim that the selected tool/action is semantically correct for the user's goal, that the issuing policy is correct, or that all bypass paths are closed.

## Environmental influence versus action authority

Fixture: [`../../fixtures/external-security/environmental-influence-v1.json`](../../fixtures/external-security/environmental-influence-v1.json)

This fixture models attacker-writable environment state that reaches an agent through an ordinary read path. The source and observation can both be validly attributed without granting the observed content instruction authority.

The central pair is:

```text
hostile content present -> protected effect requested -> deny -> protected target unchanged
hostile content present -> benign authorized effect     -> allow -> benign artifact present
```

The hostile input remains present in both cases. This prevents the fixture from succeeding merely by deleting or filtering the input and demonstrates that useful progress can coexist with an independently denied hostile request.

The modeled evidence chain is:

```text
source domain/state
  -> acquisition/read
  -> observation
  -> exact requested effect
  -> policy decision
  -> execution or no-execution evidence
  -> deterministic terminal state
```

Source provenance and observation evidence remain distinct from authorization. The fixture does not require a live model, credentials, network, or external service and does not claim generic prompt-injection detection, exhaustive complete mediation, or production containment.

## Validation

Run:

```bash
bash scripts/validate-external-security-fixtures.sh
```

The validator checks the fixture contracts and the critical paired invariants. It does not call a model, network, credential provider, policy service, signer, or external runtime.

## Upstream use

The fixtures are designed to be adaptable to:

- CoSAI MCP Security #26 for evidence-state and authority separation;
- CoSAI Agent Manifest #149 for manifest-version/action-time binding;
- OWASP Agentic ASI02/ASI03/ASI04 cases where identity, tool authority, and supply-chain evidence must remain separate;
- OWASP Agentic tool-misuse and memory/context-poisoning examples where attacker-controlled observations must remain non-authoritative;
- research/tooling that evaluates indirect environmental influence through deterministic state and terminal-effect assertions.

Before proposing them upstream, translate field names into the target project's vocabulary and retain the `does_not_prove` limitations rather than presenting synthetic structural validation as production assurance.
