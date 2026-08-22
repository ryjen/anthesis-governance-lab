# External Agent-Security Crosswalk

This crosswalk maps current Governance Lab proof surfaces to selected external agent-security guidance. It is **non-normative**, does not claim certification or conformance, and does not turn external guidance into Anthesis policy.

The machine-readable source is [`external-security-crosswalk.json`](external-security-crosswalk.json).

## Interpretation

Coverage values mean:

- **demonstrated** — the lab has a deterministic synthetic case that directly exercises the stated property at the declaration/evidence layer;
- **partial** — related behavior is exercised, but one or more important parts of the external control are outside the current public contract;
- **runtime-dependent** — the property primarily depends on a real executor, network, credential, or containment boundary that this repository does not implement;
- **not-demonstrated** — no current scenario establishes the property;
- **not-applicable** — the external control does not apply to this lab surface.

A `demonstrated` row still inherits the repository's integration boundary: Governance Lab evaluates synthetic declarations and recorded evidence. It does not execute file, network, tool, deployment, release, or other consequential effects.

## Current coverage

| External guidance | Topic | Coverage | Existing lab evidence | Main gap |
| --- | --- | --- | --- | --- |
| CoSAI MCP Security #22 | Complete mediation / bypass resistance | runtime-dependent | network/tool allow/approval/deny cases; unknown-runtime denial; inference direct-runtime-bypass and fail-closed verifier cases | no proof that raw endpoints, credentials, network routes, or alternate registries are unreachable in production |
| CoSAI MCP Security #26 | Supply-chain provenance and authority boundary | partial | dependency read/change/install separation; evidence-write denial; immutable re-verification cases | no provider-neutral SBOM/AIBOM/signature/attestation state model yet |
| CoSAI Agentic IAM | Delegation and least privilege | partial | capability-expansion denial; registered vs unknown runtime decisions | no authenticated delegation chain or child-scope attenuation vector |
| OWASP GenAI LLM Top 10 2026 | Excessive agency | partial | unrestricted command denial; deploy/release denial; workflow approval | no live downstream complete-mediation proof |
| OWASP Agentic ASI02 | Tool Misuse & Exploitation | partial | bounded test command vs unrestricted/capability-expanding command | no exact live tool/argument authorization binding |
| OWASP Agentic ASI03 | Identity & Privilege Abuse | demonstrated | registered runtime allowed; unknown runtime read/write denied; missing resolved inference identity rejected | no production workload-identity issuance/authentication proof |
| OWASP Agentic ASI04 | Agentic Supply Chain Vulnerabilities | partial | dependency inventory/mutation/install separation; immutable evidence | no AI artifact attestation/AIBOM verification |
| OWASP Agentic ASI06 | Memory & Context Poisoning | not-demonstrated | none | public contract does not yet express governed durable-memory/context writes |
| OWASP Agentic ASI07 | Insecure Inter-Agent Communication | not-demonstrated | specialist/synthesis tamper localization is adjacent evidence | no authenticated/replay-resistant handoff or delegation-continuity vector |
| OWASP AIBOM / CycloneDX | AI artifact identity/composition | not-demonstrated | none | no AIBOM/ML-BOM parser or prompt/context artifact fixture |
| CoSAI Agent Manifest #149 | Manifest-version to action-time authority binding | not-demonstrated | route-change and re-verification mutation detection are adjacent | no exact action decision bound to admitted manifest version |

## Reused scenario inventory

The crosswalk intentionally reuses existing fixtures before creating more scenarios.

### Complete mediation and authority boundaries

- `network-and-tools-01-allow-test-command`
- `network-and-tools-02-require-network-approval`
- `network-and-tools-03-deny-unrestricted-command`
- `runtime-and-identity-02-deny-unknown-runtime-read`
- `runtime-and-identity-03-deny-unknown-runtime-write`
- inference `block-direct-runtime-bypass`
- inference `required-gate-fails-closed-on-verifier-outage`

These demonstrate deterministic decisions over known declarations and evidence. They **do not** demonstrate that the real operating system, network, MCP registry, credentials, or downstream APIs prevent an alternate effect path.

### Supply chain and evidence integrity

