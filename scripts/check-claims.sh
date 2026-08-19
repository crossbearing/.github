#!/usr/bin/env bash
# Re-derives the externally checkable claims this repository makes. Everything
# here is prose and links, so the characteristic failure is not a crash — it is
# a sentence that was true when written and quietly stopped being true.
#
# Exits non-zero on the first category that fails, after reporting every failure
# in that category. Runs locally with no arguments; needs `gh` authenticated for
# the sibling-repo assertions.
set -uo pipefail

fail_count=0
note() { printf '  %-58s %s\n' "$1" "$2"; }
fail() { note "$1" "FAIL — $2"; fail_count=$((fail_count + 1)); }
pass() { note "$1" "ok"; }

# ── Links ────────────────────────────────────────────────────────────────────
# Every http(s) URL in every tracked Markdown file must resolve. mailto: is
# skipped (nothing to resolve); relative links are checked as paths on disk.
echo "Links"
urls=$(git ls-files '*.md' 'llms.txt' \
  | xargs grep -ohE 'https?://[^][ ()<>"`]+' \
  | sed -e 's/[.,;:]*$//' -e 's/\\$//' \
  | sort -u)

while IFS= read -r url; do
  [ -z "$url" ] && continue
  code=$(curl -sS -o /dev/null -w '%{http_code}' -L --max-time 20 --retry 2 --retry-delay 2 "$url" 2>/dev/null || echo 000)
  case "$code" in
    2*|3*) pass "$url" ;;
    *)     fail "$url" "HTTP $code" ;;
  esac
done <<< "$urls"

# Relative Markdown links must point at something that exists.
echo "Relative paths"
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  target=${ref%%#*}
  [ -z "$target" ] && continue
  if [ -e "$target" ]; then pass "$target"; else fail "$target" "no such file"; fi
done <<< "$(git ls-files '*.md' | xargs grep -ohE '\]\(\./[^)]+\)' \
             | sed -e 's/^](\.\///' -e 's/)$//' | sort -u)"

if [ "$fail_count" -gt 0 ]; then
  echo
  echo "$fail_count link/path claim(s) failed."
  exit 1
fi

# ── Claims about sibling repositories ────────────────────────────────────────
# These are the assertions this repo makes about repositories it does not own,
# which is exactly where drift is invisible from inside.
echo "Sibling repository claims"

check_license() {
  local repo=$1 want=$2
  local got
  # gh writes its error payload to stdout, so `|| echo ERROR` would leave the
  # payload in $got rather than replacing it. Branch on the exit status.
  if ! got=$(gh api "repos/$repo/license" -q '.license.spdx_id' 2>/dev/null); then got="ERROR"; fi
  if [ "$got" = "$want" ]; then pass "$repo licence is $want"
  else fail "$repo licence" "expected $want, got $got"; fi
}

check_license crossbearing/verify MIT
check_license crossbearing/scenarios MIT

# The engine is FSL 1.1, which is not an OSI licence — GitHub reports it as
# NOASSERTION. Asserting the string keeps us honest if it is ever relicensed.
check_license crossbearing/crossbearing NOASSERTION

# verify's zero-dependency property: no go.sum, and no require block in go.mod.
# This is a product property, not a preference — CONTRIBUTING.md and llms.txt
# both state it, and verify's own CI enforces it from the inside.
if gh api repos/crossbearing/verify/contents/go.sum >/dev/null 2>&1; then
  fail "crossbearing/verify has no go.sum" "go.sum exists — the supply chain is no longer just the stdlib"
else
  pass "crossbearing/verify has no go.sum"
fi

if ! gomod=$(gh api repos/crossbearing/verify/contents/go.mod -q '.content' 2>/dev/null | base64 -d 2>/dev/null); then gomod=""; fi
if [ -z "$gomod" ]; then
  fail "crossbearing/verify go.mod readable" "could not fetch go.mod"
elif grep -qE '^\s*require' <<< "$gomod"; then
  fail "crossbearing/verify declares no requires" "go.mod has a require directive"
else
  pass "crossbearing/verify declares no requires"
fi

# Paths this repo points a reader at by name.
check_path() {
  local repo=$1 path=$2
  if gh api "repos/$repo/contents/$path" >/dev/null 2>&1; then pass "$repo:$path exists"
  else fail "$repo:$path" "not found"; fi
}
check_path crossbearing/crossbearing demo/run.sh

# ── The security policy against the actual repository settings ───────────────
# SECURITY.md states that private vulnerability reporting is enabled on every
# public crossbearing repository. That is an assertion about a setting, and a
# setting can be flipped back without anyone touching the policy that describes
# it — the exact claim-versus-record divergence this organization sells the
# detection of. Checking our own is the cheapest possible act of consistency.
#
# Public repos are enumerated rather than hardcoded, so a new public repository
# that ships without private reporting fails this gate instead of silently
# making the published policy wrong.
echo "Security policy vs. repository settings"

# Branch on exit status, never on emptiness: gh prints its error payload to
# stdout, so a failed call yields non-empty garbage that would otherwise be
# looped over as if it were repo names. An unverifiable claim fails here; it
# does not quietly pass.
if ! public_repos=$(gh api --paginate 'orgs/crossbearing/repos?type=public' \
     -q '.[] | select(.archived == false) | .name' 2>/dev/null); then
  public_repos=""
fi

if [ -z "$public_repos" ]; then
  fail "enumerate public crossbearing repos" "could not list them — an unverifiable claim is a failed claim"
else
  while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    if ! enabled=$(gh api "repos/crossbearing/$repo/private-vulnerability-reporting" -q '.enabled' 2>/dev/null); then enabled="ERROR"; fi
    if [ "$enabled" = "true" ]; then
      pass "crossbearing/$repo private reporting enabled"
    else
      fail "crossbearing/$repo private reporting" "SECURITY.md says every public repo has it; this one reports '$enabled'"
    fi
  done <<< "$public_repos"
fi

echo
if [ "$fail_count" -gt 0 ]; then
  echo "$fail_count claim(s) failed. Correct the claim, or correct this check —"
  echo "but do not add an exception that lets a false statement pass."
  exit 1
fi
echo "All claims re-derived successfully."
