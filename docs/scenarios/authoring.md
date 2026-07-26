# Scenario Authoring Guide

## Principles

Governance Lab scenarios are deterministic declarations evaluated by `anthesis-lab`. They are not executable automation steps.

Every scenario must:

- use synthetic data only;
- remain repository-relative and portable;
- declare only accepted public-contract fields;
- identify an expected decision independently from the policy;
- explain the use case and threat;
- state that no effect executes;
- avoid credentials, tokens, private endpoints, or production identifiers.

## Canonical versus demo scenarios

`.anthesis/scenarios` is reserved for the synchronized seven-scenario public-contract conformance suite.

Additional use-case demonstrations must live in a separate collection introduced by issue #8. Do not add showcase-only scenarios to the canonical directory.

## Stable identifiers

Use lexically sortable, descriptive identifiers:

```text
01-allowed-docs-edit
02-require-ci-approval
03-deny-secret-access
```

Within themed packs, prefix IDs consistently so discovery order is deterministic.

## Required catalog fields

Each demonstration entry must include:

```yaml
id: ci-and-release.workflow-change
title: Change a CI workflow
pack: ci-and-release
scenario: .anthesis/demos/ci-and-release/02-workflow-change.yaml
use_case: An agent proposes changing a GitHub Actions workflow.
threat: The change could alter credentials or release behavior.
executes_effect: false
contract: anthesis.scenario/v1
expected:
  decision: approval_required
  source: policy_rule
  rule_id: ci-change-approval
  reason: ci_change_requires_approval
```

The catalog metadata is documentation and validation input. It must not become an alternate policy engine.

## Safety requirements

- Never include a real secret, credential, email body, customer record, or production URL.
- Use obvious synthetic placeholders when demonstrating secret-like data.
- Never let scenario content choose acquisition URLs, tokens, executors, or output destinations.
- Avoid absolute, home-relative, parent-traversal, and symlink-dependent paths.
- Keep one declared attempt per scenario unless the accepted contract explicitly requires another structure.
- Do not weaken policy to force a desired demo outcome.

## Expected results

Expected values assert evaluator behavior. They do not direct it.

A changed expected decision must produce a mismatch while leaving the actual policy decision unchanged. Use the existing drift exercise as the reference.

## Validation checklist

Before submitting a scenario:

1. validate syntax and schema;
2. confirm catalog metadata is complete;
3. run the selected pack;
4. confirm the actual decision source, rule, and reason;
5. confirm `executes_effect` is `false`;
6. run the canonical suite and ensure seven passes remain unchanged;
7. verify no host-specific paths or sensitive values appear in reports.
