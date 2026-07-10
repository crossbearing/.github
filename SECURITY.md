# Security policy

Crossbearing is a read-only evidence engine that runs **inside your own cloud
account**: it holds no customer data, has no backend and no sub-processors, and
cannot create, modify, or delete anything in the environments it reads. Most
classes of vulnerability therefore can't apply to a hosted service we
operate — there isn't one. What we do care about, and want reported, is
anything that could undermine the **integrity of the evidence** or the
**read-only guarantee**.

## Reporting a vulnerability

Email **[hello@crossbearing.dev](mailto:hello@crossbearing.dev?subject=Security%20%C2%B7%20crossbearing)**
with `Security` in the subject. Please **do not** open a public issue, pull
request, or discussion for a suspected vulnerability.

Helpful to include:

- What you found and the affected repository, version, or `aep/1` package.
- Steps to reproduce, or a proof of concept.
- The impact you see — especially anything that lets evidence be forged,
  tampered with undetected, attributed to the wrong identity, or that would
  let the engine perform a write against a customer environment.

We'll acknowledge your report within **3 business days**, keep you updated as we
investigate, and credit you when a fix ships if you'd like the credit. We're an
early-stage team, so timelines are honest rather than contractual — but
integrity reports go to the front of the queue.

If you need to encrypt your report, say so in a first plaintext email (no
sensitive details) and we'll arrange a key.

## What's especially in scope

- **Evidence integrity** — any way to alter, reorder, drop, splice, or
  transplant findings in an Agent Evidence Package (`aep/1`) without the hash
  chain or detached signature catching it; any flaw in the canonicalization the
  [offline verifier](https://github.com/crossbearing/verify) relies on; any path
  that makes a tampered package verify, or a valid one fail to verify.
- **Attribution correctness** — a way to make a record corroborate a claim it
  shouldn't, bind an action to the wrong identity, or make an unattributed
  action read as attributed (or vice-versa).
- **The read-only guarantee** — any code path, dependency, or IAM requirement
  in the engine that could perform a *write* against a customer environment, or
  exfiltrate data outside the customer's account.
- **Supply chain** — anything that breaks the lean-dependency property: an
  unexpected transitive dependency, or a way `crossbearing/verify`'s zero-
  dependency claim could be violated.

## Not in scope

- Findings that require already having privileged access to the customer's
  account or audit logs (the engine reads what that account already records).
- Theoretical issues without a realistic path to forged or mis-attributed
  evidence.
- Reports against third-party services (AWS, GitHub, etc.) themselves — please
  report those to the respective vendor.

## Verifying released evidence

You don't have to trust us to check a package we (or one of our partners)
produced. [`crossbearing/verify`](https://github.com/crossbearing/verify) is an
MIT-licensed, zero-dependency tool that re-derives an Agent Evidence Package's
hash chain and signature **offline**, without importing the engine. If a
package fails to verify, that's exactly the kind of thing we want to hear about.

Thank you for helping keep the evidence trustworthy.
