# Baseline SDLC Demo Packs

These non-canonical scenarios extend the Governance Lab with realistic, synthetic SDLC declarations. They remain separate from `.anthesis/scenarios`, do not modify the accepted policy, and never execute declared effects.

Machine-readable metadata is in [`demo-catalog.json`](demo-catalog.json).

## Documentation

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `documentation-01-allow-docs-write` | `allow` | A repository-relative documentation write within the scoped boundary. |
| `documentation-02-allow-docs-read` | `allow` | Read-only documentation inspection. |
| `documentation-03-deny-outside-boundary` | `deny` from `policy_default` | A root configuration write fails closed because no allow rule matches. |

## Source code

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `source-code-01-allow-source-write` | `allow` | A bounded source edit under `src/**`. |
| `source-code-02-allow-test-write` | `allow` | A bounded regression-test edit under `tests/**`. |
| `source-code-03-deny-merge` | `deny` | Direct merge effects are blocked by policy. |

## CI and release

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `ci-and-release-01-allow-workflow-read` | `allow` | Workflow metadata may be inspected without mutation. |
| `ci-and-release-02-require-workflow-approval` | `approval_required` | Workflow changes cross a review boundary. |
| `ci-and-release-03-deny-release` | `deny` | Direct release publication is prohibited. |

## Dependencies

| Scenario | Expected result | Demonstrates |
|---|---|---|
| `dependencies-01-allow-manifest-read` | `allow` | Dependency inventory is read-only. |
| `dependencies-02-require-manifest-approval` | `approval_required` | Manifest changes require review. |
| `dependencies-03-require-install-approval` | `approval_required` | Networked package installation requires review. |

## Enforcement boundary

The lab evaluates declarations only. It does not write files, invoke package managers, merge branches, publish releases, use network credentials, or persist approvals. A production integration must bind the decision to a separate governed executor and prevent alternate access to effectful tools.

## Execution status

Issue #9 tracks deterministic pack selection and executable validation. Until that runner lands, these fixtures are structurally validated and cataloged but are not advertised as a stable standalone pack-execution interface.