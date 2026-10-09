# AgentDrift pinned task-disjoint corpus audit — observed 2026-10-08

**Status:** measured source-data quality/leakage result; **not detector evaluation, prevention efficacy, or runtime authorization evidence**.

## Source and method

- [AgentDrift paper](https://arxiv.org/abs/2609.06972v1); [upstream repository](https://github.com/Asif-0209/AgentDrift), CC BY 4.0.
- Pinned source commit: `014a514fa998b4ac4519579fceb8a5884b379bda`.
- Read the three complete `data_taskdisjoint/{train,val,test}.jsonl` **Git blobs by exact blob SHA** via the authenticated GitHub connector. Lockfile: [agentdrift-corpus-source-lock-v1.json](../../fixtures/external-security/agentdrift-corpus-source-lock-v1.json).
- Independently iterated all records in a bounded in-memory connector analysis; parsed record identity, split, source category, and step-label grammar, compared exact JSON world objects after deterministic sorted-key normalization, and compared whitespace-normalized, case-insensitive `(agent, task)` identities. The local [agentdrift_audit.py](../../tools/agentdrift_audit.py) reproduces these categories from a pinned local checkout using SHA-256 hashed lookup keys, but **that exact local CLI was not run on the complete corpus in this session**.
- For the diagnostic **training-world lookup only**, use the *training set* frequency-majority `category` (benign / attacked / failed_attack / hard_negative) for each identical `(agent, world)`; compare against the same coarse category for matched test records. This is an intentionally simplistic leakage shortcut, **not** a model, trained detector, or estimate of attack detection.

## Verified corpus structure

| Statistic | Observed |
| --- | ---: |
| Training records | 9,081 |
| Validation records | 1,733 |
| Test records | 1,722 |
| Total records | 12,536 |
| Total labeled tool-call steps | 71,024 |
| Duplicate trajectory IDs | 0 |
| Invalid step-grammar/category/split combinations | 0 |
| Distinct whitespace-normalized task identities across corpus | 250 |
| Task identities occurring in more than one split | **0** |
| Distinct world objects (ignoring agent) | 1,141 |
| Distinct (agent, world) pairs | 1,169 |
| (Agent, world) pairs occurring in more than one split | **979** |
| Test records with exact (agent, world) overlap in train **or** val | **1,715 / 1,722** |
| Test records with exact (agent, world) overlap in **train** | **1,710 / 1,722** |

## Test-set denominators (source categories)

| Source category | Test records |
| --- | ---: |
| Benign | 525 |
| Hard negative | 204 |
| Resisted / failed attack | 218 |
| Full hijack | 450 |
| Partial hijack | 208 |
| Delayed hijack | 117 |
| **Total** | **1,722** |

These six source categories must remain separate in any subsequent detector scoring. The four-category training-world lookup below deliberately uses the upstream coarse `category` field rather than masquerading as a six-class or step-level detector.

## Exact-world train-lookup shortcut diagnostic

| Domain | Test records | Exact training-world matches | Correct coarse-category lookups | Accuracy among matched |
| --- | ---: | ---: | ---: | ---: |
| Banking | 317 | 316 | 308 | 97.5% |
| Email | 343 | 343 | 159 | 46.4% |
| Web | 304 | 300 | 288 | 96.0% |
| Coding | 382 | 377 | 361 | 95.8% |
| Medical | 376 | 374 | 366 | 97.9% |
| **Total** | **1,722** | **1,710** | **1,482** | **86.7%** |

These are *per-matched-record* rates for the coarse `category` label, **not binary attacked precision/recall/F1**. The 12 test records with no matching training world are outside that denominator. World templates and correlated company/person/email strings can leak labels even if an exact world object is absent. The high banking/web/coding/medical rates are consistent with the upstream published world-identity leakage warning; email is a useful contrasting control.

## Research interpretation and limitations

**Supported:** the pinned task-disjoint corpus preserves disjoint normalized tasks but strongly reuses world identities across splits. This can allow a memorization/lookup shortcut unrelated to understanding prompt injection. A task-disjoint split alone is **not** adequate evidence that a detector will generalize to unseen world identities.

**Not supported:** detector accuracy; world-anonymized or world-held-out model training; success/failure of any protective host policy; production complete mediation; external generalization; or accuracy on non-synthetic real agents. Source labels are generator-constructed protocol categories with known shortcuts, and this report does not correct them.

**Next experiment:** require an evaluator/train pipeline to record source-lock identity, world redaction or truly world-held-out split, task/template separation, exact transformed input digest, model/threshold/seed provenance, and separate benign/hard-negative/resisted FPR and full/partial/delayed recall. No such controlled predictions have been supplied. Continue to distinguish detector findings from independently governed effect authority.
