#!/usr/bin/env bash
# Tests for check-claims.sh.
#
# The gate exists to catch what manual reading misses. It has itself shipped
# two defects that manual reading missed, both found only by deliberately
# making it fail. Each of those is a case below, so neither can come back
# quietly.
#
# Every case runs the real script against a throwaway git fixture, with `gh`
# and `curl` replaced by stubs on PATH. Nothing here touches the network or
# any real repository.
set -uo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
# Overridable so the suite can be pointed at a mutated copy, which is how we
# check that these cases actually fail when the gate is broken.
SCRIPT="${CHECK_SCRIPT:-$HERE/check-claims.sh}"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

tests_run=0
tests_failed=0
# A suite that ran no tests has learned nothing — the same rule the gate applies
# to itself. Raise this when cases are added.
MIN_CASES=10

# ── Stubs ────────────────────────────────────────────────────────────────────
# gh and curl both write diagnostics to stdout, which is what made the two real
# defects possible. The stubs reproduce that faithfully: on failure they print
# a payload *and* exit non-zero, so a script that reads stdout instead of the
# exit status will be fooled by them exactly as it was by the real tools.
make_stubs() {
  local bin=$1
  mkdir -p "$bin"

  cat > "$bin/gh" <<'STUB'
#!/usr/bin/env bash
args="$*"
case "${GH_STUB_MODE:-ok}" in
  fail_with_stdout_payload)
    echo '{"message":"Not Found","documentation_url":"https://docs.github.com/rest","status":"404"}'
    exit 1 ;;
esac
case "$args" in
  *"orgs/crossbearing/repos"*)
    if [ "${GH_STUB_ENUM:-ok}" = "fail" ]; then
      echo '{"message":"API rate limit exceeded","status":"403"}'
      exit 1
    fi
    printf 'verify\n.github\nscenarios\ncrossbearing\n' ;;
  *"private-vulnerability-reporting"*)
    echo "${GH_STUB_PVR:-true}" ;;
  *"contents/go.sum"*)
    echo "HTTP/2.0 ${GH_STUB_GOSUM_STATUS:-404} Not Found" ;;
  *"contents/go.mod"*)
    printf 'module github.com/crossbearing/verify\n\ngo 1.26.0\n' | base64 ;;
  *"/license"*)
    case "$args" in
      *crossbearing/verify*)       echo "${GH_STUB_VERIFY_LICENSE:-MIT}" ;;
      *crossbearing/scenarios*)    echo MIT ;;
      *crossbearing/crossbearing*) echo NOASSERTION ;;
    esac ;;
  *"contents/demo/run.sh"*) exit 0 ;;
  *) exit 0 ;;
esac
STUB

  cat > "$bin/curl" <<'STUB'
#!/usr/bin/env bash
# Emits the http_code on stdout the way real curl does with -w, then exits with
# the configured status. The mid-transfer case prints a 2xx *and* fails.
echo -n "${CURL_STUB_CODE:-200}"
exit "${CURL_STUB_RC:-0}"
STUB

  chmod +x "$bin/gh" "$bin/curl"
}

# ── Fixtures ─────────────────────────────────────────────────────────────────
# A fixture repo that clears both floors, so a case reaches the stage it means
# to test rather than tripping an earlier guard.
make_fixture() {
  local dir=$1 urls=${2:-8} security=${3:-none}
  mkdir -p "$dir/profile"
  cd "$dir" || exit 1
  git init -q .
  # A repo with nothing to scan: the guard must refuse rather than report clean.
  if [ "${FIXTURE_EMPTY:-0}" = "1" ]; then return 0; fi
  {
    echo "# Fixture"
    for i in $(seq 1 "$urls"); do echo "- [link $i](https://example.invalid/page-$i)"; done
  } > README.md
  echo "# Two" > profile/README.md
  echo "# Three" > THIRD.md
  case "$security" in
    names_private_reporting)
      printf '# Security\n\nUse private vulnerability reporting: Report a vulnerability.\n' > SECURITY.md ;;
    silent)
      printf '# Security\n\nEmail us.\n' > SECURITY.md ;;
  esac
  git add -A >/dev/null 2>&1
}

