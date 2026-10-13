#!/usr/bin/env python3
"""Synthetic in-memory effect witness. No network, credentials or external effects."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
fixture = json.loads((ROOT / "fixtures/external-security/effect-path-closure-v1.json").read_text())
assert fixture["synthetic"] and not fixture["executes_effects"]
effects = fixture["effects"]
authorizations = fixture["authorizations"]
paths = fixture["paths"]

def run_case(case):
    """Compute effects from modeled reachability and authorization, never expected_verdict."""
    journal = []
    path = paths[case["path"]]
    auth = authorizations.get(case["authorization_ref"])
    mediated = path["path_class"] == "mediated" and path["requires_enforcement_boundary"]
    reachable = path["expected_reachability"] == "reachable"
    authorized = (auth is not None and auth["state"] == "active"
                  and auth["effect"] == case["requested_effect"]
                  and auth["executor_identity"] == "executor_primary")
    boundary = case["enforcement_boundary_available"] and case["enforcement_boundary_observed"]
    if reachable and mediated and authorized and boundary:
        journal.append({"effect": case["requested_effect"], "target": effects[case["requested_effect"]]["target"]})
    return journal

for case in fixture["cases"]:
    observed = run_case(case)
    expected_count = 1 if case["expected_verdict"] == "allow" else 0
    assert len(observed) == expected_count, (case["id"], observed)
    assert len(observed) == case["effect_count"], case["id"]
    assert bool(observed) == case["executor_observed"], case["id"]
print(f"effect-witness: {len(fixture['cases'])} synthetic cases independently computed; no external effects")
