#!/usr/bin/env python3
"""Verify lab fixtures exactly match the pinned public governance contract."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[1]
REFERENCE_FILE = ROOT / ".anthesis" / "contract-reference.yaml"
CONTRACT_CHECKOUT = ROOT / ".contract"


def load_yaml(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return yaml.safe_load(handle)


def main() -> int:
    errors: list[str] = []
    reference = load_yaml(REFERENCE_FILE)

    if reference.get("version") != "anthesis.contract-reference/v1":
        errors.append("unsupported contract reference version")

    expected_repository = "hackelia-micrantha/anthesis-community"
    expected_revision = "7f6cdd59c640d38a2e951032ca5c9a1707b696f2"
    expected_path = "specs/governance-lab"

    if reference.get("repository") != expected_repository:
        errors.append(f"contract repository must be {expected_repository}")
    if reference.get("revision") != expected_revision:
        errors.append(f"contract revision must be {expected_revision}")
    if reference.get("path") != expected_path:
        errors.append(f"contract path must be {expected_path}")

    contract_root = CONTRACT_CHECKOUT / expected_path
    comparisons = [
        (
            ROOT / ".anthesis" / "policies" / "local-sdlc.yaml",
            contract_root / "examples" / "local-sdlc.policy.yaml",
            "policy",
        ),
        (
            ROOT / ".anthesis" / "runtime-profile.yaml",
            contract_root / "examples" / "local.runtime-profile.yaml",
            "runtime profile",
        ),
    ]

    for local_path, canonical_path, label in comparisons:
        if not canonical_path.exists():
            errors.append(f"missing canonical {label}: {canonical_path}")
            continue
        if load_yaml(local_path) != load_yaml(canonical_path):
            errors.append(f"local {label} differs from pinned canonical fixture")

    vectors_path = contract_root / "conformance-vectors.yaml"
    if not vectors_path.exists():
        errors.append(f"missing canonical conformance vectors: {vectors_path}")
    else:
        vectors = load_yaml(vectors_path)
        canonical_scenarios = {
            scenario["id"]: scenario for scenario in vectors.get("scenarios", [])
        }
        local_scenarios: dict[str, Any] = {}
        for path in sorted((ROOT / ".anthesis" / "scenarios").glob("*.yaml")):
            scenario = load_yaml(path)
            local_scenarios[scenario["id"]] = scenario

        if set(local_scenarios) != set(canonical_scenarios):
            errors.append(
                "local scenario IDs differ from pinned canonical vectors: "
                f"local={sorted(local_scenarios)}, canonical={sorted(canonical_scenarios)}"
            )
        for scenario_id in sorted(set(local_scenarios) & set(canonical_scenarios)):
            if local_scenarios[scenario_id] != canonical_scenarios[scenario_id]:
                errors.append(f"scenario {scenario_id} differs from pinned canonical vector")

    if errors:
        print("Governance contract synchronization failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        "Governance lab policy, runtime profile, and seven scenarios match "
        f"{expected_repository}@{expected_revision}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
