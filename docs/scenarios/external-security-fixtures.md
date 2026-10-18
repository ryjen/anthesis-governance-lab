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

## Independent trace integrity versus actor-controlled logs

Fixture: [`../../fixtures/external-security/trace-integrity-v1.json`](../../fixtures/external-security/trace-integrity-v1.json)

This vector models a compromised or reward-seeking agent/harness that can delete or rewrite its own local trace after a governed effect. The portable property is not that local traces are immutable; it is that the evidence used for an authoritative governed-effect claim is captured outside the actor's mutation authority.

```text
agent / harness
  -> local trace (diagnostic, mutable)
  -> independent capture (outside actor authority)
  -> effect/provenance claim
```

The fixture includes:

- a baseline with matching local and independent evidence;
- local trace deletion after the modeled effect;
- local trace rewriting that conflicts with independent evidence;
- an attempted mutation of the independent evidence sink that is blocked;
- an independent record whose effect binding does not match the expected actor/run/effect/action/decision/result tuple, which yields a mismatch;
- missing independent capture, which yields insufficient evidence;
- an alternate effect path not covered by the recorder, which also yields insufficient evidence.

Each case carries concrete actor/run, exact effect identity, action digest, decision reference, and observed-result bindings. The validator derives claim support only when the independent record exactly matches the expected tuple and the effect path is covered; the boolean claim field cannot override a missing or mismatched record. A surviving independent record can support an effect claim even when the actor-local trace is gone, while a local mismatch remains visible rather than rewriting the independent record.

The fixture deliberately does **not** claim that an external collector, kernel, host, storage backend, or arbitrary telemetry pipeline is tamper-proof. It also does not prove complete mediation: if an equivalent effect path is not covered by the independent recorder, the evidence claim remains insufficient. That limitation composes with the separate effect-path-closure fixture rather than replacing it.

## Stale remembered authority versus current effect-time authority

Fixture: [`../../fixtures/external-security/stale-memory-authority-v1.json`](../../fixtures/external-security/stale-memory-authority-v1.json)

This vector treats remembered authority as context, not permission. A remembered grant can remain well-attributed and still be stale after revocation, narrowing, expiry, supersession, or restoration of an older memory snapshot.

```text
memory says "authorized"
        |
        v
current authority at effect time
        |
        +-> valid + scope permits exact effect -> allow
        |
        +-> revoked/narrowed/expired/superseded -> deny -> no protected effect
```

The validator derives each expected decision from the current authority state and scope. The remembered claim cannot override that derivation.

The cases cover:

- a matched currently valid allow control;
- a revoked grant still remembered as authorized;
- a narrowed grant remembered with its older broader scope;
- valid source provenance with stale lifecycle state;
- restoration of a pre-revocation memory snapshot;
- an expired delegation retained in memory.

The fixture does not test memory quality, model behavior, retrieval correctness, or every production laundering path. It demonstrates only the portable governance boundary: remembered context does not become current effect authority.

## Declared, resolved, and loaded artifact identity

Fixture: [`../../fixtures/external-security/artifact-resolution-identity-v1.json`](../../fixtures/external-security/artifact-resolution-identity-v1.json)

This vector keeps three supply-chain facts distinct:

```text
declared reference
  -> resolved revision/tree
  -> actually loaded content
```

A reference that looks pinned is not sufficient if resolution produces a different revision/tree, and a correct resolution is not sufficient if different bytes are actually loaded.

The fixture includes:

- a matched declared/resolved/loaded positive control;
- a SHA-looking declared ref that resolves to a different revision/tree;
- a correct resolved artifact followed by substituted loaded bytes;
- missing and unverifiable resolution states;
- verified artifact identity with no independent action authority.

The validator derives identity correspondence from the concrete revision/tree/content values, then derives the decision separately from identity state and action authority. Artifact integrity/provenance therefore remains evidence and cannot grant invocation authority.

The fixture does not implement a Git resolver, package manager, plugin loader, signature verifier, AIBOM parser, or CycloneDX parser. It models only the portable identity and authority boundary.

