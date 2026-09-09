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

## Authorization versus execution correspondence

Fixture: [`../../fixtures/external-security/execution-correspondence-v1.json`](../../fixtures/external-security/execution-correspondence-v1.json)

This fixture starts after an exact action has already been authorized and admitted. It asks a different question: did the downstream effector actually perform the same policy-relevant action?

The central pair is:

```text
authorized A -> dispatched A -> provider reports B -> A != B -> correspondence fail
authorized A -> dispatched A -> provider reports A -> A == A -> correspondence pass
```

The mismatch case changes only the protected target. Authorization for `action_a` remains valid and immutable; execution evidence truthfully records `action_b`. The checker therefore fails correspondence rather than rewriting the authorization record or treating `B` as retroactively authorized.

The validator derives policy-relevant differences directly from the authorized and executed action objects and requires the result to match each case's declared `mismatch_fields`. The fixture therefore cannot pass merely by asserting that a target mismatch exists when the underlying action fields do not support that claim.

The modeled evidence chain keeps four facts separate:

```text
authorization evidence
  -> dispatch evidence
  -> provider execution evidence
  -> deterministic terminal-state evidence
```

The fixture compares policy-relevant fields including tool, operation, target, arguments, and actor context. Its positive control proves the checker does not simply mark every execution as mismatched or unverifiable.

The `digest` values in this fixture are opaque stable identifiers with SHA-256-shaped syntax. They are not claimed to be cryptographic hashes of canonicalized action content. Any future content-binding digest contract would need to define canonicalization and compute the digest rather than relying on these fixture identifiers.

This is structural evidence only. It does not establish production complete mediation, receipt authenticity, absence of unobserved side effects, universal provider semantics, exhaustive TOCTOU resistance, or policy correctness.

## Complete mediation and effect-path closure

Fixture: [`../../fixtures/external-security/effect-path-closure-v1.json`](../../fixtures/external-security/effect-path-closure-v1.json)

This vector makes the complete-mediation claim narrower and testable: protecting the normal tool or adapter path is insufficient if a semantically equivalent effect can still be reached through another path.

```text
                         authorization
                              |
                              v
runtime -> governed adapter -> unavoidable boundary -> executor -> effect
   |                                                    ^
   +-> raw API ------------------------ blocked ---------+
   +-> alternate registry ------------- blocked --------+
   +-> direct credential -------------- blocked --------+
```

The positive case allows one exact effect through the mediated path. The three bypass paths model the same external effect but must remain structurally unreachable and produce zero externally observable effects.

The fixture also covers:

- target mutation after authorization;
- policy-relevant argument mutation;
- replay of a consumed single-use authorization;
- expired authorization;
- authorization bound to a different executor identity;
- loss of the required enforcement boundary;
- a control signal being observed while an equivalent raw bypass path is still attempted.

That last case deliberately distinguishes **observation** from **enforcement**. A hook, audit record, policy decision, or other control-plane signal can show that a governed interaction was observed. It does not by itself prove that all equivalent effect paths were mediated.

Every case with `expected_verdict: block` is valid only when `effect_count` remains `0`. This prevents a fixture from declaring success because a denial record exists after the external effect already happened.

### Optional ACS mapping

The base vector is protocol-neutral. For Agent Control Standard (ACS) experiments, the same fields can be projected without changing authority ownership:

| Provider-neutral fixture | ACS projection |
| --- | --- |
| `control_signal_observed` | observation of `steps/toolCallRequest` or equivalent lifecycle traffic |
| authorization/effect binding | Guardian decision plus exact policy-relevant request binding |
| `allow` / `block` | ALLOW / DENY, with ASK represented by a separate approval flow when needed |
| path/component inventory | AgBOM/tool inventory evidence where available |
| boundary/executor/effect observations | Trace or external evidence projection |

The mapping is intentionally one-way. ACS vocabulary can describe the interaction, but an ACS hook or Guardian response does not become proof of complete mediation. Stronger assurance still depends on an unavoidable enforcement boundary or structural unreachability of equivalent bypass paths.

For the ACS #16 discussion, the corresponding simple explanation is: **putting a guard on one of four doors does not secure the room; either every door must pass the guard or the other doors must be locked.**

The fixture remains synthetic. It does not prove production network isolation, credential unreachability, absence of unknown bypass paths, cryptographic token authenticity, or ACS conformance/certification. A concrete runtime composition belongs in a bounded runtime integration rather than in this provider-neutral vector.

## Validation

Run:

```bash
bash scripts/validate-external-security-fixtures.sh
bash scripts/validate-effect-path-closure-fixture.sh
```

The validators check the fixture contracts and the critical paired invariants. They do not call a model, network, credential provider, policy service, signer, or external runtime.

## Upstream use

The fixtures are designed to be adaptable to:

- CoSAI MCP Security #26 for evidence-state and authority separation;
- CoSAI Agent Manifest #149 for manifest-version/action-time binding;
- Agent Control Standard #16 for effect-path closure, observed-versus-enforced coverage, and zero-effect bypass vectors;
- OWASP Agentic ASI02/ASI03/ASI04 cases where identity, tool authority, and supply-chain evidence must remain separate;
- OWASP Agentic tool-misuse and memory/context-poisoning examples where attacker-controlled observations must remain non-authoritative;
- conformance work that distinguishes a correctly authorized request from the effect actually reported or observed downstream;
- research/tooling that evaluates indirect environmental influence through deterministic state and terminal-effect assertions.

Before proposing them upstream, translate field names into the target project's vocabulary and retain the `does_not_prove` limitations rather than presenting synthetic structural validation as production assurance.
