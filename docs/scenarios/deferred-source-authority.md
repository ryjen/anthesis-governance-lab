# Deferred source is not authority (issue #99)

This deterministic synthetic fixture models a mutable TODO-page fetch followed by proposed actions. The source may be authenticated and contain hostile instructions, but **source authenticity does not confer authority**. A request is modeled as allowed only when a separate current grant exactly matches request kind and scope.

Five cases cover an authorized fetch, hostile protected write denied, authenticated source without grant denied, independently scoped benign delegated read allowed, and stale grant denied. Run `bash scripts/validate-deferred-source-authority.sh` and `bash scripts/test-deferred-source-authority.sh` (ten rejected mutations). Both are called by the external-security fixture suite.

**Assurance boundary:** all grants, source fields, requests and expected decisions are fixture-owned synthetic declarations. The verdict is a modeled consistency check, not independent policy evaluation. This fixture does not prove real source authentication, authority provenance, effect-time checks, complete mediation, or production containment. No network, credentials, live model or protected effect is used.

Follow-up #99 variants: commit/recovery and semantic-judge narrowing. Anthesis #26 owns deferred policy-source boundary; Dubnium owns runtime qualification.