## Optimization versus experimental understanding

Fixture: [`../../fixtures/external-security/experimental-understanding-v1.json`](../../fixtures/external-security/experimental-understanding-v1.json)

This vector separates two evaluation questions:

```text
Did the evaluator select the best observed configuration?
                  !=
Did the evaluator recover which component caused which effect?
```

The synthetic response surface has a baseline plus isolated component-A and component-B interventions. The validator derives component effects from the measurements and evaluates optimization success independently from effect recovery.

The cases include:

- the best configuration is selected while the claimed component effects are wrong;
- the best configuration is selected and the component effects are correct with held-out confirmation;
- the effects are correct but required held-out evidence is absent;
- two syntactically distinct configurations share one execution-equivalence class and cannot count as two independent replications;
- the component effects are correct even though the selected configuration is not the best observed one.

The underlying measurements remain separate from the derived conclusion. This allows later evaluators to reinterpret the same experiment without rewriting the original observations.

The fixture does not establish causal identification for arbitrary systems, promotion eligibility, promotion authority, or runtime/effect authority. It is a deterministic profile for the RFC-0025 distinction between optimization evidence and experimental-understanding evidence.

## Untrusted input to durable memory

Fixture: [`../../fixtures/external-security/durable-memory-write-v1.json`](../../fixtures/external-security/durable-memory-write-v1.json)

This vector models the write-path boundary identified by memory-poisoning research:

```text
external/tool/observed content
        |
        v
memory write candidate
        |
        +-> non-authoritative retrieval write, when explicitly allowed + provenance retained
        |
        +-> trusted guidance only after independent validation + promotion
```

It covers four ways a model-controlled write can arise without treating those channel names as Anthesis authority:

- explicit "remember/store" instructions from external content;
- inferred retention under a system prompt;
- compaction/summarization that selects salient or repeated content;
- experience-to-procedure / skill synthesis.

The validator derives whether a case stays candidate-only, becomes non-authoritative retrieval memory, becomes trusted guidance, or is rejected. A model's decision to remember, repetition/salience, compaction, or a producer-visible success check cannot independently upgrade trust.

Positive controls show both permitted outcomes: an approved source may enter retrieval memory while remaining non-authoritative, and exact trusted guidance may be committed after provenance, independent validation, and explicit promotion approval.

This fixture does not implement a production memory database, retrieval system, poisoning detector, or memory-policy engine. It demonstrates only the portable write/promotion boundary.

## Compositional and dormant memory poisoning

Fixture: [`../../fixtures/external-security/memory-composition-trigger-v1.json`](../../fixtures/external-security/memory-composition-trigger-v1.json)

This vector covers the use-time gap that remains after pointwise write admission:

```text
individually plausible retrieval records
        |
        +-> joint retrieval / derived context
        |      -> harmful candidate
        |
        +-> later natural trigger
               -> dormant candidate activates

candidate behavior != authority
```

The fixture keeps every contributing record as non-authoritative retrieval memory with explicit provenance. The validator derives:

- whether retrieved records form a multi-record composition;
- whether a dormant record's declared trigger is active;
- whether retrieved content conflicts with current structured state;
- whether an exact requested effect has independent current authority.

The cases include individually inert L2 fragments, harmful co-retrieval without authority, dormant/no-trigger and triggered L3 cases, benign multi-record context, a positive exact-authority control, and retrieval conflicting with current structured state.

This does not claim semantic poison detection, model behavior prediction, or live retrieval enforcement. It demonstrates the portable invariant that composition, repetition, synthesis, or trigger activation cannot upgrade retrieval memory into authority.

## Multi-parent revocation and residual grant support

Fixture: [`../../fixtures/external-security/delegation-revocation-v1.json`](../../fixtures/external-security/delegation-revocation-v1.json)  
Contract: [`delegation-revocation.md`](delegation-revocation.md)

