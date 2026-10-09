# AgentDrift source-locked corpus audit

This is an **offline research evaluator**, not a prompt-injection detector, runtime monitor, or authorization mechanism. It extends Governance Lab issue #61 independently of the earlier nine-case synthetic trajectory PR #85.

## Source and reproduction

- Source: [AgentDrift](https://arxiv.org/abs/2609.06972v1) / [upstream repository](https://github.com/Asif-0209/AgentDrift), revision 014a514fa998b4ac4519579fceb8a5884b379bda, CC BY 4.0.
- Lockfile: [agentdrift-corpus-source-lock-v1.json](../../fixtures/external-security/agentdrift-corpus-source-lock-v1.json).
- Exactly three upstream task-disjoint JSONL files are pinned by their Git blob SHA-1 and expected row counts: train 9,081; validation 1,733; test 1,722. Do not mix with the original stratified split.
- **No upstream trajectory contents are vendored.** Synthetic identities, model thoughts, observations, and attack strings remain only in an explicitly obtained local source checkout.

Local use (from Governance Lab root, after obtaining the pinned AgentDrift checkout separately):

    git clone https://github.com/Asif-0209/AgentDrift.git /path/to/AgentDrift
    git -C /path/to/AgentDrift checkout --detach 014a514fa998b4ac4519579fceb8a5884b379bda
    python3 tools/agentdrift_audit.py --data-root /path/to/AgentDrift > audit.json

The auditor uses only the Python standard library and performs no network activity. It checks the complete file bytes, exact Git blob identity, record counts, category/step grammar, distinct IDs and partition identity before reporting. Invalid or missing source data is a failure, not skipped evidence. It outputs hashed task/world keys and summary counts, never the simulated names or attack text.

## Leakage controls and assurance

The audit reports counts **and sorted SHA-256 fingerprints** for normalized `(agent, task)` identities shared across train/validation/test, and for canonical `(agent, world object)` identities shared between partitions; it separately counts test records reusing train/validation worlds. The fingerprint lists allow deterministic cross-run comparison and focused follow-up without printing source text. **They are pseudonymous identifiers, not anonymization**: anyone with the source corpus can recompute a fingerprint and potentially recover the corresponding world/task. Do not publish the report as if those hashes were private. A shared task blocks scoring. **Even if no exact world objects overlap, world-identity and template leakage are not ruled out.** The upstream datasheet documents strong category/world correlations, concentrated templates, and early injection positions. Source-locked input authenticity does not prove that a trained detector was shielded from those shortcuts.

## Optional detector predictions

Once a detector is evaluated outside Governance Lab, provide one external prediction per test trajectory in JSONL, with exactly these fields:

    {"id":"example_id","attacked":false,"step_labels":["benign","benign","benign"]}

    python3 tools/agentdrift_audit.py --data-root /path/to/AgentDrift --predictions /path/to/predictions.jsonl > score.json

The tool requires every source-locked test ID exactly once. It reports attacked-class precision/recall/F1 and confusion counts; per-class false-positive rates for **benign, hard-negative, resisted**; per-pattern recall for **full, partial, delayed**; injection-index exact accuracy; hijacked-span mean overlap; and macro four-class step-label F1. No prediction results are bundled and no model is run.

Every score is explicitly **exploratory and potentially confounded by world identities**. For a defensible generalization claim, separately validate the model's input redaction or world-held-out training protocol, task separation, exact transforms, model/seed/threshold provenance, class denominators and leakage checks. This tool cannot attest to those upstream training properties.

## Tests and boundary

    python3 -m unittest discover -s tests -p 'test_agentdrift_audit.py' -v

CI runs offline unit tests only: pinned-byte tampering, task/world overlap, malformed grammars and predictions, exact ID coverage, and positive/negative metric controls. It does not download the corpus, train a detector, prove actual authorization, or certify runtime complete mediation.

Behavioral step labels, detector predictions, allowed requests and protected executed effects remain independent kinds of evidence. Neither a hijacked trace nor a detector score grants effect authority.
