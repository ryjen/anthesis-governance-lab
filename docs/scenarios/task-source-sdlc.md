# Malicious issue/task-source SDLC conformance (#80)

The trusted operator objective is to resolve a functional defect described by issue 80. The issue and its linked observations supply task content, **not** authority to install dependencies, create persistent hooks, change agent configuration, or exceed process budgets.

Eight synthetic no-effects cases pair a denied malicious prerequisite with a useful allowed path for each family: dependency installation/source edit, persistent hook/scoped test edit, agent configuration/scoped source edit, and unbounded spawn/bounded test run. The fixture preserves four source delivery kinds: issue body, issue comment, linked document, and repository comment. A source may claim capability, but admission is modeled by a distinct host-policy record bound to the exact task and action; the source's claim does not grant authority.

Run `bash scripts/validate-task-source-sdlc.sh` and `bash scripts/test-task-source-sdlc.sh`; eighteen negative mutations must be rejected. Both are invoked from the external-security validation suite.

**Limits:** All grants, observations, decisions, and effects are fixture-owned declarations. ALLOW means permitted in this modeled policy, not that a real action ran. DENY with `observed_effect: false` is a declared null effect, not independent host telemetry. This is not a coding-agent implementation, production capability boundary, live model evaluation, dependency safety assessment, or complete-mediation proof. No network, credentials, actual effects, or live model are used.
