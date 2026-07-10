<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/crossbearing/.github/main/profile/assets/mark-dark.svg">
  <img alt="Crossbearing — three bearing lines crossing around a fix" src="https://raw.githubusercontent.com/crossbearing/.github/main/profile/assets/mark.svg" width="112" height="112">
</picture>

### What your AI agents did&nbsp;&nbsp;·&nbsp;&nbsp;vs. what they said

**A read-only evidence engine that runs in your own cloud account.**

[crossbearing.dev](https://crossbearing.dev) &nbsp;·&nbsp; [the offline verifier](https://github.com/crossbearing/verify) &nbsp;·&nbsp; [become a design partner](mailto:hello@crossbearing.dev?subject=crossbearing%20%C2%B7%20design%20partner)

</div>

---

Crossbearing corroborates what your AI agents **claim** they did against the
records your infrastructure already keeps — CloudTrail, GCP and Azure audit
logs, Kubernetes audit, GitHub audit — and surfaces the divergence as
auditor-ready, signed evidence. Nothing installs in the agent path; one
read-only role connects it.

> A *cross bearing* fixes a navigator's true position from independent
> reference lines. Three bearings never meet at a single point — the truth
> lives inside the small triangle they enclose, the **cocked hat**. One claim
> is a story; corroborated against records the agent doesn't control, it
> becomes a position fix.

### What it produces

- **The divergence report** — every agent action joined claim-side to
  record-side and labelled: corroborated, mismatched, claimed-but-unrecorded,
  or recorded-but-unattributed. The headline finding is usually the last one:
  real accounts are anonymous by default.
- **The Agent Evidence Package** (`aep/1`) — findings hash-chained from a
  genesis anchored to the report window and match policy, signed with **your**
  KMS key, mapped to SOC 2 CC and ISO 42001 Annex A controls. Edit, reorder, or
  drop one finding and every downstream hash changes and the signature stops
  verifying.
- Every finding carries **provenance** — a re-fetchable locator and a digest.
  Nothing is asserted; everything re-derives. Explainable to an auditor beats
  clever.

### Why it's trustworthy

- **Read-only by architecture.** The engine can only read (CloudTrail, IAM
  trust policies, audit-log exports you provide) and sign with a key you name.
  It cannot create, modify, or delete anything in your account.
- **Your data never leaves your account.** No backend, no sub-processors, no
  stored customer data — everything happens inside your trust boundary.
- **Independently verifiable.** Evidence is only evidence if a counterparty can
  check it *without* trusting — or even contacting — whoever emitted it.
  [`crossbearing/verify`](https://github.com/crossbearing/verify) is an
  MIT-licensed, **zero-dependency** offline verifier that never imports the
  engine. Re-derive any package's hash chain and signature on your own machine.
- **A lean supply chain is a product property.** The engine's dependency tree
  is a single upstream vendor (AWS SDK + smithy), all Apache-2.0 — short enough
  that a buyer can actually review the SBOM.

### Where to look

- 🌐 **[crossbearing.dev](https://crossbearing.dev)** — the product, and the
  five-minute divergence demo.
- 🔎 **[crossbearing/verify](https://github.com/crossbearing/verify)** — the
  public, zero-dependency Agent Evidence Package verifier (MIT). Start here if
  you've been handed a package and want to check it.

### Become a design partner

We're working with a small number of AI-product teams under SOC 2 / ISO 42001 /
customer-security-review pressure who want evidence of what their agents
*actually did*, not just what they said.

**→ [hello@crossbearing.dev](mailto:hello@crossbearing.dev?subject=crossbearing%20%C2%B7%20design%20partner)** &nbsp;·&nbsp; or take a fix from [crossbearing.dev](https://crossbearing.dev).

<sub>Security: see the [security policy](https://github.com/crossbearing/.github/blob/main/SECURITY.md). Found something? Report it privately to <a href="mailto:hello@crossbearing.dev?subject=Security%20%C2%B7%20crossbearing">hello@crossbearing.dev</a>.</sub>
