# Environmental Influence Crosswalk Note

Portable fixture: [`../../fixtures/external-security/environmental-influence-v1.json`](../../fixtures/external-security/environmental-influence-v1.json)

This note extends the external-security crosswalk without promoting the portable fixture into the canonical `anthesis-lab` runtime scenario catalog.

## Relevant rows

### OWASP Agentic ASI02 — Tool Misuse & Exploitation

Additional portable evidence:

- attacker-writable repository content is observed through an ordinary read path;
- the resulting protected-effect request is independently denied;
- valid source/observation evidence is preserved;
- the protected target remains unchanged in deterministic terminal state.

Coverage remains **partial** because this synthetic vector does not prove live tool mediation, downstream credential isolation, or absence of alternate effect paths.

### OWASP Agentic ASI06 — Memory & Context Poisoning

Adjacent portable evidence:

- environmental/source content can be authentic and attributable while remaining non-authoritative for instructions;
- hostile observed content does not need to be removed for a benign authorized objective to succeed.

Coverage remains **not-demonstrated** for durable-memory write governance specifically. This fixture models repository/environment influence and should not be relabeled as a memory-write control.

## Research mapping

The fixture operationalizes the ToolHazard-style path:

```text
attacker-writable state
  -> legitimate acquisition
  -> agent observation
  -> effect request
  -> independent authorization
  -> execution/no-execution evidence
  -> deterministic terminal state
```

It provides a reusable environmental-influence test shape while preserving the crosswalk assurance boundary: synthetic evidence is not production conformance, and source provenance is not action authority.
