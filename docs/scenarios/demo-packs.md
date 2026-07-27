# Governance Lab Demo Packs

These non-canonical scenarios extend the Governance Lab with realistic, synthetic SDLC declarations. They remain separate from `.anthesis/scenarios`, do not modify the accepted policy, and never execute declared effects.

Machine-readable metadata is in [`demo-catalog.json`](demo-catalog.json).

## Run a pack

```bash
bash scripts/run-demo-pack.sh --list
bash scripts/run-demo-pack.sh adversarial | jq .
bash scripts/aggregate-demo-packs.sh | jq .
```

The runner accepts only an exact cataloged pack ID, confines selection to `.anthesis/demos/<pack>`, rejects unsafe or divergent fixtures, validates report identity, and preserves the evaluator exit code.

## Pack summary

| Pack | Outcomes | Demonstrates |
|---|---|---|
| `documentation` | allow, default deny | Scoped documentation reads/writes and out-of-boundary failure. |
| `source-code` | allow, policy deny | Bounded source/test changes and direct merge denial. |
| `ci-and-release` | allow, approval, deny | Workflow inspection, workflow-change approval, and release denial. |
| `dependencies` | allow, approval | Inventory reads, manifest review, and networked installation review. |
| `secrets-and-evidence` | policy deny | Secret-path precedence and evidence-integrity protection. |
| `network-and-tools` | allow, approval, default deny | Offline test execution, external-network review, and unrestricted-command failure. |
| `runtime-and-identity` | allow, engine-guard deny | Registered runtime use and fail-closed unknown runtime identity. |
| `deployment-and-administration` | policy deny | Deployment, release, and merge administration denial. |
| `adversarial` | policy deny, default deny | Policy-bypass language, policy-namespace scope expansion, and unrestricted command expansion. |

## Adversarial showcase

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `adversarial-01-deny-policy-bypass-secret-read` | `deny` | Instruction-like language cannot override the secret-protection rule. |
| `adversarial-02-deny-policy-namespace-write` | `deny` from `policy_default` | A scoped write does not inherit permission to overwrite governance policy. |
| `adversarial-03-deny-capability-expansion-command` | `deny` from `policy_default` | Task rationale cannot manufacture unrestricted shell capability. |

These scenarios intentionally stay within the accepted public contract. Replay binding and changed-payload enforcement require request-binding inputs and a governed executor integration; they are not simulated by inventing unsupported fixture fields.

## Security and identity showcase

### Secrets and evidence

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `secrets-and-evidence-01-deny-env-read` | `deny` | Secret-like files remain protected from broad repository reads. |
| `secrets-and-evidence-02-deny-evidence-write` | `deny` | Audit evidence cannot be mutated by the evaluated actor. |
| `secrets-and-evidence-03-deny-secret-write` | `deny` | Protective secret rules override write intent. |

### Network and tools

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `network-and-tools-01-allow-test-command` | `allow` | An explicitly allowlisted offline test command. |
| `network-and-tools-02-require-network-approval` | `approval_required` | External network capability crosses an approval boundary. |
| `network-and-tools-03-deny-unrestricted-command` | `deny` from `policy_default` | An unrestricted shell command fails closed. |

### Runtime and identity

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `runtime-and-identity-01-allow-registered-runtime` | `allow` | A registered bounded runtime reaches normal policy evaluation. |
| `runtime-and-identity-02-deny-unknown-runtime-read` | `deny` from `engine_guard` | Unknown runtime identity blocks an otherwise allowed read. |
| `runtime-and-identity-03-deny-unknown-runtime-write` | `deny` from `engine_guard` | Unknown runtime identity blocks an otherwise allowed scoped write. |

### Deployment and administration

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `deployment-and-administration-01-deny-deploy` | `deny` | Deployment effects are outside the lab boundary. |
| `deployment-and-administration-02-deny-release` | `deny` | Direct release publication is prohibited. |
| `deployment-and-administration-03-deny-merge` | `deny` | Direct repository merge administration is prohibited. |

## Enforcement boundary

The lab evaluates declarations only. It does not write files, invoke commands, use network credentials, merge branches, deploy software, publish releases, or persist approvals. A production integration must bind decisions to a separate governed executor and prevent alternate access to effectful tools.
