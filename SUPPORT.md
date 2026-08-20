# Support

Where to take a question, sorted by what kind of question it is. Everything
here is public and best-effort except the security channel, which is private
and prioritized.

## I think I found a vulnerability

Don't open an issue. Email
[hello@crossbearing.dev](mailto:hello@crossbearing.dev?subject=Security%20%C2%B7%20crossbearing)
with `Security` in the subject and read [`SECURITY.md`](./SECURITY.md) for
what's in scope and what we do next. If you're unsure whether it qualifies,
email anyway — sorting that out is our job, not yours.

## I was handed an Agent Evidence Package and want to check it

Start with [`crossbearing/verify`](https://github.com/crossbearing/verify) —
an MIT-licensed, zero-dependency offline verifier that re-derives a package's
hash chain and signature without contacting us or importing the engine. That's
the point of it: you don't have to trust the party that emitted the evidence,
including us.

If a package that should verify doesn't, or one that shouldn't verify does,
that's a security report — see above.

## Something is broken

Open an issue on the repository where it broke:

- [`crossbearing/crossbearing`](https://github.com/crossbearing/crossbearing/issues)
  — the engine.
- [`crossbearing/verify`](https://github.com/crossbearing/verify/issues) — the
  offline verifier.
- [`crossbearing/scenarios`](https://github.com/crossbearing/scenarios/issues)
  — the named divergence scenarios.
- [`crossbearing/.github`](https://github.com/crossbearing/.github/issues) —
  the org profile, this file, and the other org-wide defaults.

Include what you ran, what you saw, and what you expected. The bug template
asks for exactly that.

## I have a question about how it works

The engine's `./demo/run.sh` shows a full divergence report offline in about
five seconds, and [`crossbearing/scenarios`](https://github.com/crossbearing/scenarios)
walks named agent misbehaviors end to end — the evidence, the finding, the fix,
and the proof re-run. Between them they answer most "but what does it actually
do" questions faster than we can in prose.

If they don't, open an issue on the relevant repo and ask. A question that
needed asking is usually a docs bug.

## I want to use this at my company

[crossbearing.dev](https://crossbearing.dev) has the product and the
five-minute demo. We're working with a small number of design partners under
SOC 2 / ISO 42001 / customer-security-review pressure — if that's you, email
[hello@crossbearing.dev](mailto:hello@crossbearing.dev?subject=crossbearing%20%C2%B7%20design%20partner).

## What we don't promise

We're an early-stage team. Response times on public issues are honest rather
than contractual, and there is no support SLA attached to anything in this
document. Security reports are the exception and go to the front of the queue —
acknowledged within three business days.