This **synthetic, non-normative** fixture tests a disjunctive grant graph. It derives current authorization from the **joint** set of surviving grants rather than unioning individually revoked target sets. One positive control preserves an independently authorized path and another preserves an unrelated actor; a simultaneous cut of both parent grants denies shared and cross-domain descendants. Two counterfactual histories have identical present reachability but opposite outcomes after the same grant is revoked. Stale, missing, untrusted or incomplete current authority evidence makes modeled dispatch ineligible.

The graph oracle is a portable Testule #30 example consuming Anthesis #56/#203 semantics, **not** an implementation of either, and it does not test physical revocation propagation, a signed roster, cryptographic proof, or a provider effect. It does not change the accepted Anthesis v1 single-hop delegation contract. See the dedicated document for exact cases, acceptance boundaries, and known limitations.

## Proof of execution, trace completeness, replay, and fresh authority

Fixture: [`../../fixtures/external-security/proof-execution-replay-v1.json`](../../fixtures/external-security/proof-execution-replay-v1.json)  
Validator: [`../../scripts/validate-proof-execution-fixtures.sh`](../../scripts/validate-proof-execution-fixtures.sh)  
Negative oracle: [`../../scripts/test-proof-execution-oracle.sh`](../../scripts/test-proof-execution-oracle.sh)

