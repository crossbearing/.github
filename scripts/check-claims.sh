#!/usr/bin/env bash
# Re-derives the externally checkable claims this repository makes. Everything
# here is prose and links, so the characteristic failure is not a crash — it is
# a sentence that was true when written and quietly stopped being true.
#
# Two rules govern this script, both learned from defects found in it:
#
#   1. Branch on exit status, never on empty output. `gh api` and `curl` both
#      write diagnostics to stdout, so `cmd || echo FALLBACK` leaves the
#      diagnostic in the variable rather than replacing it.
#   2. A check that examined nothing has learned nothing, and must never look
#      like a pass. Every extraction asserts a floor; falling under it is a
#      failure, not a quiet green.
set -uo pipefail

# This repo, for detecting self-referential links. A blob/main URL pointing at
# a file in this very repository is checked against the working tree, not over
# HTTP: on a pull request that adds the file, it does not exist at
# refs/heads/main yet, and HTTP-checking it would fail a correct change.
SELF_REPO="crossbearing/.github"
SELF_BLOB="https://github.com/${SELF_REPO}/blob/main/"

# Floors. Raise these when the repo grows; under-counting is how an extraction
# that silently stopped matching turns this gate green.
MIN_MD_FILES=3
MIN_URLS=8

fail_count=0
note() { printf '  %-58s %s\n' "$1" "$2"; }
fail() { note "$1" "FAIL — $2"; fail_count=$((fail_count + 1)); }
pass() { note "$1" "ok"; }

# ── Inventory ────────────────────────────────────────────────────────────────
# Printed so a run proves it examined something. A step that silently scanned
# zero files is a vacuous pass wearing the costume of a green check.
md_files=$(git ls-files '*.md' 'llms.txt')
md_count=$(printf '%s\n' "$md_files" | grep -c . || true)
echo "Inventory"
note "markdown/llms files found" "$md_count"
if [ "$md_count" -lt "$MIN_MD_FILES" ]; then
  fail "file discovery" "found $md_count, floor is $MIN_MD_FILES — discovery is broken, not the docs"
  echo; echo "Refusing to report on a scan that examined nothing."; exit 1
fi

# ── Links ────────────────────────────────────────────────────────────────────
echo "Links"
urls=$(printf '%s\n' "$md_files" | xargs grep -ohE 'https?://[^][ ()<>"`]+' \
  | sed -e 's/[.,;:]*$//' -e 's/\\$//' | sort -u)
url_count=$(printf '%s\n' "$urls" | grep -c . || true)
note "unique URLs extracted" "$url_count"
if [ "$url_count" -lt "$MIN_URLS" ]; then
  fail "URL extraction" "found $url_count, floor is $MIN_URLS — extraction is broken, not the docs"
  echo; echo "Refusing to report on a scan that examined nothing."; exit 1
fi

while IFS= read -r url; do
  [ -z "$url" ] && continue

  # Self-referential blob/main link: resolve against the working tree. This is
  # the state that will be true once merged, which is what we actually mean.
  case "$url" in
    "$SELF_BLOB"*)
      rel=${url#"$SELF_BLOB"}; rel=${rel%%#*}
      if [ -e "$rel" ]; then pass "$url (self, on disk)"
      else fail "$url" "self-referential link to a path not in this tree: $rel"; fi
      continue ;;
  esac

  code=$(curl -sS -o /dev/null -w '%{http_code}' -L --max-time 20 --retry 2 --retry-delay 2 "$url" 2>/dev/null)
  rc=$?
  if [ "$rc" -ne 0 ]; then
    # A transfer that dies after the response line still prints an http_code,
    # so `|| echo 000` would concatenate rather than replace and a 2xx prefix
    # would read as ok. The exit status is the authority.
    fail "$url" "curl exit $rc (http_code=${code:-none})"
  else
    case "$code" in
      2*|3*) pass "$url" ;;
      *)     fail "$url" "HTTP $code" ;;
    esac
  fi
done <<< "$urls"

