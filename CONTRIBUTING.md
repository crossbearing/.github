# Contributing

The org-wide ground rules for contributing to any crossbearing repository.
Individual repos may add their own `CONTRIBUTING.md` with domain-specific
contracts — those build on this document, they don't replace it.

Before you start, read [`SUPPORT.md`](./SUPPORT.md) if what you have is a
question rather than a change, and [`SECURITY.md`](./SECURITY.md) if what you
found is a vulnerability. Neither belongs in a public issue.

## The two properties a contribution must not break

Crossbearing sells trustworthiness, so two properties are load-bearing in a way
that outranks any feature. A change that weakens either is not a trade-off we
make; it's a change we don't ship.

**Read-only by architecture.** The engine reads — audit logs, IAM trust
policies, exports the customer provides — and signs with a key the customer
names. It cannot create, modify, or delete anything in a customer environment.
A pull request that adds a write-capable API call, widens an IAM policy beyond
read and `kms:Sign`, or takes a dependency that could write, needs to justify
itself before anything else about it gets reviewed. "It's only used for X" is
not a justification: the guarantee is architectural, not behavioral.

**A lean supply chain.** [`crossbearing/verify`](https://github.com/crossbearing/verify)
has **zero** dependencies — the Go standard library is its entire supply chain,
and its CI fails if `go.sum` so much as exists. That is a product property: a
counterparty can audit the verifier in an afternoon. The engine's tree is a
single upstream vendor (AWS SDK + smithy), all Apache-2.0. Adding a dependency
to either is a real decision with a written reason, not a convenience.

Both properties are also what we ask the outside world to report against — see
the in-scope list in [`SECURITY.md`](./SECURITY.md). Holding ourselves to a
lower bar than we invite others to test us against would be its own kind of
unverified claim.

## Workflow

- Every change lands through a pull request — including changes by maintainers,
  and including this repository. On the four public repositories that rule is
  enforced by branch protection on `main`. On the private ones it is convention:
  GitHub gates branch protection for private repositories behind a paid plan,
  so the rule is currently held by discipline rather than by the platform.
  Stating it the other way round would put a bar in this file that the org does
  not actually meet, which is the failure this document warns about two
  sections up.
- Merges are squash-merges that preserve the authored commit message. Write the
  commit message as the permanent record — what changed and *why*; the diff
  already shows what. Keep the PR description short and link issues there.
- CI must be green before merge. That includes failures you didn't cause: a red
  check on `main` is everyone's problem, and merging past it just moves the
  cost onto the next person.
- Keep pull requests focused. One argument per PR reviews faster than three.

## Voice

Docs and commit messages are plain English, technical, unhurried. Describe the
state of the design — what the system *is* — rather than narrating how it got
there. Prefer the concrete claim with evidence behind it over the confident
adjective; that's the whole product thesis, and it applies to our own prose.

## Before adding a community health file to a repository

The files in [`crossbearing/.github`](https://github.com/crossbearing/.github) —
this one, the security policy, the code of conduct, the support routing, the
issue and PR templates — are served by GitHub as the default for every
repository in the organization that does not ship its own copy.

A repository that adds its own copy **replaces** the inherited file entirely.
GitHub has no mechanism for extending one: there is no `extends`, no merge, no
composition. The moment a repo ships its own `SECURITY.md`, the org-level policy
stops applying to it, and the new file has to carry everything the old one did —
including the parts nobody remembers are in there.

That is how a fork nobody maintains gets created by someone trying to be
helpful. The org policy is doing real work for the repos that don't shadow it:
it names the offline verifier, the canonicalization concern, and the
false-accept severity model, and a repo-level rewrite that omits any of those
silently narrows the scope of what people are invited to report.

So: prefer a pointer to the org file over a copy of it. Ship a repository-level
version only when that repository genuinely needs something the org-wide one
cannot say, and when you do, carry the whole thing across deliberately rather
than starting fresh.

## Reporting a bug

Open an issue with what you ran, what you saw, and what you expected instead.
For anything touching evidence integrity, attribution correctness, or the
read-only guarantee, use [`SECURITY.md`](./SECURITY.md) rather than filing
publicly — even if you're not sure it qualifies.
