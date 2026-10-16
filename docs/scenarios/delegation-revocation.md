# Deterministic delegation-revocation fixture (synthetic, non-normative)

Fixture: [`delegation-revocation-v1.json`](../../fixtures/external-security/delegation-revocation-v1.json)  
Validator: [`validate-delegation-revocation-fixture.sh`](../../scripts/validate-delegation-revocation-fixture.sh)

```bash
bash scripts/validate-delegation-revocation-fixture.sh
bash scripts/test-delegation-revocation-oracle.sh
```

This is a portable **test specification**, not a new Anthesis policy or Testule adapter. The shell/`jq` validator independently computes modeled decisions from the declared grant edges, the **joint** revoked-grant set, proof state, and current epoch, then compares them with the expected verdicts. It binds each named case to the required world, cut, actor, proof state, epoch, and verdict **and pins every synthetic grant ID to its expected source and destination in that world**. A swapped `A→C` / `B→C` grant ID or a rerouted parallel grant must fail even when graph reachability and every expected decision are unchanged. The complete edge set is checked exactly, rejecting undeclared grants. Eleven mutation regressions exercise the case labels, all bound cached claims, and grant provenance. A model's `cached_claim` never determines authority. No protected effects are executed.

## Disjunctive multi-parent cut

The root independently grants authority to `A` and `B`; each grants to `C`, which supports descendants `D` and cross-domain `E`. An unrelated `F` has direct root support.

| Revocation | C | D/E | F | Why |
|---|---|---|---|---|
| `A→C` alone | allow | allow | allow | Independent B path remains |
| `B→C` alone | allow | allow | allow | Independent A path remains |
| Both edges, **one batch** | deny | deny | allow | No surviving path to C or descendants; F unaffected |

A separate **cached-denial positive control** demonstrates that an outdated model-supplied `deny` cannot override independently verified current authority, just as a cached `allow` cannot authorize a revoked effect.

The invalid shortcut—unioning two separately computed single-edge revoke target sets—fails for this graph. Each individual cut leaves C reachable, while the **joint** cut removes both supports.

A second counterfactual pair gives `root→A→C` two histories with **identical current all-pairs reachability**: one has a single `A→C` grant, the other also has an independently sufficient parallel grant. Revoking the common primary grant must deny in the first world and allow in the second. This distinguishes authorization-support provenance from a snapshot of present reachability.

## Freshness and missing evidence

The cases include a cached prior `allow` at `epoch-1` after a cut at `epoch-2`, an incomplete surviving-edge inventory, an untrusted proof, and an unavailable current authority source. Each is **indeterminate and not dispatch-eligible**, even if the fixture's local omniscient graph could compute a hypothetical correct authorization outcome. Positive controls ensure independently supported actors remain eligible when current authority is verified.

## Ownership and scope

| Aspect | Owner |
|---|---|
| Meaning of grants/delegation, support sets, current effect-time authorization | Anthesis #56 / #203 |
| Portable scenario requirements, independent oracle, expected vs observed Evidence and gap outcomes | Testule #30 / RFC-0001 / RFC-0002 |
| Reproducible synthetic graph fixture | Anthesis Governance Lab |
| Actual worker fencing, propagated cancellation, provider-side effect/denial observation | Dubnium and its governed capability provider — **not tested** |

This is a non-normative experimental profile for **disjunctive** delegation. Anthesis's accepted v1 **single-hop** behavior remains unchanged; the fixture does not assert it currently supports multi-parent or transitive delegation. Neither a passing `jq` test nor the fixture's expected no-dispatch label proves production complete mediation, signature authenticity, signed-roster completeness, absence of unobserved effects, or execution of a protected operation. Conjunctive, k-of-n, and time-dependent policies need separate semantics. A later integration must independently observe real provider behavior before claiming effect-time enforcement.

The fixture's provenance and negative-oracle questions follow [ResidualAuth](https://arxiv.org/abs/2609.08062v2) and [VERA](https://arxiv.org/abs/2608.30091). It **does not reproduce their research experiments**.
