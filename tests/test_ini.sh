#!/usr/bin/env bash
#
# test_ini.sh - Unit tests for INI parsing functions
#

# Source the main script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../awsprof" 2>/dev/null || source "${SCRIPT_DIR}/../awsprof"

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

echo "Running INI parsing tests..."
echo

# Test 1: List sections with valid file
((TESTS_RUN++))
result=$(awsprof_ini_list_sections "${SCRIPT_DIR}/fixtures/credentials.mock" 2>/dev/null) || true
if [[ "$result" == *"default"* ]] && [[ "$result" == *"staging"* ]] && [[ "$result" == *"production"* ]]; then
    pass "awsprof_ini_list_sections returns all sections"
else
    fail "awsprof_ini_list_sections missing sections"
fi

# Test 2: List sections with missing file
((TESTS_RUN++))
result=$(awsprof_ini_list_sections "/nonexistent/file.ini" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"not found"* ]]; then
    pass "awsprof_ini_list_sections handles missing file"
else
    fail "awsprof_ini_list_sections should fail on missing file"
fi

# Test 3: Read section with valid profile
((TESTS_RUN++))
result=$(awsprof_ini_read_section "default" "${SCRIPT_DIR}/fixtures/credentials.mock" 2>/dev/null) || true
if [[ "$result" == *"aws_access_key_id=AKIAIOSFODNN7EXAMPLE"* ]]; then
    pass "awsprof_ini_read_section reads valid section"
else
    fail "awsprof_ini_read_section failed to read section"
fi

# Test 4: Read section with additional fields
((TESTS_RUN++))
result=$(awsprof_ini_read_section "staging" "${SCRIPT_DIR}/fixtures/credentials.mock" 2>/dev/null) || true
if [[ "$result" == *"region=us-west-2"* ]]; then
    pass "awsprof_ini_read_section reads additional fields"
else
    fail "awsprof_ini_read_section failed to read region"
fi

# Test 5: Read section with missing file
((TESTS_RUN++))
result=$(awsprof_ini_read_section "default" "/nonexistent/file.ini" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"not found"* ]]; then
    pass "awsprof_ini_read_section handles missing file"
else
    fail "awsprof_ini_read_section should fail on missing file"
fi

# Test 6: Read section without parameter
((TESTS_RUN++))
result=$(awsprof_ini_read_section "" "${SCRIPT_DIR}/fixtures/credentials.mock" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof_ini_read_section requires section parameter"
else
    fail "awsprof_ini_read_section should fail without section"
fi

# Test 7: Handle malformed INI gracefully (list sections)
((TESTS_RUN++))
result=$(awsprof_ini_list_sections "${SCRIPT_DIR}/fixtures/credentials_malformed.mock" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"Malformed INI section header"* ]]; then
    pass "awsprof_ini_list_sections reports malformed INI"
else
    fail "awsprof_ini_list_sections should report malformed INI"
fi

# Test 8: Handle malformed INI gracefully (read section)
((TESTS_RUN++))
result=$(awsprof_ini_read_section "default" "${SCRIPT_DIR}/fixtures/credentials_malformed.mock" 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"Malformed INI section header"* ]]; then
    pass "awsprof_ini_read_section reports malformed INI"
else
    fail "awsprof_ini_read_section should report malformed INI"
fi

echo
echo "=============================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=============================="

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