- `dependencies-01-allow-manifest-read`
- `dependencies-02-require-manifest-approval`
- `dependencies-03-require-install-approval`
- `secrets-and-evidence-02-deny-evidence-write`
- inference `preserve-original-on-reverification`
- inference `reject-reverification-mutation`

These establish that dependency mutation/acquisition can receive stronger decisions than inventory reads and that recorded evidence is protected from silent mutation. They do **not** establish that an external signature, SBOM, AIBOM, attestation, or vulnerability statement is valid.

### Identity and capability narrowing

- `runtime-and-identity-01-allow-registered-runtime`
- `runtime-and-identity-02-deny-unknown-runtime-read`
- `runtime-and-identity-03-deny-unknown-runtime-write`
- `adversarial-03-deny-capability-expansion-command`
- inference `reject-missing-resolved-identity`

These establish deterministic fail-closed behavior for unknown/missing runtime identity and capability-expansion declarations. They do **not** authenticate a real workload identity or delegation chain.

## First missing vectors

The inventory shows that the next work should not be another broad demo pack. The smallest missing vectors are cross-boundary cases that the current declaration contract cannot fully express yet.

### 1. Verified artifact does not grant action authority

Desired result:

```text
artifact evidence = verified
requested action = outside current authority
result = deny
```

The fixture should represent evidence state independently from the action authorization result. A valid signature, AIBOM, SBOM, model identity, or attestation must never become an implicit allow.

Required evidence states for the eventual provider-neutral fixture:

- `verified`
- `missing`
- `stale`
- `mismatch`
- `contradictory`
- `unverifiable`

Operational/provider failure must remain distinguishable from negative evidence.

### 2. Exact action decision becomes stale after manifest drift

Desired sequence:

```text
admit manifest M1
  -> authorize exact action A1 against M1
  -> deployment changes to M2 before dispatch
  -> reject M1-bound decision
  -> require fresh decision against M2
  -> execute only after M2-bound decision
  -> receipt records M2 + exact action + observed effect reference
```

Variants should change normalized arguments, actor/delegation context, tool schema, or policy revision independently.

This vector must not claim that a valid manifest proves semantic correctness of the selected action.

### 3. Runtime complete-mediation test harness

The declaration layer cannot prove production bypass resistance. A later bounded runtime fixture should test known equivalent effect paths explicitly:

- governed MCP/tool route succeeds;
- raw MCP/tool route is unreachable;
- downstream credential is unavailable to the agent runtime;
- direct network/API route cannot reproduce the effect;
- alternate server/tool registration cannot introduce an unmediated path;
- loss of the policy/enforcement service fails closed for consequential effects.

Passing such a harness would still establish only the tested reachable surface, not exhaustive absence of unknown bypasses.

### 4. Delegation narrowing and inter-agent continuity

A future public contract should make it possible to express:

- authenticated parent actor;
- parent capability/grant identifier;
- child/specialist actor;
- requested child scope;
- expected monotonic narrowing;
- replay/freshness state.

A child request wider than the parent grant must fail regardless of model rationale.

### 5. Durable memory/context write governance

A future scenario should treat a shared or durable memory write as a consequential effect rather than inert metadata. The vector should distinguish approved scoped memory updates from unapproved writes and retain source/provenance information for later audit.

## Upstream contribution packaging

The generic cases should be exportable without requiring Anthesis tooling or Anthesis vocabulary.

Initial targets:

1. CoSAI MCP Security #22 — complete-mediation/bypass scenarios;
2. CoSAI MCP Security #26 — evidence-state and `verified artifact != authorized action` scenarios;
3. CoSAI Agent Manifest #149 — manifest-version/action-time decision binding vector;
4. OWASP Agentic — tool misuse, identity/privilege, supply-chain, memory/context, and inter-agent cases;
5. OWASP AIBOM — provider-neutral AI artifact identity/substitution case after Invokrum/Anthesis work establishes the representation.

## Assurance boundary

This crosswalk and its scenarios do not prove:

- certification or compliance with CoSAI or OWASP guidance;
- absence of all bypass routes;
- production network isolation;
- production credential unreachability;
- correctness of external identity issuers, evidence providers, or policy engines;
- semantic correctness of an agent's selected action;
- that telemetry or evidence can grant authority;
- that a signed artifact or manifest is safe to execute.

They are deterministic, synthetic evidence that specific policy/evidence properties can be reproduced against the public Governance Lab contract.
