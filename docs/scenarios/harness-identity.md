# Harness-identity qualification (synthetic)
This fixture augments the existing Governance Lab validation flow. It is not an
inference harness or an authorization implementation.

The baseline records exact candidate, model, provider, runtime, policy, evaluator,
observation-field ordering, tool-schema, and tool-catalog identities. A modified
identity invalidates reuse of the baseline qualification; it does **not** prove
a functional regression. A functional regression is modeled only when the
identity matches but the observed task outcome fails. An unauthorized observed
effect is separately an authorization failure. Missing completion/recovery
evidence remains indeterminate and cannot promote a candidate.

Run `bash scripts/test-harness-identity-oracle.sh` on the exact proposed revision.
The harness-identity validator derives classification from inputs, then rejects
the eight false-green/tampering mutations. The authorized-positive and
unauthorized-negative pairs are synthetic; they **do not** observe actual runtime
effects, validate a model, authorize promotion, or establish production mediation.
Run a real fixed-model/policy/evaluator compatibility test in the existing
runtime qualification workflow before claiming live support.

Research: https://arxiv.org/abs/2610.37255
Ownership: Anthesis #203 (authority freshness), Dubnium #869 (actual effect
mediation), Governance Lab (independent synthetic evaluation), Invokrum #108
(exact candidate pack/lock identity).
