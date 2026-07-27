# Inference-Integrity Fixture Skeleton

This directory contains **provisional, synthetic fixture records** for the inference-integrity work tracked by `ryjen/anthesis-governance-lab#13`.

Canonical semantics remain owned by `hackelia-micrantha/anthesis#108`. Gateway identity and runtime metadata remain owned by `ryjen/dubnium#379`; live replay and verifier integration remain owned by `ryjen/dubnium#381`.

## Why these fixtures are separate

The released `anthesis-lab` scenario contract does not yet include the inference-integrity evidence and policy fields described by Anthesis #108. These files therefore remain under `fixtures/inference-integrity/` rather than `.anthesis/scenarios/` or `.anthesis/demos/`.

They are structural examples only. They are not executable scenarios, canonical schemas, a policy engine, a verifier, or evidence of live inference protection.

## Record boundaries

Each record separates:

1. **Original execution evidence** — requested alias, exact resolved provider/route/model/tokenizer/runtime identity, sampling commitment, output digest, and topology.
2. **Verifier evidence** — attributable observations and a non-authoritative verdict.
3. **Policy result** — the authoritative governance outcome and any containment authorization.
4. **Re-verification linkage** — a future linked record that must not mutate the original evidence.

The verifier is explicitly marked non-authoritative. It cannot release, quarantine, suspend, isolate, or enter dormancy without policy-plane mediation.

## Validation

```bash
bash scripts/validate-inference-integrity-fixtures.sh
```

Validation requires:

- synthetic-only records;
- no real prompts or secrets;
- requested alias distinct from resolved execution identity;
- gateway-owned seed evidence;
- explicit verification class and operating mode;
- original execution linkage across verifier and policy records;
- verifier non-authority;
- normalized policy outcomes from Anthesis #108.

## Promotion gate

These fixtures may move into executable Governance Lab scenarios only after all of the following exist in a reviewed public release:

- canonical Anthesis schema or accepted evidence semantics;
- provider-neutral evaluator support;
- a released `anthesis-lab` contract capable of parsing and evaluating the records;
- stable Dubnium resolved-execution fields for any live profile.

Until then, the `v0` identifiers are intentionally provisional and must not be presented as canonical Anthesis contracts.
