# Decision and Report Interpretation

## Actual versus expected

An Anthesis scenario test contains an expected result used to verify evaluator behavior. The evaluator computes the actual decision from policy, runtime profile, and declared attempt.

Changing the expected result must not change the actual decision. A disagreement is reported as a mismatch.

## Decision classes

### `allow`

The declaration matched an allow rule. The Governance Lab does not execute the declared effect.

### `approval_required`

Policy requires an external approval before a separate governed executor may act. The Governance Lab does not collect, bind, or persist approvals.

### Policy-rule `deny`

A named policy rule blocked the declaration. Inspect the rule ID and stable reason to understand the protected boundary.

### Engine-guard `deny`

An evaluator guard rejected the declaration independently of ordinary policy-rule matching, such as an unknown runtime identity.

## Fields to inspect

For each scenario, inspect:

- scenario ID;
- actual decision;
- expected decision;
- passed status;
- decision source;
- rule ID;
- reason;
- evidence fields;
- mismatches.

A stable rule and reason are preferable to inferring behavior from prose alone.

## Report status

A successful canonical report uses `anthesis.test-report/v1`, reports seven scenarios, and has zero failures.

Exit status `0` means all scenario expectations matched actual decisions.

Exit status `7` means evaluation completed but at least one expectation did not match. This is the expected status for the intentional drift exercise, not for the canonical suite.

Other nonzero statuses indicate invalid input, unsupported contracts, evaluator failure, or another terminal condition and must not be treated as expectation drift without inspection.

## Preserve exit status through `jq`

Use `pipefail`:

```bash
set -o pipefail
anthesis-lab test --repo . --format json | jq .
```

Without `pipefail`, a successful `jq` process can hide a failed evaluator process.

## What a passing report proves

A passing report proves that the pinned evaluator produced the expected deterministic decisions for the checked-in declarations, policy, and runtime profile.

It does not prove:

- that an agent cannot bypass evaluation;
- that an approval was obtained;
- that an effect was executed safely;
- that production credentials were protected by an external broker;
- that a deployment, merge, release, or network call occurred.

Those properties belong to the governed integration and executor boundary.
