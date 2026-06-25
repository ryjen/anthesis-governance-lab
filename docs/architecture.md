# Architecture

This lab has three intentionally simple layers:

```text
Scenario envelope
  -> Anthesis runner
  -> governed agent/runtime
  -> bounded tools
  -> evidence bundle
```

The application code is a small calculator module. The governance surface is modeled under `.anthesis/`.

## Governance focus

The important test surface is not application complexity. It is whether Anthesis can make each run explainable:

- task intent
- actor/runtime identity
- policy profile
- tool decisions
- file changes
- approvals
- evidence