echo "Relative paths"
rels=$(printf '%s\n' "$md_files" | xargs grep -ohE '\]\(\./[^)]+\)' | sed -e 's/^](\.\///' -e 's/)$//' | sort -u)
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  target=${ref%%#*}
  [ -z "$target" ] && continue
  if [ -e "$target" ]; then pass "$target"; else fail "$target" "no such file"; fi
done <<< "$rels"

if [ "$fail_count" -gt 0 ]; then
  echo; echo "$fail_count link/path claim(s) failed."; exit 1
fi

# ── Claims about sibling repositories ────────────────────────────────────────
echo "Sibling repository claims"

check_license() {
  local repo=$1 want=$2 got
  if ! got=$(gh api "repos/$repo/license" -q '.license.spdx_id' 2>/dev/null); then got="ERROR"; fi
  if [ "$got" = "$want" ]; then pass "$repo licence is $want"
  else fail "$repo licence" "expected $want, got $got"; fi
}

check_license crossbearing/verify MIT
check_license crossbearing/scenarios MIT
# FSL 1.1 is not an OSI licence, so GitHub reports NOASSERTION. Asserting the
# string keeps us honest if the engine is ever relicensed.
check_license crossbearing/crossbearing NOASSERTION

# verify's zero-dependency property. Absence must be proven by a 404
# specifically — any other failure means we did not learn whether go.sum
# exists, and "did not learn" is not "is absent".
gosum_status=$(gh api repos/crossbearing/verify/contents/go.sum --silent -i 2>/dev/null | head -1 | grep -oE '[0-9]{3}' | head -1 || true)
if [ "$gosum_status" = "404" ]; then
  pass "crossbearing/verify has no go.sum"
elif [ "$gosum_status" = "200" ]; then
  fail "crossbearing/verify has no go.sum" "go.sum exists — the supply chain is no longer just the stdlib"
else
  fail "crossbearing/verify go.sum state" "could not determine (status '${gosum_status:-none}') — an unresolved check is not a pass"
fi

if ! gomod=$(gh api repos/crossbearing/verify/contents/go.mod -q '.content' 2>/dev/null | base64 -d 2>/dev/null); then gomod=""; fi
if [ -z "$gomod" ]; then
  fail "crossbearing/verify go.mod readable" "could not fetch go.mod"
elif grep -qE '^\s*require' <<< "$gomod"; then
  fail "crossbearing/verify declares no requires" "go.mod has a require directive"
else
  pass "crossbearing/verify declares no requires"
fi

check_path() {
  local repo=$1 path=$2
  if gh api "repos/$repo/contents/$path" >/dev/null 2>&1; then pass "$repo:$path exists"
  else fail "$repo:$path" "not found"; fi
}
check_path crossbearing/crossbearing demo/run.sh

# ── The security policy against the actual repository settings ───────────────
# Two assertions, deliberately distinct:
#
#   1. Every public repository has private vulnerability reporting enabled.
#      That is the posture the organization intends, and it is checkable today
#      whatever any file happens to say.
#   2. If SECURITY.md instructs reporters to use it, that instruction is true.
#      This is the claim-versus-record check proper. It engages only once the
#      policy makes the claim, so the check never describes itself as verifying
#      a sentence that does not exist yet.
echo "Security policy vs. repository settings"

# Archived repositories are excluded: they are read-only, so their setting
# cannot be changed and a red gate there would be permanent rather than
# actionable. The exclusion is named here so the check's scope is not wider in
# its title than in its body.
if ! public_repos=$(gh api --paginate 'orgs/crossbearing/repos?type=public' \
     -q '.[] | select(.archived == false) | .name' 2>/dev/null); then
  public_repos=""
fi
repo_count=$(printf '%s\n' "$public_repos" | grep -c . || true)
note "public non-archived repos found" "$repo_count"

pvr_all_enabled=1
if [ "$repo_count" -lt 1 ]; then
  fail "enumerate public crossbearing repos" "could not list them — an unverifiable claim is a failed claim"
  pvr_all_enabled=0
else
  while IFS= read -r repo; do
    [ -z "$repo" ] && continue
    if ! enabled=$(gh api "repos/crossbearing/$repo/private-vulnerability-reporting" -q '.enabled' 2>/dev/null); then enabled="ERROR"; fi
    if [ "$enabled" = "true" ]; then
      pass "crossbearing/$repo private reporting enabled"
    else
      fail "crossbearing/$repo private reporting" "expected enabled, got '$enabled'"
      pvr_all_enabled=0
    fi
  done <<< "$public_repos"
fi

if [ -f SECURITY.md ] && grep -qi 'private vulnerability reporting\|Report a vulnerability' SECURITY.md; then
  if [ "$pvr_all_enabled" -eq 1 ]; then
    pass "SECURITY.md points at private reporting, and it is enabled"
  else
    fail "SECURITY.md points at private reporting" "the policy names a channel that is not enabled everywhere"
  fi
else
  note "SECURITY.md does not yet name private reporting" "policy-vs-settings check inactive"
fi

echo
if [ "$fail_count" -gt 0 ]; then
  echo "$fail_count claim(s) failed. Correct the claim, or correct this check —"
  echo "but do not add an exception that lets a false statement pass."
  exit 1
fi
echo "All claims re-derived successfully ($url_count URLs, $md_count files, $repo_count repos)."
