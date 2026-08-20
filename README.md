# crossbearing/.github

Organization-level community health files for
[**crossbearing**](https://crossbearing.dev). GitHub serves everything here as
the default for every repository in the organization that doesn't ship its own
copy, so a change in this repo changes the front door of all of them.

## The public profile

- [`profile/README.md`](./profile/README.md) — the org profile shown at
  [github.com/crossbearing](https://github.com/crossbearing). What crossbearing
  is, and where to go next, lives there rather than being repeated here.
- [`profile/assets/`](./profile/assets/README.md) — the mark and avatar
  artwork, and which surface each file feeds.

## The org-wide defaults

- [`SECURITY.md`](./SECURITY.md) — how to report a vulnerability, what's in
  scope, and what we do about it.
- [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) — Contributor Covenant 2.1, and
  how to report a conduct concern privately.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — the ground rules for changing any
  crossbearing repository, including the two product properties a contribution
  must not break.
- [`SUPPORT.md`](./SUPPORT.md) — where to take a question, sorted by what kind
  of question it is.
- [`.github/ISSUE_TEMPLATE/`](./.github/ISSUE_TEMPLATE) and
  [`.github/PULL_REQUEST_TEMPLATE.md`](./.github/PULL_REQUEST_TEMPLATE.md) —
  the default issue and PR forms.
- [`llms.txt`](./llms.txt) — the same map, machine-readable, for agents reading
  the organization rather than people.

## Tooling served to the organization

- [`default.json`](./default.json) — the shared Renovate preset. Repositories
  consume it with a one-line `renovate.json`:
  `{"extends": ["github>crossbearing/.github"]}`. Its `description` fields carry
  the hazards a future editor needs before changing it.
- [`renovate.json`](./renovate.json) — this repository consuming its own preset.

## Checking this repo

Everything here is prose, links and configuration, so the failure mode is drift:
a claim that was true when written and quietly stopped being true.

- [`scripts/check-claims.sh`](./scripts/check-claims.sh) re-derives the
  externally checkable claims — every link resolves, the licences are what we
  say they are, `crossbearing/verify` still has no dependencies, and the
  security policy matches the repositories' actual settings. It asserts a floor
  on what it examined and reports the count, so a run that scanned nothing fails
  instead of passing.
- [`scripts/test-check-claims.sh`](./scripts/test-check-claims.sh) tests that
  checker against stubbed `gh` and `curl`, including the cases where both write
  diagnostics to stdout while exiting non-zero.
- [`.github/workflows/claims.yml`](./.github/workflows/claims.yml) runs both on
  every pull request and again weekly, because drift in repositories this one
  does not own arrives with no commit here to trigger a check.
- [`.github/workflows/renovate-config.yml`](./.github/workflows/renovate-config.yml)
  validates the preset. A malformed preset makes Renovate error on the consuming
  repository rather than falling back to defaults, so a typo here stops
  dependency updates across the organization at once.

When a check goes red, the fix is usually to correct the claim rather than to
restore the world — the gate is reporting that the docs drifted from reality,
and reality is generally the part that is right. If the claim is correct and the
check is wrong, fix the check in the same pull request rather than adding an
exception that lets a false statement pass.
