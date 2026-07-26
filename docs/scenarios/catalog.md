# Governance Lab Scenario Catalog

## Collections

### Canonical conformance suite

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

### Demonstration catalog

The separate demo collection is tracked by issues #6–#9. It will contain themed, synthetic use cases without changing the canonical conformance suite.

Planned packs:

- documentation;
- source code;
- CI and release;
- dependencies;
- secrets and evidence;
- network and tools;
- runtime and identity;
- deployment and repository administration;
- adversarial declarations.

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

The complete catalog should demonstrate:

- allow;
- approval required;
- policy-rule denial;
- engine-guard denial;
- expectation mismatch;
- malformed or unsafe input rejection where appropriate.

Not every pack must manufacture every outcome. Policy must not be weakened solely to produce a visually balanced demo.

## Curated showcase

The recommended five-scenario walkthrough is:

1. allowed documentation edit;
2. approval-gated CI workflow change;
3. denied secret access;
4. engine-guard denial for unknown runtime;
5. expectation drift detected with exit code `7`.

This sequence shows normal permission, higher-impact review, protected data, runtime identity enforcement, and governance regression detection.
