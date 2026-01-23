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
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" list 2>/dev/null) || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == *"default"* ]] && [[ "$stdout" == *"staging"* ]] && [[ "$stdout" == *"production"* ]]; then
    pass "awsprof list outputs profiles"
else
    fail "awsprof list should output profiles"
fi
unset exit_code

# Test 2: missing credentials file
((TESTS_RUN++))
stderr=$(AWS_SHARED_CREDENTIALS_FILE="/nonexistent/file.ini" "${ROOT_DIR}/awsprof" list 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"Credentials file not found"* ]]; then
    pass "awsprof list handles missing credentials file"
else
    fail "awsprof list should fail on missing credentials file"
fi
unset exit_code

# Test 3: empty credentials file
((TESTS_RUN++))
stderr=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials_empty.mock" "${ROOT_DIR}/awsprof" list 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"No profiles found"* ]]; then
    pass "awsprof list handles empty credentials file"
else
    fail "awsprof list should report no profiles for empty file"
fi
unset exit_code

# Test 4: exit codes are correct for success
((TESTS_RUN++))
AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" list >/dev/null 2>&1
exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof list exits 0 on success"
else
    fail "awsprof list should exit 0 on success"
fi
unset exit_code

# Test 5: end-to-end + basic performance check (<100ms)
((TESTS_RUN++))
start_ns=$(date +%s%N)
AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" list >/dev/null 2>&1
exit_code=$?
end_ns=$(date +%s%N)
elapsed_ns=$((end_ns - start_ns))
if [[ $exit_code -eq 0 ]] && [[ $elapsed_ns -lt 100000000 ]]; then
    pass "awsprof list completes within 100ms"
else
    fail "awsprof list should complete within 100ms"
fi
unset exit_code

echo
echo "=============================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=============================="

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
