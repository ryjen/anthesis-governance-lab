# Governance Lab Scenario Catalog

The human-readable catalog is paired with the validated machine-readable manifest at [`docs/scenarios/catalog.json`](catalog.json).

Governance Lab intentionally exposes three separate proof surfaces. Keep the counts and purposes distinct:

| Surface | Path / command | Count | Purpose |
|---|---|---:|---|
| Canonical governance contract | `.anthesis/scenarios` / `anthesis-lab test` | 7 | Stable public conformance fixtures for deterministic policy evaluation. |
| General demonstration catalog | `.anthesis/demos` / `scripts/run-demo-pack.sh` | 27 across 9 packs | Broader synthetic SDLC governance examples for demos and integration design. |
| Inference-integrity contract | `fixtures/inference-integrity` / `anthesis-lab inference-integrity` | 24 | Provider-neutral synthetic inference evidence evaluated against the inference-integrity contract. |

The 24 inference-integrity scenarios are not part of the 27-scenario demo-pack catalog. See [`inference-integrity-fixtures.md`](inference-integrity-fixtures.md) for that contract.

## Collections

### Canonical conformance suite — 7 scenarios

Path: `.anthesis/scenarios`

These seven scenarios are synchronized public-contract fixtures. They validate evaluator compatibility and must remain separate from the expanding demonstration catalog.

| ID | Expected decision | Purpose |
|---|---|---|
| `01-allowed-docs-edit` | `allow` | Scoped documentation write. |
| `02-block-ci-change` | `approval_required` | CI workflow mutation requires approval. |
| `03-require-network-approval` | `approval_required` | External network access requires approval. |
| `04-block-secret-access` | `deny` | Secret-like path protection takes precedence. |
| `05-require-dependency-approval` | `approval_required` | Dependency changes require approval. |
| `06-fail-unknown-runtime` | `deny` from `engine_guard` | Unregistered runtime fails closed. |
| `07-block-evidence-tamper` | `deny` | Evidence mutation is blocked. |

The manifest and fixture directory are checked one-to-one by:

```bash
bash scripts/validate-docs-and-catalog.sh
```

### General demonstration catalog — 9 packs / 27 scenarios

Path: `.anthesis/demos`

The demonstration collection is executable through the signed `anthesis-lab` evaluator. It contains nine synthetic packs with three scenarios each. These scenarios evaluate declared effects but never execute them.

Machine-readable metadata is in [`demo-catalog.json`](demo-catalog.json), with presentation-oriented detail in [`demo-packs.md`](demo-packs.md).

Available packs:

- `documentation`;
- `source-code`;
- `ci-and-release`;
- `dependencies`;
- `secrets-and-evidence`;
- `network-and-tools`;
- `runtime-and-identity`;
- `deployment-and-administration`;
- `adversarial`.

Run them with:

```bash
bash scripts/run-demo-pack.sh --list
bash scripts/run-demo-pack.sh documentation | jq .
bash scripts/aggregate-demo-packs.sh | jq .
```

Expected aggregate result:

```json
{
  "classification": "passed",
  "pack_count": 9,
  "passed_packs": 9,
  "total_scenarios": 27
}
```

## Required demo metadata

Every non-canonical demo must identify:

- stable ID and title;
- pack;
- scenario path;
- use case;
- declared capability or attempt;
- expected decision, source, rule, and reason;
- threat or control demonstrated;
- trust assumption;
- accepted Anthesis contract version;
- whether a real effect executes, which must be `false` in this repository;
- related issue or production-integration example.

## Decision coverage

The complete catalog demonstrates:

- allow;
- approval required;
- policy-rule denial;
- engine-guard denial;
- expectation mismatch;
- malformed or unsafe input rejection where appropriate.

Not every pack manufactures every outcome. Policy must not be weakened solely to produce a visually balanced demo.

## Curated showcase

The recommended five-case walkthrough is synchronized with [`docs/walkthroughs/showcase.json`](../walkthroughs/showcase.json) and the [five-minute walkthrough](../walkthroughs/five-minute-demo.md):

1. scoped documentation write allowed;
2. CI workflow change requiring approval;
3. direct merge denied by policy;
4. unknown runtime denied by the engine guard;
5. deliberate expectation drift detected with exit code `7`.

This sequence shows normal permission, higher-impact review, prohibited repository administration, runtime identity enforcement, and governance regression detection.

For the 24-case inference-integrity extension, use the dedicated [inference-integrity runbook](../runbooks/inference-integrity-demo.md).
