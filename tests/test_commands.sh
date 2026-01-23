#!/usr/bin/env bash
#
# test_commands.sh - Unit/integration tests for command dispatch
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() {
    echo "✓ PASS: $1"
    ((TESTS_PASSED++))
}

fail() {
    echo "✗ FAIL: $1"
    ((TESTS_FAILED++))
}

echo "Running command tests..."
echo

# Test 1: list profiles from valid file
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" list 2>"$stderr_file") || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ -z "$stderr" ]] && [[ "$stdout" == *"default"* ]] && [[ "$stdout" == *"staging"* ]] && [[ "$stdout" == *"production"* ]]; then
    pass "awsprof list outputs profiles"
else
    fail "awsprof list should output profiles"
fi
unset exit_code
unset stderr

# Test 2: list profiles from large file (100+ profiles)
((TESTS_RUN++))
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials_many.mock" "${ROOT_DIR}/awsprof" list 2>/dev/null) || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == *"profile100"* ]] && [[ "$stdout" == *"profile120"* ]]; then
    pass "awsprof list handles 100+ profiles"
else
    fail "awsprof list should handle 100+ profiles"
fi
unset exit_code

# Test 3: missing credentials file
((TESTS_RUN++))
stderr=$(AWS_SHARED_CREDENTIALS_FILE="/nonexistent/file.ini" "${ROOT_DIR}/awsprof" list 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"Credentials file not found"* ]]; then
    pass "awsprof list handles missing credentials file"
else
    fail "awsprof list should fail on missing credentials file"
fi
unset exit_code

# Test 4: empty credentials file
((TESTS_RUN++))
stderr=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials_empty.mock" "${ROOT_DIR}/awsprof" list 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"No profiles found"* ]]; then
    pass "awsprof list handles empty credentials file"
else
    fail "awsprof list should report no profiles for empty file"
fi
unset exit_code

# Test 5: exit codes are correct for success
((TESTS_RUN++))
AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" list >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof list exits 0 on success"
else
    fail "awsprof list should exit 0 on success"
fi
unset exit_code

# Test 6: end-to-end + basic performance check (<100ms)
((TESTS_RUN++))
start_ns=$(date +%s%N)
AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials_many.mock" "${ROOT_DIR}/awsprof" list >/dev/null 2>&1
exit_code=$?
end_ns=$(date +%s%N)
elapsed_ns=$((end_ns - start_ns))
if [[ $exit_code -eq 0 ]] && [[ $elapsed_ns -lt 100000000 ]]; then
    pass "awsprof list completes within 100ms"
else
    fail "awsprof list should complete within 100ms"
fi
unset exit_code

# Test 7: use valid profile
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" use default 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
stdout=${stdout:-}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=default" ]] && [[ "$stderr" == *"Switched to profile: default"* ]]; then
    pass "awsprof use switches to valid profile"
else
    fail "awsprof use should switch to valid profile"
fi
unset exit_code
unset stdout
unset stderr

# Test 8: use non-existent profile
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" use nonexistent 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
stdout=${stdout:-}
if [[ $exit_code -eq 1 ]] && [[ -z "$stdout" ]] && [[ "$stderr" == *"not found"* ]]; then
    pass "awsprof use rejects non-existent profile"
else
    fail "awsprof use should reject non-existent profile"
fi
unset exit_code
unset stdout
unset stderr

# Test 9: use missing parameter
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" use 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
stdout=${stdout:-}
if [[ $exit_code -eq 1 ]] && [[ -z "$stdout" ]] && [[ "$stderr" == *"required"* ]] && [[ "$stderr" != *"unbound variable"* ]]; then
    pass "awsprof use requires profile name"
else
    fail "awsprof use should require profile name"
fi
unset exit_code
unset stdout
unset stderr

# Test 10: eval integration
((TESTS_RUN++))
(
    export AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock"
    eval "$("${ROOT_DIR}/awsprof" use default 2>/dev/null)"
    [[ "$AWS_PROFILE" == "default" ]] && exit 0 || exit 1
) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof use works with eval pattern"
else
    fail "awsprof use should work with eval pattern"
fi
unset exit_code

# Test 11: use command performance (<100ms)
((TESTS_RUN++))
start_ns=$(date +%s%N)
AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" use default >/dev/null 2>&1
exit_code=$?
end_ns=$(date +%s%N)
elapsed_ns=$((end_ns - start_ns))
if [[ $exit_code -eq 0 ]] && [[ $elapsed_ns -lt 100000000 ]]; then
    pass "awsprof use completes within 100ms"
else
    fail "awsprof use should complete within 100ms"
fi
unset exit_code

# Test 12: whoami with AWS_PROFILE set
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(AWS_PROFILE="staging" "${ROOT_DIR}/awsprof" whoami 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
stdout=${stdout:-}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "staging" ]] && [[ -z "$stderr" ]]; then
    pass "awsprof whoami displays current profile"
else
    fail "awsprof whoami should display current profile"
fi
unset exit_code
unset stdout
unset stderr

# Test 13: whoami without AWS_PROFILE set
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(unset AWS_PROFILE; "${ROOT_DIR}/awsprof" whoami 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
stdout=${stdout:-}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == *"No profile set"* ]] && [[ -z "$stderr" ]]; then
    pass "awsprof whoami displays default message when no profile set"
else
    fail "awsprof whoami should display default message"
fi
unset exit_code
unset stdout
unset stderr

# Test 14: whoami with empty AWS_PROFILE
((TESTS_RUN++))
stderr_file=$(mktemp)
stdout=$(AWS_PROFILE="" "${ROOT_DIR}/awsprof" whoami 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
stdout=${stdout:-}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == *"No profile set"* ]] && [[ -z "$stderr" ]]; then
    pass "awsprof whoami handles empty AWS_PROFILE"
else
    fail "awsprof whoami should handle empty AWS_PROFILE"
fi
unset exit_code
unset stdout
unset stderr

# Test 15: whoami performance (<100ms)
((TESTS_RUN++))
start_ns=$(date +%s%N)
AWS_PROFILE="test" "${ROOT_DIR}/awsprof" whoami >/dev/null 2>&1
exit_code=$?
end_ns=$(date +%s%N)
elapsed_ns=$((end_ns - start_ns))
if [[ $exit_code -eq 0 ]] && [[ $elapsed_ns -lt 100000000 ]]; then
    pass "awsprof whoami completes within 100ms"
else
    fail "awsprof whoami should complete within 100ms"
fi
unset exit_code

# Test 16: integration - whoami after use
((TESTS_RUN++))
(
    export AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock"
    eval "$("${ROOT_DIR}/awsprof" use default 2>/dev/null)"
    result=$("${ROOT_DIR}/awsprof" whoami)
    [[ "$result" == "default" ]] && exit 0 || exit 1
) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof whoami shows profile after use command"
else
    fail "awsprof whoami should show profile after use command"
fi
unset exit_code

echo
echo "=============================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=============================="

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
