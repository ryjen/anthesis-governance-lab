# Design-partner evaluation

Use this scorecard when handing Governance Lab to a candidate customer, design partner, or other realistic evaluator.

The evaluation asks one practical question:

> Did Anthesis increase governance decision confidence without introducing unacceptable workflow friction?

The scorecard is an evaluation aid. It is not a policy, approval, capability, evidence, or authority contract, and completing it does not make a deployment production-ready.

## Primary outcome: Governance Decision Confidence

After the evaluator has run the canonical scenarios and the executable reference trial, ask:

> Can you explain what happened, why it was allowed, blocked, or approval-gated, and what evidence proves it?

Score the answer from 1 to 5:

- **1** — cannot explain the decision or identify trustworthy evidence;
- **2** — partial explanation with important ambiguity;
- **3** — understandable with material operator help or missing evidence;
- **4** — clear, independently explainable, and adequately evidenced;
- **5** — clear, independently explainable, strongly evidenced, and easy to reconstruct.

Initial target: **>= 4/5**.

## Before scoring

From a fresh checkout, acquire the pinned evaluator and run the public proof surfaces:

```bash
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"

anthesis-lab test --repo . --format json
bash scripts/run-reference-trial.sh
```

For a complete technical preflight, also run [`docs/runbooks/full-verification.md`](runbooks/full-verification.md).

The evaluation covers two different proof classes:

1. the **seven canonical Governance Lab scenarios**, which deterministically evaluate declarations but do not execute their effects;
2. the **reference trial**, which performs one bounded repository mutation through `anthesis.repo_write` and hard-denies both a raw writer bypass and an out-of-scope governed write.

Do not collapse these proof classes into one claim.

## What to record

Use [`.anthesis/evaluation/scorecard.yaml`](../.anthesis/evaluation/scorecard.yaml) as the machine-readable template. It is JSON-formatted YAML so it can be parsed by standard JSON tooling as well as YAML tooling.

Record:

- evaluator and workflow context without unnecessary personal data;
- setup time and time to first governed action;
- the seven canonical decision results;
- reference-trial mutation and bypass results;
- Governance Decision Confidence;
- technical correctness;
- operator experience;
- customer value;
- the six public trial criteria: enforceability, attribution, least privilege, human approval, auditability, and bypass resistance;
- false-positive denies and false-negative allows;
- whether the evaluator would try Anthesis on a real workflow and continue after the trial.

A synthetic completed example is available at [`.anthesis/evaluation/results.example.yaml`](../.anthesis/evaluation/results.example.yaml). Do not reuse its scores as evidence.

## Technical correctness

The initial trial should require:

- all seven canonical scenarios match their expected decision and source semantics;
- the allowed reference mutation produces an inspectable Git diff;
- the raw writer bypass hard-denies and leaves repository state unchanged;
- the out-of-scope governed write hard-denies and leaves repository state unchanged;
- policy decision and request binding are attributable;
- runtime/evaluator identity is recorded;
- evidence is sufficient to reconstruct the reference trial;
- false-negative allows are **zero**.

A false-negative allow is a safety failure and should not be averaged away by high usability scores.

## Operator experience

Capture at minimum:

- setup time;
- time to first governed action;
- decision/failure-message clarity;
- false-positive deny count;
- time to reconstruct and explain a completed run;
- whether the runtime restriction and residual trust assumptions were understandable.

These measurements are intended to expose friction, not optimize a vanity benchmark.

## Customer value

Ask the evaluator to score 1-5:

- evidence bundle / trial record understandable — target **>= 4**;
- decisions independently explainable — target **>= 4**;
- governance friction acceptable — target **>= 4**;
- bypass boundary understandable — target **>= 4**.

Also ask two direct questions:

- Would you use Anthesis on a real repository or workflow?
- Would you continue using Anthesis after this trial?

A technically correct demo that receives two negative answers has not demonstrated design-partner value.

## Six assurance dimensions

Use the public [Anthesis trial criteria](https://github.com/hackelia-micrantha/anthesis-community/blob/main/docs/product/trial-criteria.md) as the interpretation authority for these dimensions:

1. **Enforceability** — does the selected effect actually cross the claimed governance boundary?
2. **Attribution** — can the evaluator associate request, actor/runtime, decision, tool, and outcome?
3. **Least privilege** — are deliberately out-of-scope variants denied?
4. **Human approval** — are approval-required effects held before execution and exactly scoped?
5. **Auditability** — can the evaluator reconstruct what happened from durable evidence?
6. **Bypass resistance** — are direct effect paths enumerated and tested for the selected integration mode?

### Approval limitation in this reference lab

The canonical suite proves that an approval-required declaration is held as `approval_required`. Governance Lab does **not** persist an approval and then execute the approved effect.

The executable reference trial currently uses an `allow` decision, so approval and capability fields are intentionally null. Score the lab's **pre-approval hold semantics** here; score end-to-end approval binding only in a real workflow that actually implements it.

## Recommended trial decision

Use one of three dispositions:

- **proceed-to-real-workflow** — technical correctness is intact, no false-negative allow occurred, Governance Decision Confidence is >= 4, and the evaluator is willing to try a real workflow;
- **needs-fix** — the concept is useful but a concrete correctness, clarity, friction, or integration gap should be fixed first;
- **stop** — the evaluator does not see sufficient value or the claimed enforcement boundary cannot be established safely.

Do not activate broad architecture work from a low score alone. Record the smallest observed blocker and promote that concrete gap into the normal Anthesis issue queue.
