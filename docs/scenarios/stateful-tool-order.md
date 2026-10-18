# Stateful tool-order composition (issue #99)

This bounded, synthetic, provider-neutral fixture checks whether a **completed trusted structured lookup** precedes an independently authorized proposed write and matches the exact lookup revision.

- `lookup-then-write`: positive sequence with completed trusted lookup and matching revision.
- `write-before-lookup`: the same proposed write cannot rely on a future lookup.
- `forged-history`: a claimed historical lookup is not a verified completed step.

Run `bash scripts/validate-stateful-tool-order.sh` and `bash scripts/test-stateful-tool-order.sh`. The negative oracle rejects nine mutations. The suite also runs through `scripts/validate-external-security-fixtures.sh`.

The fixture **proves only internal consistency of declared synthetic sequence records**. It does not authenticate real lookup sources, prove independent write authorization, mediate real tools, observe actual effects, or establish concurrency/restart safety. `expected` is checked against the fixture-derived verdict, not against a separately implemented runtime security control. No network, credentials, live model or protected effect is used.

This is the first bounded pair under #99. Remaining candidates (bound values, deferred source, commit/recovery, semantic judge) are not implemented here. Anthesis owns actual policy and effect-time semantics; Dubnium owns runtime adapter qualification.
