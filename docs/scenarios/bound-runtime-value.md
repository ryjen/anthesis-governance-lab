# Exact lookup-bound runtime values (issue #99)

This deterministic, synthetic, no-effects fixture checks exact write arguments against a declared trusted structured lookup and its revision. Six cases include positive exact binding and unrelated-state change, plus changed recipient, changed amount, stale lookup revision and untrusted source denials.

Run `bash scripts/validate-bound-runtime-value.sh` and `bash scripts/test-bound-runtime-value.sh`. Eleven negative mutations must be rejected. Both run from `scripts/validate-external-security-fixtures.sh`.

**Assurance boundary:** this is a consistency assertion over fixture-owned lookup, authorization, policy revision, and expected verdict fields. It does **not** authenticate runtime lookup results, verify a live policy decision, enforce actual tool calls, observe effects, establish replay protection, or prove complete mediation. A fixture author can change both lookup and write records; passing validation is not independent evidence of trusted source provenance. No network, credentials, live model, or protected effect is required.

Remaining #99 variants: deferred source, commit/recovery, and semantic judge. Anthesis owns effect-time authority and policy semantics; Dubnium owns runtime qualification.
