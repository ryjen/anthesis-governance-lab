# Anthesis Governance Lab

A deliberately small repository for evaluating deterministic governance of AI-assisted SDLC workflows.

This repository is a consumer of the accepted public Governance Lab CLI contract in [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community/tree/main/specs/governance-lab). Contract semantics, schemas, matching rules, and canonical conformance expectations are defined there rather than duplicated here.

## What the lab evaluates

The seven canonical scenarios demonstrate:

1. allowed documentation changes
2. approval-gated CI workflow changes
3. approval-gated network access
4. denied secret access
5. approval-gated dependency changes
6. fail-closed behavior for an unknown runtime
7. denied evidence tampering

A successful evaluation does not mean every attempted action completes. Success means the evaluator produces the expected deterministic decision, identifies its source and public rule, and records verifiable evidence.

## Contract inputs

The lab stores its accepted inputs under `.anthesis/`:

- `policies/local-sdlc.yaml` — canonical default-deny policy
- `runtime-profile.yaml` — explicit runtime allowlist
- `scenarios/` — seven single-effect conformance scenarios

Natural-language `goal` fields are descriptive only. Authority comes exclusively from each scenario's explicit `attempts` entry, actor, runtime, and policy.

## Commands

The accepted CLI surface is:

```bash
anthesis-lab evaluate --repo . --scenario .anthesis/scenarios/01-allowed-docs-edit.yaml
anthesis-lab test --repo .
anthesis-lab verify --evidence .anthesis/evidence/run.jsonl
anthesis-lab version
```

`anthesis-lab test --repo .` should discover the scenarios in lexical order and verify all seven expected decision, source, rule, reason, and evidence requirements.

## Expected outcomes

| Scenario | Decision source | Expected decision |
|---|---|---|
| `01-allowed-docs-edit` | `policy_rule` | `allow` |
| `02-block-ci-change` | `policy_rule` | `approval_required` |
| `03-require-network-approval` | `policy_rule` | `approval_required` |
| `04-block-secret-access` | `policy_rule` | `deny` |
| `05-require-dependency-approval` | `policy_rule` | `approval_required` |
| `06-fail-unknown-runtime` | `engine_guard` | `deny` |
| `07-block-evidence-tamper` | `policy_rule` | `deny` |

## Evaluation questions

After each scenario, the evaluator should be able to answer:

- What effect was explicitly attempted?
- Was it allowed, denied, or routed to approval?
- Did the decision come from a policy rule, policy default, or engine guard?
- Which public policy rule and stable reason produced the outcome?
- Which runtime identity was configured?
- Which policy revision was evaluated?
- What evidence was captured, and does its digest verify?

## Trust boundary

The lab evaluates contract behavior; it does not prove production sandboxing, credential isolation, distributed enforcement, release automation, or resistance to a hostile administrator. Evaluation must not execute the attempted command, network request, file mutation, deployment, merge, or release operation.

## License

Licensed under the Apache License 2.0. See [LICENSE](./LICENSE).
