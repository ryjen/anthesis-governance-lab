# Commit/recovery and stale grant context (issue #99)

This synthetic, deterministic, no-effects fixture distinguishes a declared **verified committed prior step** from proposed, indeterminate or unverified states. An advancing proposal is modeled as allowed only when the prior step has a verified receipt and its grant matches the current run, restart epoch, attempt and policy revision.

Eight cases cover one positive control and seven denial cases. Run `bash scripts/validate-commit-recovery.sh` and `bash scripts/test-commit-recovery.sh`; fifteen negative mutations must be rejected. Both run via `scripts/validate-external-security-fixtures.sh`.

**Assurance boundary:** receipt verification, grant provenance and state are fixture-owned declarations. This is not a persistent recovery implementation, a transactional commit protocol, or runtime effect-time authorization. It does not prove a durable ledger, exactly-once semantics, concurrent execution safety, replay prevention after real crashes, or complete mediation. No network, credentials, live model or protected effect is involved.

Issue #99 remaining variant: semantic judge only narrows. Anthesis #203/#204 own effect-time state semantics; Dubnium owns runtime adapters.
