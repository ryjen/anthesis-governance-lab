# Semantic judgment may narrow, never widen (issue #99)

This deterministic, synthetic, no-effects fixture models a semantic judge as a **narrowing-only** input. A proposed action is allowed only when the semantic judgment is ALLOW **and** independent deterministic scope, target, sequence, and approval checks all pass. A DENY or UNKNOWN judgment denies; a permissive judgment cannot override any failed deterministic check.

Eight cases cover a positive control, semantic denial, four individual deterministic denials, multiple failures, and unknown judgment. Run `bash scripts/validate-semantic-judge-narrowing.sh` and `bash scripts/test-semantic-judge-narrowing.sh`; fifteen negative mutations must be rejected. Both run from the external-security validation suite.

**Assurance boundary:** judgment and constraint results are synthetic fixture-owned declarations, not authenticated runtime decisions. This demonstrates modeled boolean composition only. It does not prove a live model is safe, the deterministic checks are correct, the policy is complete, effect-time authorization occurs, or all alternate effect paths are mediated. No network, credentials, live model or protected effect is used.