This 19-case **synthetic, provider-neutral** pack is a bounded first execution slice of [Governance Lab #72](https://github.com/ryjen/anthesis-governance-lab/issues/72), informed by [Rhodes & Kang, *Proof of Execution*, arXiv:2607.05397v1](https://arxiv.org/abs/2607.05397v1). The paper's single-logical-Gateway, recorder and deployment assumptions are *not* established by passing this fixture.

It derives `VERIFIED`, `REJECTED`, and `UNRESOLVED` evidence states independently from modeled input observations. A claimed sealed trace is insufficient when an independent effect disagrees, the order/commit event differs, a deny led to mutation, or an unmediated effect path exists. Missing witness, path coverage or precommit recorder evidence remains **UNRESOLVED**, never silently `VERIFIED`. Replay independently rejects live-world drift and preserves an unresolved missing-dependency state, without retroactively revoking a historically valid proof.

The protected *follow-on* action requires fresh authority bound to the **same modeled principal and exact follow-on action**. Cross-action and cross-principal fresh approval attempts are denied independently of the historical proof. The historically valid record cannot authorize a new operation, and a freshly authorized but subsequently revoked context is denied. The modeled principal/action strings are **not authenticated credentials or real approval artifacts**. Mutation tests intentionally corrupt the modeled observations and assert the validator fails.

**Limitations:** The independent witness, seal, capture-path inventory, provider timing and world equivalence are declared fixture assumptions, not validated cryptographic or physical-host properties. The pack does not execute effects, establish all reachable production paths, verify external recorder durability, implement the paper's wire format, or grant authorization. It supplements (does not replace) the existing independent trace-integrity and execution-correspondence fixtures. Anthesis owns semantic authority; Dubnium owns actual runtime and recovery; Testule owns portable evidence representation. A passing synthetic oracle is **not** production compliance or complete-mediation evidence.

## Evaluator controls and placebo attribution

Fixture: [`../../fixtures/external-security/evaluator-control-task-v1.json`](../../fixtures/external-security/evaluator-control-task-v1.json)  
Validator: [`../../scripts/validate-evaluator-control-fixtures.sh`](../../scripts/validate-evaluator-control-fixtures.sh)  
Negative oracle: [`../../scripts/test-evaluator-control-oracle.sh`](../../scripts/test-evaluator-control-oracle.sh)

These nine **synthetic, no-effect** cases implement the first bounded conformance slice of [Governance Lab #62](https://github.com/ryjen/anthesis-governance-lab/issues/62), inspired by Hewitt & Liang, [*Designing and Interpreting Probes with Control Tasks*](https://arxiv.org/abs/1909.03368). The paper's use of *selectivity* is methodological evidence, not an Anthesis contract. The fixture reports discrete **raw correct count**, **matched-control correct count**, **count differential**, and **attribution** separately; the jq oracle recomputes each from explicit ten-element synthetic labels/predictions instead of trusting reported scores.

The positive treatment has ten correct raw labels but only five correct matched-control labels, giving differential five. An absent mechanism, irrelevant placebo and over-capable evaluator supply negative controls. An intentionally always-pass evaluator scores nine of ten on an imbalanced task **and the same nine of ten on its control**, so it cannot be promoted by the raw score. Missing, noncomparable or **invalid-oracle** controls produce **UNRESOLVED**, and proving only a weakened requirement produces **NOT_SUPPORTED** even if its raw score and differential are high. Eight deliberate fixture mutations must be rejected. A high treatment-control differential cannot support an attribution claim when the control oracle's correctness is unknown or explicitly invalid.

**Trust limits:** The synthetic labels are the fixture's declared reference oracle, not an attested real dataset; the control-oracle-valid field is a modeled precondition, not a verified credential or certification; the activity/mechanism and requirement-coverage flags are modeled assumptions. Matching condition identifiers alone do not establish actual experimental matching. A raw/control count is not a statistical causal estimate, verifier attestation, policy decision, agent capability grant, or deployment qualification. The derived `SUPPORTED` label is evidence only under this declared toy experiment; no consumer may treat it as Anthesis authorization. Extended grader-collapse and contract-aware auditor controls remain tracked on #62 and should be added only without broadening this first slice.

## Verifier collapse and task-contract-aware auditor controls

Fixture: [`../../fixtures/external-security/verifier-collapse-controls-v1.json`](../../fixtures/external-security/verifier-collapse-controls-v1.json)  
Validator: [`../../scripts/validate-verifier-collapse-controls.sh`](../../scripts/validate-verifier-collapse-controls.sh)  
Negative oracle: [`../../scripts/test-verifier-collapse-controls.sh`](../../scripts/test-verifier-collapse-controls.sh)

This nine-case **synthetic, no-effect** extension of [#62](https://github.com/ryjen/anthesis-governance-lab/issues/62) models the verifier-collapse and contract-blind auditor failure modes described in [*Who Verifies the Verifier?* (arXiv:2610.11464v1)](https://arxiv.org/abs/2610.11464). Paper outcomes are author-reported and are **not** independently reproduced here.

The locked oracle includes known-good, known-bad, and abstain labels. An anchored candidate matches each; an always-pass candidate incorrectly accepts bad and abstain examples. The fixture's plausible downstream agent score of 0.94 cannot override these invalid verifier results. The oracle is declared unavailable as grader-selection feedback, although this is a synthetic assumption rather than an enforceable information-flow guarantee.

A generic auditor incorrectly rejects a report containing the task-contract-required `EVIDENCE:42` tag; a contract-aware auditor accepts that report but rejects `EVIDENCE:` without a numeric value. A generic auditor that correctly rejects the malformed tag is also marked **VALID**: validity is derived from the observed verdict against the same contract oracle, not from the candidate's name. Each case binds a synthetic subject, evaluator profile, harness, candidate, and task-contract revision. The verdict and validity are separately checked. Distinct evaluator/contract revisions must be recorded as distinct evidence identities in any real integration; this pack does not implement an identity signer, new schema or retroactive reinterpretation.

These tests are *evidence checks*, not authorization or promotion decisions. They neither run models nor demonstrate real evaluator independence, model-training dynamics, statistical validity, or a trustworthy external grader.

## Root-scoped revocation and late-effect quiescence

Fixture: [`../../fixtures/external-security/root-revocation-quiescence-v1.json`](../../fixtures/external-security/root-revocation-quiescence-v1.json)  
Validator: [`../../scripts/validate-root-revocation-quiescence.sh`](../../scripts/validate-root-revocation-quiescence.sh)  
Negative oracle: [`../../scripts/test-root-revocation-quiescence.sh`](../../scripts/test-root-revocation-quiescence.sh)

This twelve-case, **synthetic, provider-neutral, no-effect** pack implements the bounded fixture scope of [#70](https://github.com/ryjen/anthesis-governance-lab/issues/70), based on [Zhu & Wang, *Authorization Revocation for Long-Running AI Agents*, arXiv:2609.21284v1](https://arxiv.org/abs/2609.21284v1). It tests cancellation acknowledgment, process/token revocation, durable cut without provider fence, cut plus fence, late settlement of pre-fence accepted commitments, stale restarted worker, exact shared-worker rebind, missing provider coverage, duplicated handoff, conflicting certificate, retry exhaustion and preservation of independent roots.

Verdicts are derived from explicit modeled coverage, fence, cut, live-support and commitment facts as `QUIESCENT`, `NOT_QUIESCENT` or `INDETERMINATE`. A historical accepted commitment settling after the cut is not counted as a *new* protected commitment. A known new retired-root commitment or live retired-root support defeats quiescence; missing enumeration, fence, frontier, handoff, certificate or completed retry evidence remains indeterminate. The model does not assert global idleness, rollback or business completion.

**Evidence boundary:** All provider coverage, ordering, epoch and certificate facts are declared **fixture assumptions**, not authenticated proofs. This is neither a complete implementation of the paper nor a deployed revocation protocol. Anthesis owns revocation semantics; Dubnium owns runtime cuts/fences/recovery; Testule owns portable evidence. The lab only owns deterministic negative cases. The fixture also models origin-root and delegation epoch, support source, cut/fence/frontier sequence ordering, stable handoff and retry effect identities, and terminal disposition. These are checked for structural consistency with 29 negative mutations, but are not authenticated provider evidence, proof of manifest completeness, or physical-host revocation assurance.

## Cross-control composition (synthetic)

Fixture: [`../../fixtures/external-security/cross-control-composition-v1.json`](../../fixtures/external-security/cross-control-composition-v1.json)  
Validator: [`../../scripts/validate-cross-control-composition.sh`](../../scripts/validate-cross-control-composition.sh)  
Negative oracle: [`../../scripts/test-cross-control-composition.sh`](../../scripts/test-cross-control-composition.sh)

Six deterministic, provider-neutral, no-effect scenarios for issue #77 cover positive composition, provenance drop, delegation loss, delayed stale-state reuse, detection without containment, and quarantined recovery with independent-root continuation. Two locally passing control assertions do not establish end-to-end composition when an identity is lost between stages. Mandatory security failures cannot be offset by utility, latency or cost.

The fixture draws on Ling et al., *Toward Secure LLM Agents* (arXiv:2606.10749v2), a survey synthesizing research rather than proving a universal security stack. Source, policy, memory, delegation, effect and recovery fields are synthetic assertions. A modeled terminal-effect ledger and open-contamination identifiers are cross-checked against effect/containment flags; the modeled security-gate flag is checked for consistency with the synthetic verdict; utility, latency and cost descriptions cannot override that verdict. The modeled `modeled_security_gate_pass` value is a consistency assertion checked against the same synthetic invariants that produce the verdict, **not independent evidence** or a second enforcement gate. The fixture requires exactly one committed ledger entry when its committed flag is true and exactly one open contamination identifier when its live-path flag is true; both must be empty when their respective flags are false. This is consistency of declared entries, not independent completeness evidence. Ledger membership and contamination closure are limited to explicitly enumerated fixture entries: an omitted effect, omitted contaminated path, or forged assumption cannot be discovered by this validator. The tests can therefore pass vacuously relative to unmodeled activity. The checks do not establish real containment, physical effect mediation, provider evidence, production security or universal composability.

## Validation

Run:

```bash
bash scripts/validate-external-security-fixtures.sh
bash scripts/validate-delegation-revocation-fixture.sh
bash scripts/validate-proof-execution-fixtures.sh
bash scripts/test-proof-execution-oracle.sh
bash scripts/validate-evaluator-control-fixtures.sh
bash scripts/test-evaluator-control-oracle.sh
bash scripts/validate-verifier-collapse-controls.sh
bash scripts/test-verifier-collapse-controls.sh
bash scripts/validate-root-revocation-quiescence.sh
bash scripts/test-root-revocation-quiescence.sh
bash scripts/validate-effect-path-closure-fixture.sh
bash scripts/validate-cross-control-composition.sh
bash scripts/test-cross-control-composition.sh
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