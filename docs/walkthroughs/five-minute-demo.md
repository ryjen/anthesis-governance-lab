# Five-Minute Governance Lab Demo

## Goal

Show deterministic policy evaluation for AI-assisted software work without implying that this repository executes declared effects.

This short walkthrough intentionally covers the **7-scenario canonical governance contract** and the **9 general demo packs / 27 scenarios**. It does not attempt to present all 24 inference-integrity cases. Use the [inference-integrity runbook](../runbooks/inference-integrity-demo.md) for that extension or the [full verification runbook](../runbooks/full-verification.md) to reproduce every proof surface.

## 1. Acquire and verify the evaluator

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
anthesis-lab version --format json | jq .
```

Acquisition is anonymous and verifies the immutable public release, Sigstore identity, provenance, archive and binary checksums, CLI identity, and supported contracts before installation.

## 2. Run the canonical contract suite

```bash
bash scripts/validate-governance-lab.sh
```

Expected summary:

```text
Canonical suite: 7 passed, 0 failed
Intentional governance drift: detected with exit code 7
```

## 3. Run all themed demo packs

```bash
bash scripts/aggregate-demo-packs.sh | tee /tmp/anthesis-demo-packs.json | jq '{classification, pack_count, passed_packs, total_scenarios}'
```

Expected result:

```json
{
  "classification": "passed",
  "pack_count": 9,
  "passed_packs": 9,
  "total_scenarios": 27
}
```

## 4. Show the five-case showcase

```bash
jq -r '.entries[] | [.id, .kind, (.path // .command)] | @tsv' docs/walkthroughs/showcase.json
```

The showcase covers:

1. scoped documentation write allowed;
2. CI workflow change requiring approval;
3. direct merge denied by policy;
4. unknown runtime denied by an engine guard;
5. deliberate expectation drift detected with evaluator exit code `7`.

For a security-focused extension, run:

```bash
bash scripts/run-demo-pack.sh secrets-and-evidence | jq .
bash scripts/run-demo-pack.sh runtime-and-identity | jq .
bash scripts/run-demo-pack.sh adversarial | jq .
```

The adversarial pack shows that policy-bypass wording, absolute host paths, and unrestricted command requests do not expand capability.

## 5. Optional inference-integrity extension

If the audience needs the inference-integrity proof surface, show the aggregate 24-case result rather than walking every fixture:

```bash
.anthesis/bin/anthesis-lab inference-integrity --repo . --format json |
  jq '{passed, total, passed_count, failed_count}'
```

Expected result is 24 passed and zero failed. A useful representative scenario is `detect-token-substitution`; the dedicated runbook explains the remaining verification classes, routes, supervisor/specialist cases, operating modes, and controlled mismatch.

## 6. State the enforcement boundary

Anthesis proves that a pinned declaration, policy, runtime profile, and scenario expectation produce a deterministic decision and report. The inference-integrity extension likewise evaluates recorded provider-neutral evidence deterministically.

This repository does not write files, run commands, access networks, merge branches, deploy software, publish releases, persist approvals, invoke live providers, or prevent an agent from using an ungoverned tool. Production enforcement requires a governed executor, gateway, broker, supervisor boundary, sandbox, or equivalent control that makes Anthesis decisions authoritative.
