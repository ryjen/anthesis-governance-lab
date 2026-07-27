# Five-Minute Governance Lab Demo

## Goal

Show deterministic policy evaluation for AI-assisted software work without implying that this repository executes declared effects.

## 1. Acquire and verify the evaluator

From a fresh clone:

```bash
git clone https://github.com/ryjen/anthesis-governance-lab.git
cd anthesis-governance-lab
export GITHUB_TOKEN=...
bash scripts/acquire-anthesis-lab.sh
export PATH="$PWD/.anthesis/bin:$PATH"
anthesis-lab version --format json | jq .
```

The current acquisition path uses a checksum-pinned promoted artifact. Issue #4 tracks replacement with an anonymously downloadable immutable public release.

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
  "pack_count": 4,
  "passed_packs": 4,
  "total_scenarios": 12
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

## 5. State the enforcement boundary

Anthesis proves that a pinned declaration, policy, runtime profile, and scenario expectation produce a deterministic decision and report.

This repository does not write files, access networks, merge branches, publish releases, persist approvals, or prevent an agent from using an ungoverned tool. Production enforcement requires a governed executor, gateway, broker, supervisor boundary, sandbox, or equivalent control that makes Anthesis decisions authoritative.
