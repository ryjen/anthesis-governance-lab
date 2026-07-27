# Micrantha architecture context

Anthesis Governance Lab is a **Laboratory testbed** within the [Micrantha ecosystem](https://github.com/hackelia-micrantha). It is not itself the deployable governance product or an agent execution environment.

The architectural roles are intentionally separate:

- **Anthesis** is the governance and provenance Solution under test.
- **Dubnium** is Micrantha's reproducible, local-first distribution for agentic development and bounded execution.
- **Anthesis Governance Lab** independently validates public Anthesis contracts, deterministic policy decisions, canonical scenarios, and evaluator compatibility.
- The **Dubnium Governed Agent Demo** exercises the public Governance Lab contract and Anthesis evaluator boundary through Dubnium's bounded execution path to demonstrate an end-to-end governed-agent slice.

Governance Lab remains independently runnable and does not depend on Dubnium. Its role is to make the governance boundary reproducible before that boundary is embedded in an agentic system. The Dubnium integration consumes the public contract and evaluator interface; it does not require direct access to this repository's fixture tree.

Some implementations and reference integrations currently remain under [`ryjen`](https://github.com/ryjen) while repository ownership is consolidated into Micrantha. The accepted public contract and immutable evaluator distribution already live under [`hackelia-micrantha/anthesis-community`](https://github.com/hackelia-micrantha/anthesis-community).

Related public boundaries:

- [Dubnium community and distribution](https://github.com/hackelia-micrantha/dubnium-community)
- [Anthesis public contracts and releases](https://github.com/hackelia-micrantha/anthesis-community)
- [Micrantha organization profile](https://github.com/hackelia-micrantha)
