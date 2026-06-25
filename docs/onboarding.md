# Onboarding

This repository is a safe target for testing Anthesis governance behavior.

Start with scenario 01, which should succeed. Then run the fault-injection scenarios, which deliberately attempt governed violations.

Expected outcomes:

- docs-only edits should be allowed
- CI workflow edits should require approval or be denied
- network access should require approval
- secret access should be denied
- dependency changes should require approval
- unknown runtimes should fail closed
- evidence tampering should be denied
