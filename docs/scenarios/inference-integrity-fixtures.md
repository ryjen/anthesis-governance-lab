# Inference-Integrity Fixtures and Executable Contract

This repository contains two related but intentionally distinct inference-integrity surfaces.

Canonical semantics remain owned by `hackelia-micrantha/anthesis#108`. Gateway identity and runtime metadata remain owned by `ryjen/dubnium#379`; live replay and verifier integration remain owned by `ryjen/dubnium#381`.

## Executable 24-case contract

The signed public `anthesis-lab` release evaluates the provider-neutral fixture contract:

```text
fixtures/inference-integrity/scenario-suite-v1alpha1.yaml
fixtures/inference-integrity/fixtures-v1alpha1.json
```

The executable suite contains 24 canonical synthetic cases and emits:

```text
anthesis.inference-integrity-report/v1alpha1
```

It runs without a GPU, live model, provider credential, or Dubnium service. The evaluator computes verdicts, verification capability classes, and normalized policy postures from recorded evidence. Expected outcomes are assertions rather than evaluator inputs.

Run it with:

```bash
bash scripts/acquire-anthesis-lab.sh
bash scripts/validate-executable-inference-integrity.sh
```

The validation requires:

- 24 passing scenarios and zero failures;
- deterministic byte-identical JSON reports;
- a passing YAML report;
- controlled expectation drift returning exit code `7` with exactly one failed scenario;
- repository-contained execution;
- signed release verification before checksum, provenance, extraction, or execution.

## Rich demonstration records

The individual JSON records and `fixtures/inference-integrity/manifest.json` predate the canonical compact evaluator contract. They preserve richer examples for presentation and future live-runtime integration, including detailed execution identity, verifier attribution, policy authority, topology, risk-window, and recovery fields.

These richer records remain **synthetic and provisional as live integration records**. They are structurally validated but are not individually parsed by the current Rust evaluator.

This separation avoids two failure modes:

1. reimplementing Anthesis evaluator semantics in Governance Lab;
2. claiming that a fixture-only evaluator proves live provider evidence, replay, containment, or non-bypassability.

## Record boundaries

The rich records separate:

1. **Original execution evidence** — requested alias, exact resolved provider/route/model/tokenizer/runtime identity, sampling commitment, output digest, and topology.
2. **Verifier evidence** — attributable observations and a non-authoritative verdict.
3. **Policy result** — the authoritative governance outcome and any containment authorization.
4. **Re-verification linkage** — a linked append-only record that must not mutate original evidence.

The verifier is explicitly non-authoritative. It cannot release, quarantine, suspend, isolate, increase sampling, recover a route, or enter dormancy without policy-plane mediation.

## Structural validation

```bash
bash scripts/validate-inference-integrity-fixtures.sh
bash scripts/validate-inference-capacity-fixtures.sh
bash scripts/validate-inference-final-catalog.sh
bash scripts/validate-inference-scenario-catalog.sh
```

Structural validation requires:

- synthetic-only records;
- no real prompts or secrets;
- requested alias distinct from resolved execution identity;
- gateway-owned seed evidence where a fixed-seed claim is represented;
- explicit verification class and operating mode;
- original execution linkage across verifier and policy records;
- verifier non-authority;
- normalized policy outcomes coordinated with Anthesis #108;
- exact parity between the executable catalog, canonical suite, and canonical compact fixture keys.

## Live integration gate

The fixture-only contract is executable now. A live profile still requires reviewed Dubnium runtime support for:

- exact resolved execution identity and lineage;
- gateway-owned seed and sampling evidence;
- protected replay material;
- independently controlled verifier execution;
- policy-mediated containment and recovery;
- proof that governed traffic cannot reach raw runtime paths.

Until those surfaces exist, the suite must be presented as deterministic evaluation of recorded provider-neutral evidence, not complete live inference protection.