# ── Runner ───────────────────────────────────────────────────────────────────
# expect_rc: the exit status the gate must produce.
# expect_text: a substring that must appear. A case that passes for the wrong
# reason is not a passing case, so both are asserted.
run_case() {
  local name=$1 expect_rc=$2 expect_text=$3; shift 3
  tests_run=$((tests_run + 1))
  local dir="$WORK/case-$tests_run" bin="$WORK/bin-$tests_run"
  make_stubs "$bin"
  ( make_fixture "$dir" "${FIXTURE_URLS:-8}" "${FIXTURE_SECURITY:-none}" ) >/dev/null 2>&1

  local out rc
  out=$(cd "$dir" && env PATH="$bin:$PATH" "$@" bash "$SCRIPT" 2>&1)
  rc=$?

  local ok=1
  [ "$rc" -eq "$expect_rc" ] || ok=0
  grep -qF -- "$expect_text" <<< "$out" || ok=0

  if [ "$ok" -eq 1 ]; then
    printf '  ok    %s\n' "$name"
  else
    tests_failed=$((tests_failed + 1))
    printf '  FAIL  %s\n' "$name"
    printf '        expected rc=%s and text %q\n' "$expect_rc" "$expect_text"
    printf '        got rc=%s\n' "$rc"
    sed 's/^/        | /' <<< "$out" | tail -12
  fi
}

echo "check-claims.sh"

# ── Regression: the two defects that actually shipped ────────────────────────

# A total gh outage must not be survivable. This case does not discriminate
# between the exit-status and emptiness idioms — both fail here — so it is
# named for what it actually asserts. The discriminating case is below.
run_case "a total gh outage fails the run" \
  1 "FAIL" GH_STUB_MODE=fail_with_stdout_payload

# THE regression for the gh defect. gh writes its error payload to stdout, so
# `list=$(gh api ... || echo "")` leaves that payload in the variable. The
# emptiness guard then reads non-empty garbage as a repo list and loops over it
# — silently narrowing "every public repository" to one bogus entry. Branching
# on exit status is what produces the message asserted here; the buggy idiom
# still exits 1, but for the wrong reason and with the wrong scope, so only the
# text discriminates.
run_case "enumeration failing with a payload on stdout is unverifiable, not narrowed" \
  1 "could not list them — an unverifiable claim is a failed claim" GH_STUB_ENUM=fail

# curl that dies after the response line still prints an http_code, so the
# variable begins with 2xx and a `case 2*` match reports ok on a failed fetch.
run_case "curl dying mid-transfer after a 2xx is a failure, not a pass" \
  1 "curl exit 18" CURL_STUB_RC=18 CURL_STUB_CODE=200

# ── The vacuous-pass guards ──────────────────────────────────────────────────

FIXTURE_EMPTY=1 run_case "an empty file list refuses to report rather than passing" \
  1 "Refusing to report on a scan that examined nothing"
unset FIXTURE_EMPTY

FIXTURE_URLS=1 run_case "an extraction below the floor fails instead of going green" \
  1 "extraction is broken, not the docs"
unset FIXTURE_URLS

# ── Claim checks ─────────────────────────────────────────────────────────────

run_case "a licence that does not match what GitHub reports fails" \
  1 "expected MIT, got Apache-2.0" GH_STUB_VERIFY_LICENSE=Apache-2.0

# Absence must be proven by a 404. Any other status means we did not learn
# whether go.sum exists, and "did not learn" is not "is absent".
run_case "an unresolved go.sum status fails rather than reading as absent" \
  1 "an unresolved check is not a pass" GH_STUB_GOSUM_STATUS=403

run_case "a repo with private reporting disabled fails" \
  1 "expected enabled, got 'false'" GH_STUB_PVR=false

# ── The policy-vs-settings seam ──────────────────────────────────────────────

FIXTURE_SECURITY=silent run_case "a silent policy reports the check dormant, not covered" \
  0 "policy-vs-settings check inactive"
unset FIXTURE_SECURITY

FIXTURE_SECURITY=names_private_reporting run_case "a policy naming private reporting is verified against the setting" \
  0 "SECURITY.md points at private reporting, and it is enabled"
unset FIXTURE_SECURITY

# ── Result ───────────────────────────────────────────────────────────────────
echo
if [ "$tests_run" -lt "$MIN_CASES" ]; then
  echo "Ran $tests_run cases, floor is $MIN_CASES — the suite is not running what it claims to."
  exit 1
fi
if [ "$tests_failed" -gt 0 ]; then
  echo "$tests_failed of $tests_run cases failed."
  exit 1
fi
echo "$tests_run cases passed."
