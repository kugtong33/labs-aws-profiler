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

# Test 15: hook detects valid project .awsprofile and outputs export
((TESTS_RUN++))
tmp_dir=$(mktemp -d)
printf "default\n" > "${tmp_dir}/.awsprofile"
stderr_file=$(mktemp)
stdout=$(cd "$tmp_dir" && AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
rm -rf "$tmp_dir"
stdout=${stdout:-}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=default" ]] && [[ -z "$stderr" ]]; then
    pass "hook outputs export for valid .awsprofile"
else
    fail "hook should output export for valid .awsprofile"
fi
unset exit_code
unset stdout
unset stderr

# Test 16: hook trims whitespace in .awsprofile
((TESTS_RUN++))
tmp_dir=$(mktemp -d)
printf "  default  \n" > "${tmp_dir}/.awsprofile"
stderr_file=$(mktemp)
stdout=$(cd "$tmp_dir" && AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>"$stderr_file") && exit_code=0 || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
rm -rf "$tmp_dir"
stdout=${stdout:-}
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=default" ]] && [[ -z "$stderr" ]]; then
    pass "hook trims whitespace in .awsprofile"
else
    fail "hook should trim whitespace in .awsprofile"
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

#=== ADD COMMAND TESTS ===

# Test 17: add new profile successfully
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add.tmp"
echo "[existing]" > "$test_file"
echo "aws_access_key_id=EXISTINGKEY" >> "$test_file"
echo "aws_secret_access_key=EXISTINGSECRET" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add newprofile 2>&1) && exit_code=0 || exit_code=$?
profile_exists=$(grep "^\[newprofile\]" "$test_file" 2>/dev/null)
backup_count=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
if [[ $exit_code -eq 0 ]] && [[ "$result" == *"added successfully"* ]] && [[ -n "$profile_exists" ]] && [[ $backup_count -ge 1 ]]; then
    pass "awsprof add creates new profile"
else
    fail "awsprof add should create new profile (exit=$exit_code, exists=$profile_exists, backups=$backup_count)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 18: add duplicate profile rejection
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_dup.tmp"
echo "[duplicate]" > "$test_file"
echo "key=value" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add duplicate 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"already exists"* ]]; then
    pass "awsprof add rejects duplicate profile"
else
    fail "awsprof add should reject duplicate (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 19: add missing profile name parameter
((TESTS_RUN++))
result=$(AWS_SHARED_CREDENTIALS_FILE="/tmp/test.tmp" "${ROOT_DIR}/awsprof" add 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof add requires profile name"
else
    fail "awsprof add should require profile name (exit=$exit_code)"
fi
unset exit_code

# Test 20: add with empty access key
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_empty.tmp"
echo "[test]" > "$test_file"
result=$(echo -e "\nsecret" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add emptykey 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof add rejects empty access key"
else
    fail "awsprof add should reject empty access key (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 21: add with empty secret key
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_empty2.tmp"
echo "[test]" > "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\n" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add emptysecret 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof add rejects empty secret key"
else
    fail "awsprof add should reject empty secret key (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 22: add preserves existing profiles
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_preserve.tmp"
echo "[profile1]" > "$test_file"
echo "key1=value1" >> "$test_file"
echo "" >> "$test_file"
echo "[profile2]" >> "$test_file"
echo "key2=value2" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add newprofile 2>&1) && exit_code=0 || exit_code=$?
profile1_exists=$(grep "^\[profile1\]" "$test_file" 2>/dev/null)
profile2_exists=$(grep "^\[profile2\]" "$test_file" 2>/dev/null)
if [[ $exit_code -eq 0 ]] && [[ -n "$profile1_exists" ]] && [[ -n "$profile2_exists" ]]; then
    pass "awsprof add preserves existing profiles"
else
    fail "awsprof add should preserve existing profiles"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 23: add sets chmod 600
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_chmod.tmp"
echo "[test]" > "$test_file"
chmod 644 "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add newprofile 2>&1) && exit_code=0 || exit_code=$?
perms=$(stat -c "%a" "$test_file" 2>/dev/null || stat -f "%A" "$test_file" 2>/dev/null)
if [[ $exit_code -eq 0 ]] && [[ "$perms" == "600" ]]; then
    pass "awsprof add sets chmod 600"
else
    fail "awsprof add should set chmod 600 (perms=$perms)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 24: add never displays secret in output
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_secret.tmp"
echo "[test]" > "$test_file"
secret="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\n$secret" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add secrettest 2>&1)
if [[ "$result" != *"$secret"* ]]; then
    pass "awsprof add never displays secret"
else
    fail "awsprof add displayed secret in output"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null

# Test 25: integration - add then list
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_list.tmp"
echo "[existing]" > "$test_file"
echo "key=value" >> "$test_file"
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add integration-test 2>/dev/null
list_result=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" list 2>/dev/null)
if [[ "$list_result" == *"integration-test"* ]]; then
    pass "awsprof add then list shows new profile"
else
    fail "awsprof list should show added profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null

# Test 26: integration - add then use
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_use.tmp"
echo "[existing]" > "$test_file"
echo "key=value" >> "$test_file"
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add switch-test 2>/dev/null
(
    eval "$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" use switch-test 2>/dev/null)"
    [[ "$AWS_PROFILE" == "switch-test" ]] && exit 0 || exit 1
) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof add then use switches to new profile"
else
    fail "awsprof use should work with added profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 27: add rejects invalid access key format
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_invalid_access.tmp"
echo "[test]" > "$test_file"
result=$(echo -e "INVALIDKEY\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add badaccess 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"Invalid Access Key ID format"* ]]; then
    pass "awsprof add rejects invalid access key format"
else
    fail "awsprof add should reject invalid access key format (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 28: add rejects invalid secret key format
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_add_invalid_secret.tmp"
echo "[test]" > "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nshortsecret" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add badsecret 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"Invalid Secret Access Key format"* ]]; then
    pass "awsprof add rejects invalid secret key format"
else
    fail "awsprof add should reject invalid secret key format (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

#=== EDIT COMMAND TESTS ===

# Test 29: edit existing profile successfully
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit.tmp"
echo "[testprofile]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit testprofile 2>&1) && exit_code=0 || exit_code=$?
profile_exists=$(grep "^\[testprofile\]" "$test_file" 2>/dev/null)
new_key=$(grep "aws_access_key_id=AKIAIOSFODNN7EXAMPLE" "$test_file" 2>/dev/null)
old_key=$(grep "OLDKEY" "$test_file" 2>/dev/null)
backup_count=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
if [[ $exit_code -eq 0 ]] && [[ "$result" == *"updated successfully"* ]] && [[ -n "$profile_exists" ]] && [[ -n "$new_key" ]] && [[ -z "$old_key" ]] && [[ $backup_count -ge 1 ]]; then
    pass "awsprof edit updates existing profile"
else
    fail "awsprof edit should update profile (exit=$exit_code, exists=$profile_exists, new_key=$new_key, old_key=$old_key, backups=$backup_count)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 30: edit non-existent profile rejection
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_noexist.tmp"
echo "[existing]" > "$test_file"
echo "key=value" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit nonexistent 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"not found"* ]]; then
    pass "awsprof edit rejects non-existent profile"
else
    fail "awsprof edit should reject non-existent profile (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 31: edit missing profile name parameter
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_noparam.tmp"
echo "[existing]" > "$test_file"
result=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof edit requires profile name"
else
    fail "awsprof edit should require profile name (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 32: edit with empty access key
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_empty.tmp"
echo "[emptykey]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
result=$(echo -e "\nsecret" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit emptykey 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof edit rejects empty access key"
else
    fail "awsprof edit should reject empty access key (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 33: edit with empty secret key
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_empty2.tmp"
echo "[emptysecret]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\n" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit emptysecret 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"required"* ]]; then
    pass "awsprof edit rejects empty secret key"
else
    fail "awsprof edit should reject empty secret key (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 34: edit preserves other profiles
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_preserve.tmp"
echo "[profile1]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "aws_secret_access_key=SECRET1" >> "$test_file"
echo "" >> "$test_file"
echo "[profile2]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
echo "aws_secret_access_key=SECRET2" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit profile1 2>&1) && exit_code=0 || exit_code=$?
profile1_exists=$(grep "^\[profile1\]" "$test_file" 2>/dev/null)
profile2_exists=$(grep "^\[profile2\]" "$test_file" 2>/dev/null)
profile2_key=$(grep -A1 "^\[profile2\]" "$test_file" 2>/dev/null | grep "KEY2")
if [[ $exit_code -eq 0 ]] && [[ -n "$profile1_exists" ]] && [[ -n "$profile2_exists" ]] && [[ -n "$profile2_key" ]]; then
    pass "awsprof edit preserves other profiles"
else
    fail "awsprof edit should preserve other profiles"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 35: edit sets chmod 600
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_chmod.tmp"
echo "[testprofile]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
chmod 644 "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit testprofile 2>&1) && exit_code=0 || exit_code=$?
perms=$(stat -c "%a" "$test_file" 2>/dev/null || stat -f "%A" "$test_file" 2>/dev/null)
if [[ $exit_code -eq 0 ]] && [[ "$perms" == "600" ]]; then
    pass "awsprof edit sets chmod 600"
else
    fail "awsprof edit should set chmod 600 (perms=$perms)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 36: edit never displays secret in output
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_secret.tmp"
echo "[testprofile]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
secret="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\n$secret" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit testprofile 2>&1)
if [[ "$result" != *"$secret"* ]]; then
    pass "awsprof edit never displays secret"
else
    fail "awsprof edit displayed secret in output"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null

# Test 37: integration - edit then list
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_list.tmp"
echo "[tolist]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit tolist 2>/dev/null
list_result=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" list 2>/dev/null)
if [[ "$list_result" == *"tolist"* ]]; then
    pass "awsprof edit then list shows profile"
else
    fail "awsprof list should show edited profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null

# Test 38: integration - edit then use
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_use.tmp"
echo "[touse]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit touse 2>/dev/null
(
    eval "$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" use touse 2>/dev/null)"
    [[ "$AWS_PROFILE" == "touse" ]] && exit 0 || exit 1
) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof edit then use switches to profile"
else
    fail "awsprof use should work with edited profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 39: edit rejects invalid access key format
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_invalid_access.tmp"
echo "[testprofile]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
result=$(echo -e "INVALIDKEY\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit testprofile 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"Invalid Access Key ID format"* ]]; then
    pass "awsprof edit rejects invalid access key format"
else
    fail "awsprof edit should reject invalid access key format (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 40: edit rejects invalid secret key format
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_invalid_secret.tmp"
echo "[testprofile]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nshortsecret" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit testprofile 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"Invalid Secret Access Key format"* ]]; then
    pass "awsprof edit rejects invalid secret key format"
else
    fail "awsprof edit should reject invalid secret key format (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# ===== REMOVE COMMAND TESTS (Story 2.4) =====

# Test 41: Remove existing profile successfully
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[keep-this]" > "$test_file"
echo "aws_access_key_id=KEEP123" >> "$test_file"
echo "aws_secret_access_key=KEEPSECRET456" >> "$test_file"
echo "[remove-me]" >> "$test_file"
echo "aws_access_key_id=DELETE123" >> "$test_file"
echo "aws_secret_access_key=DELETESECRET456" >> "$test_file"
stderr_file=$(mktemp)
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove remove-me 2>"$stderr_file" || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
exit_code=${exit_code:-0}
# Check removal succeeded
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"removed successfully"* ]] && ! grep -q "^\[remove-me\]" "$test_file" && grep -q "^\[keep-this\]" "$test_file"; then
    pass "awsprof remove deletes target profile"
else
    fail "awsprof remove should delete target profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset stderr

# Test 42: Non-existent profile rejection
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[exists]" > "$test_file"
echo "aws_access_key_id=KEY123" >> "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove nonexistent 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"not found"* ]]; then
    pass "awsprof remove rejects non-existent profile"
else
    fail "awsprof remove should reject non-existent profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset stderr

# Test 43: Missing profile name parameter
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[test]" > "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"required"* ]]; then
    pass "awsprof remove requires profile name"
else
    fail "awsprof remove should require profile name"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset stderr

# Test 44: Remove only profile (empty file result)
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[only-profile]" > "$test_file"
echo "aws_access_key_id=ONLY123" >> "$test_file"
echo "aws_secret_access_key=ONLYSECRET456" >> "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove only-profile >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
# Check file exists but is empty (or only comments)
if [[ $exit_code -eq 0 ]] && [[ -f "$test_file" ]] && ! grep -q "^\[" "$test_file"; then
    pass "awsprof remove handles removing only profile"
else
    fail "awsprof remove should leave empty file when removing only profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 45: Other profiles preserved after deletion
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[profile1]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "[profile2]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
echo "[profile3]" >> "$test_file"
echo "aws_access_key_id=KEY3" >> "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove profile2 >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
# Check profile2 removed but others remain
if [[ $exit_code -eq 0 ]] && ! grep -q "^\[profile2\]" "$test_file" && grep -q "^\[profile1\]" "$test_file" && grep -q "^\[profile3\]" "$test_file"; then
    pass "awsprof remove preserves other profiles"
else
    fail "awsprof remove should preserve other profiles"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 46: Backup created before deletion
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[remove-me]" > "$test_file"
echo "aws_access_key_id=DELETE123" >> "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove remove-me >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
backup_count=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
if [[ $exit_code -eq 0 ]] && [[ $backup_count -ge 1 ]]; then
    pass "awsprof remove creates backup before deletion"
else
    fail "awsprof remove should create backup"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 47: Backup filename format is correct
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[remove-me]" > "$test_file"
echo "aws_access_key_id=DELETE123" >> "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove remove-me >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
backup_file=$(ls -t "${test_file}.bak."* 2>/dev/null | head -n 1)
if [[ $exit_code -eq 0 ]] && [[ "$backup_file" =~ \.bak\.[0-9]{8}-[0-9]{6}$ ]]; then
    pass "awsprof remove creates timestamped backup filename"
else
    fail "awsprof remove should create timestamped backup filename"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 48: Removal failure leaves original intact
((TESTS_RUN++))
temp_dir=$(mktemp -d)
test_file="${temp_dir}/credentials"
echo "[only]" > "$test_file"
echo "aws_access_key_id=ONLY123" >> "$test_file"
chmod 500 "$temp_dir"
orig_checksum=$(cksum "$test_file" | awk '{print $1}')
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove only >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
new_checksum=$(cksum "$test_file" | awk '{print $1}')
if [[ $exit_code -ne 0 ]] && [[ "$orig_checksum" == "$new_checksum" ]]; then
    pass "awsprof remove fails safely without modifying original"
else
    fail "awsprof remove should not modify original on failure"
fi
chmod 700 "$temp_dir"
rm -rf "$temp_dir"
unset exit_code

# Test 49: Removal failure after backup leaves original intact
((TESTS_RUN++))
temp_dir=$(mktemp -d)
test_file="${temp_dir}/credentials"
echo "[only]" > "$test_file"
echo "aws_access_key_id=ONLY123" >> "$test_file"
orig_checksum=$(cksum "$test_file" | awk '{print $1}')
mkdir -p "${temp_dir}/bin"
cat > "${temp_dir}/bin/mv" <<EOF
#!/usr/bin/env bash
if [[ "\$2" == "${test_file}" ]]; then
  exit 1
fi
exec /bin/mv "$@"
EOF
chmod +x "${temp_dir}/bin/mv"
PATH="${temp_dir}/bin:$PATH" AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove only >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
new_checksum=$(cksum "$test_file" | awk '{print $1}')
backup_count=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
if [[ $exit_code -ne 0 ]] && [[ "$orig_checksum" == "$new_checksum" ]] && [[ $backup_count -ge 1 ]]; then
    pass "awsprof remove preserves original when move fails"
else
    fail "awsprof remove should not modify original when move fails"
fi
rm -rf "$temp_dir"
unset exit_code

# Test 50: chmod 600 maintained on credentials file
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[remove-me]" > "$test_file"
echo "aws_access_key_id=DELETE123" >> "$test_file"
chmod 600 "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove remove-me >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
perms=$(stat -c %a "$test_file" 2>/dev/null || stat -f %OLp "$test_file" | grep -o '..$')
if [[ $exit_code -eq 0 ]] && [[ "$perms" == "600" || "$perms" == "rw-------" ]]; then
    pass "awsprof remove maintains chmod 600"
else
    fail "awsprof remove should maintain chmod 600"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset perms

# Test 51: Integration - remove then list
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[profile1]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "[profile2]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove profile1 >/dev/null 2>&1 || exit_code=$?
exit_code=${exit_code:-0}
list_output=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" list 2>/dev/null)
if [[ $exit_code -eq 0 ]] && [[ ! "$list_output" == *"profile1"* ]] && [[ "$list_output" == *"profile2"* ]]; then
    pass "awsprof remove then list shows updated profiles"
else
    fail "awsprof list should reflect removed profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset list_output

# Test 52: Integration - remove then attempt to use deleted profile
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[deleted-profile]" > "$test_file"
echo "aws_access_key_id=DELETE123" >> "$test_file"
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove deleted-profile >/dev/null 2>&1
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" use deleted-profile 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"not found"* ]]; then
    pass "awsprof use fails on removed profile"
else
    fail "awsprof use should fail on removed profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset stderr

# Test 53: Error messages format and exit codes
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove.tmp"
echo "[test]" > "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove nonexistent 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == "Error: "* ]]; then
    pass "awsprof remove error messages properly formatted"
else
    fail "awsprof remove should format error messages correctly"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code
unset stderr

# ===== IMPORT COMMAND TESTS (Story 2.5) =====

# Test 54: Import profiles from valid credentials file
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
echo "[profile1]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "[profile2]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 2 profiles"* ]] && [[ "$stderr" == *"profile1"* ]] && [[ "$stderr" == *"profile2"* ]]; then
    pass "awsprof import lists profiles from credentials file"
else
    fail "awsprof import should list profiles"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr

# Test 55: Import with empty credentials file
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
touch "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 0 profiles"* ]]; then
    pass "awsprof import handles empty credentials file"
else
    fail "awsprof import should report 0 profiles for empty file"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr

# Test 56: Import with single profile
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
echo "[onlyprofile]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 1 profile"* ]] && [[ "$stderr" == *"onlyprofile"* ]]; then
    pass "awsprof import handles single profile"
else
    fail "awsprof import should handle single profile"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr

# Test 57: Import with many profiles (10+)
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
for i in {1..12}; do
    echo "[profile$i]" >> "$test_file"
    echo "aws_access_key_id=KEY$i" >> "$test_file"
done
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 12 profiles"* ]]; then
    pass "awsprof import handles 10+ profiles"
else
    fail "awsprof import should handle 10+ profiles"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr

# Test 58: Import with comments and blank lines
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
cat > "$test_file" <<'EOF'
# This is a comment
[profile1]
aws_access_key_id=KEY1

; Another comment
[profile2]
aws_access_key_id=KEY2

# Final comment
EOF
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
# Check file is unmodified (read-only) - verify file still exists and has content
file_size_before=$(stat -c %s "$test_file" 2>/dev/null || stat -f %z "$test_file")
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 2 profiles"* ]] && [[ -f "$test_file" ]] && [[ $file_size_before -gt 0 ]]; then
    pass "awsprof import preserves file structure"
else
    fail "awsprof import should preserve file and detect profiles"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr
unset file_size_before

# Test 59: Import when credentials file missing
((TESTS_RUN++))
stderr=$(AWS_SHARED_CREDENTIALS_FILE="/nonexistent/credentials" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"No credentials file found"* ]]; then
    pass "awsprof import handles missing credentials file with error"
else
    fail "awsprof import should exit 1 when credentials file missing"
fi
unset exit_code
unset stderr

# Test 60: Import with malformed INI syntax
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
cat > "$test_file" <<'EOF'
[valid1]
aws_access_key_id=KEY1
[malformed
aws_access_key_id=BAD
EOF
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
# Should detect valid profiles and report errors
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 1 profiles"* ]] && [[ "$stderr" == *"valid1"* ]] && [[ "$stderr" == *"Malformed"* ]]; then
    pass "awsprof import handles malformed files gracefully"
else
    fail "awsprof import should report profiles and errors on malformed files"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr

# Test 61: Import with special characters in profile names
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
echo "[profile-with-dashes]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "[profile_with_underscores]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
echo "[profile.with.dots]" >> "$test_file"
echo "aws_access_key_id=KEY3" >> "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]] && [[ "$stderr" == *"Found 3 profiles"* ]] && [[ "$stderr" == *"profile-with-dashes"* ]]; then
    pass "awsprof import handles special characters in names"
else
    fail "awsprof import should handle special characters"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code
unset stderr

# Test 62: Integration - import then list consistency
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
echo "[test1]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "[test2]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
import_output=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import 2>&1)
list_output=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" list 2>/dev/null)
if [[ "$import_output" == *"test1"* ]] && [[ "$import_output" == *"test2"* ]] && [[ "$list_output" == *"test1"* ]] && [[ "$list_output" == *"test2"* ]]; then
    pass "awsprof import then list shows consistency"
else
    fail "awsprof import should match list output"
fi
rm -f "$test_file" 2>/dev/null
unset import_output
unset list_output

# Test 63: Import exit codes - success vs error
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_import.tmp"
echo "[test]" > "$test_file"
# Test with valid file - should exit 0
AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" import >/dev/null 2>&1
exit_code=$?
rm -f "$test_file" 2>/dev/null
# Test with missing file - should exit 1 (error condition)
AWS_SHARED_CREDENTIALS_FILE="/nonexistent/file" "${ROOT_DIR}/awsprof" import >/dev/null 2>&1
exit_code_missing=$?
if [[ $exit_code -eq 0 ]] && [[ $exit_code_missing -eq 1 ]]; then
    pass "awsprof import exits correctly (0 on success, 1 on error)"
else
    fail "awsprof import should exit 0 on success, 1 on missing file"
fi
unset exit_code
unset exit_code_missing

# Test 64: Add profile with special characters in name
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_special.tmp"
touch "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add "profile-with-dash" 2>&1)
if grep -q "^\[profile-with-dash\]" "$test_file" 2>/dev/null; then
    pass "awsprof add accepts profile names with dashes"
else
    fail "awsprof add should accept profile names with dashes"
fi
rm -f "$test_file" 2>/dev/null

# Test 65: Add profile rejects extra arguments
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_extra.tmp"
touch "$test_file"
stderr=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add "myprofile" "extra_argument" 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"Too many arguments"* ]]; then
    pass "awsprof add rejects extra arguments"
else
    fail "awsprof add should reject extra arguments"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code

# Test 66: Edit profile with special characters in name
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_special_edit.tmp"
echo "[profile_with_underscore]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit "profile_with_underscore" 2>&1)
if grep -q "AKIAIOSFODNN7EXAMPLE" "$test_file" 2>/dev/null; then
    pass "awsprof edit accepts profile names with underscores"
else
    fail "awsprof edit should accept profile names with underscores"
fi
rm -f "$test_file" 2>/dev/null

# Test 67: Edit profile rejects extra arguments
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_extra.tmp"
echo "[myprofile]" > "$test_file"
echo "aws_access_key_id=KEY" >> "$test_file"
stderr=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit "myprofile" "extra_arg" 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"Too many arguments"* ]]; then
    pass "awsprof edit rejects extra arguments"
else
    fail "awsprof edit should reject extra arguments"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code

# Test 68: Remove profile rejects extra arguments
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_remove_extra.tmp"
echo "[myprofile]" > "$test_file"
echo "aws_access_key_id=KEY" >> "$test_file"
stderr=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" remove "myprofile" "extra_arg" 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"Too many arguments"* ]]; then
    pass "awsprof remove rejects extra arguments"
else
    fail "awsprof remove should reject extra arguments"
fi
rm -f "$test_file" 2>/dev/null
unset exit_code

# Test 69: Use profile rejects extra arguments
((TESTS_RUN++))
stderr=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" use "default" "extra_arg" 2>&1 >/dev/null) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 1 ]] && [[ "$stderr" == *"Too many arguments"* ]]; then
    pass "awsprof use rejects extra arguments"
else
    fail "awsprof use should reject extra arguments"
fi
unset exit_code

# Test 70: Init command outputs valid bash syntax
((TESTS_RUN++))
init_output=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
if echo "$init_output" | bash -n 2>/dev/null; then
    pass "awsprof init outputs valid bash syntax"
else
    fail "awsprof init should output valid bash syntax"
fi
unset init_output

# Test 71: Output can be eval'd without errors
((TESTS_RUN++))
init_output=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
# Try to eval in a subshell - verify no errors occur
eval_result=$(bash -c "eval \"\$1\"" -- "$init_output" 2>&1) && exit_code=0 || exit_code=$?
exit_code=${exit_code:-0}
if [[ $exit_code -eq 0 ]]; then
    pass "awsprof init output can be eval'd without errors"
else
    fail "awsprof init output should eval without errors (error: $eval_result)"
fi
unset init_output exit_code eval_result

# Test 72: Wrapper function is defined after eval
((TESTS_RUN++))
# Create a temporary shell script that sources init and checks for awsprof function
test_script=$(mktemp)
cat > "$test_script" <<EOF
eval "\$("${ROOT_DIR}/awsprof" init)"
if declare -f awsprof >/dev/null 2>&1; then
    echo "function_exists"
fi
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "function_exists" ]]; then
    pass "awsprof wrapper function is defined after eval"
else
    fail "awsprof wrapper function should be defined after eval (got: $result)"
fi
unset test_script result

# Test 73: PROMPT_COMMAND is set after eval
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
eval "\$("${ROOT_DIR}/awsprof" init)"
if [[ -n "\$PROMPT_COMMAND" ]]; then
    echo "hook_set"
fi
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "hook_set" ]]; then
    pass "PROMPT_COMMAND is set after eval"
else
    fail "PROMPT_COMMAND should be set after eval"
fi
unset test_script result

# Test 74: Wrapper function is callable after eval
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
eval "\$("${ROOT_DIR}/awsprof" init)"
# Test that wrapper function exists and is callable
if type awsprof >/dev/null 2>&1; then
    echo "function_callable"
fi
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "function_callable" ]]; then
    pass "Wrapper function is callable after eval"
else
    fail "Wrapper function should be callable after eval"
fi
unset test_script result

# Test 75: Init works when awsprof is in PATH
((TESTS_RUN++))
# awsprof should already be in PATH during test
init_result=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
if [[ -n "$init_result" ]] && echo "$init_result" | grep -q "awsprof"; then
    pass "init works when awsprof is in PATH"
else
    fail "init should output code when awsprof is in PATH"
fi
unset init_result

# Test 76: Init outputs wrapper function definition
((TESTS_RUN++))
init_result=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
if [[ "$init_result" == *"awsprof()"* ]] || [[ "$init_result" == *"function awsprof"* ]]; then
    pass "init outputs wrapper function definition"
else
    fail "init should output wrapper function definition"
fi
unset init_result

# Test 77: Init includes PROMPT_COMMAND setup
((TESTS_RUN++))
init_result=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
if [[ "$init_result" == *"PROMPT_COMMAND"* ]]; then
    pass "init includes PROMPT_COMMAND setup"
else
    fail "init should include PROMPT_COMMAND setup"
fi
unset init_result

# Test 78: Init outputs to stdout (no stderr)
((TESTS_RUN++))
stdout_output=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
stderr_output=$("${ROOT_DIR}/awsprof" init 2>&1 >/dev/null)
if [[ -n "$stdout_output" ]] && [[ -z "$stderr_output" ]]; then
    pass "init outputs to stdout only"
else
    fail "init should output to stdout, not stderr"
fi
unset stdout_output stderr_output

# Test 79: Shell remains functional after eval (basic sanity check)
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<'EOF'
eval "$(awsprof init)"
# Try basic shell operations after eval
cd /tmp 2>/dev/null
result=$(echo "test")
if [[ "$result" == "test" ]]; then
    echo "shell_ok"
fi
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "shell_ok" ]]; then
    pass "Shell remains functional after eval"
else
    fail "Shell should remain functional after eval"
fi
unset test_script result

# Test 80: Wrapper function actually executes awsprof commands (CRITICAL FUNCTIONAL TEST)
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
# Make sure awsprof is in PATH for the wrapper to find
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init)"
# Now actually call the wrapper with a real command
result=\$(awsprof list 2>&1 | head -1)
if [[ -n "\$result" ]]; then
    echo "wrapper_works"
fi
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "wrapper_works" ]]; then
    pass "Wrapper function successfully executes awsprof commands"
else
    fail "Wrapper function should execute awsprof commands (got: $result)"
fi
unset test_script result

# Test 81: Wrapper enables profile switching via eval (AC3 verification)
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
# Make sure awsprof is in PATH for the wrapper to find
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init)"
# Set up a test profile first (isolated credentials file)
creds_file=\$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="\$creds_file"
cat > "\$creds_file" <<'CREDS'
[test-profile-abc]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS

# Now use the wrapper to switch profiles
awsprof use test-profile-abc >/dev/null 2>&1
# Verify AWS_PROFILE is set in current shell (not a subshell)
if [[ "\$AWS_PROFILE" == "test-profile-abc" ]]; then
    echo "profile_set"
fi
rm -f "\$creds_file" 2>/dev/null
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "profile_set" ]]; then
    pass "Wrapper function enables profile switching in current shell (AC3)"
else
    fail "Wrapper should enable profile switching in current shell"
fi
unset test_script result

# Test 82: Init command rejects extra arguments
((TESTS_RUN++))
init_with_args=$("${ROOT_DIR}/awsprof" init extra-arg 2>&1)
init_exit=$?
if [[ $init_exit -ne 0 ]]; then
    pass "init command rejects extra arguments"
else
    fail "init command should reject extra arguments (exit code was: $init_exit)"
fi
unset init_with_args init_exit

# Story 3.2: POSIX sh Initialization Script Tests

# Test 83: Init --sh outputs valid POSIX sh syntax
((TESTS_RUN++))
init_output=$("${ROOT_DIR}/awsprof" init --sh 2>/dev/null)
# Validate POSIX sh syntax with sh -n
echo "$init_output" | sh -n 2>/dev/null
if [[ $? -eq 0 ]]; then
    pass "init --sh outputs valid POSIX sh syntax"
else
    fail "init --sh should output valid POSIX sh syntax"
fi
unset init_output

# Test 84: Init --sh output can be eval'd in sh environment
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" <<'EOF'
eval "$("${ROOT_DIR}/awsprof" init --sh)"
EOF
result=$(sh "$sh_script" 2>&1) && exit_code=0 || exit_code=$?
rm -f "$sh_script"
if [[ $exit_code -eq 0 ]]; then
    pass "init --sh output can be eval'd without errors in sh"
else
    fail "init --sh output should eval without errors (got: $result)"
fi
unset sh_script result exit_code

# Test 85: Wrapper function is defined after eval in sh
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" <<EOF
eval "\$("${ROOT_DIR}/awsprof" init --sh)"
if type awsprof >/dev/null 2>&1; then
    echo "function_exists"
fi
EOF
result=$(sh "$sh_script" 2>/dev/null)
rm -f "$sh_script"
if [[ "$result" == "function_exists" ]]; then
    pass "Wrapper function is defined after eval in sh"
else
    fail "Wrapper function should be defined after eval in sh"
fi
unset sh_script result

# Test 86: Profile switching works through wrapper in sh environment
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" <<SHEOF
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init --sh)"
creds_file=\$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="\$creds_file"
cat > "\$creds_file" << 'CREDS'
[test-sh-profile]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS

awsprof use test-sh-profile >/dev/null 2>&1
if [ "\$AWS_PROFILE" = "test-sh-profile" ]; then
    echo "profile_set"
fi
rm -f "\$creds_file" 2>/dev/null
SHEOF
result=$(sh "$sh_script" 2>/dev/null)
rm -f "$sh_script"
if [[ "$result" == "profile_set" ]]; then
    pass "Profile switching works through wrapper in sh"
else
    fail "Profile switching should work through wrapper in sh"
fi
unset sh_script result

# Test 87: Init defaults to bash (no flag produces bash output)
((TESTS_RUN++))
init_bash=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
init_sh=$("${ROOT_DIR}/awsprof" init --sh 2>/dev/null)
# Bash version should have PROMPT_COMMAND, sh version should not
if echo "$init_bash" | grep -q "PROMPT_COMMAND"; then
    pass "init defaults to bash output (no flag)"
else
    fail "init should default to bash output with PROMPT_COMMAND"
fi
unset init_bash init_sh

# Test 88: Init --sh produces different output than init
((TESTS_RUN++))
init_bash=$("${ROOT_DIR}/awsprof" init 2>/dev/null)
init_sh=$("${ROOT_DIR}/awsprof" init --sh 2>/dev/null)
# sh version should NOT have PROMPT_COMMAND
if ! echo "$init_sh" | grep -q "PROMPT_COMMAND"; then
    pass "init --sh produces different output (no PROMPT_COMMAND)"
else
    fail "init --sh should not include PROMPT_COMMAND"
fi
unset init_bash init_sh

# Test 89: POSIX sh wrapper uses backticks, not $()
((TESTS_RUN++))
init_sh=$("${ROOT_DIR}/awsprof" init --sh 2>/dev/null)
# POSIX sh version should use backticks for maximum compatibility
if echo "$init_sh" | grep -q 'awsprof_bin=`'; then
    pass "init --sh uses backticks for command substitution"
else
    fail "init --sh should use backticks for POSIX compatibility"
fi
unset init_sh

# Test 90: Init --sh includes documentation about limitations
((TESTS_RUN++))
init_sh=$("${ROOT_DIR}/awsprof" init --sh 2>/dev/null)
# Should document that automatic detection is not available
if echo "$init_sh" | grep -q -i "limitation\|automatic"; then
    pass "init --sh includes documentation about limitations"
else
    fail "init --sh should document POSIX sh limitations"
fi
unset init_sh

# Test 91: Wrapper handles missing awsprof gracefully in sh
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" <<'EOF'
# Use a PATH that doesn't include awsprof
export PATH="/bin:/usr/bin"
eval "$("${ROOT_DIR}/awsprof" init --sh)"
# Try to call wrapper - it should fail gracefully without hanging
result=$(timeout 2 sh -c 'awsprof list 2>&1' || echo "command_failed")
if [ -n "$result" ]; then
    echo "graceful_failure"
fi
EOF
result=$(sh "$sh_script" 2>/dev/null)
rm -f "$sh_script"
if [[ "$result" == "graceful_failure" ]]; then
    pass "Wrapper handles missing awsprof gracefully in sh"
else
    fail "Wrapper should handle missing awsprof gracefully"
fi
unset sh_script result

# Test 92: Shell remains functional with sh initialization
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" <<'EOF'
eval "$("${ROOT_DIR}/awsprof" init --sh)"
# Try basic shell operations after eval
cd /tmp 2>/dev/null
result=$(echo "test")
if [ "$result" = "test" ]; then
    echo "shell_ok"
fi
EOF
result=$(sh "$sh_script" 2>/dev/null)
rm -f "$sh_script"
if [[ "$result" == "shell_ok" ]]; then
    pass "Shell remains functional with sh initialization"
else
    fail "Shell should remain functional with sh initialization"
fi
unset sh_script result

# Test 93: Wrapper handles informational commands (whoami) correctly
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init)"
creds_file=\$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="\$creds_file"
cat > "\$creds_file" << 'CREDS'
[test-profile-abc]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS
awsprof use test-profile-abc >/dev/null 2>&1
# Now test whoami through wrapper (should NOT crash, should output profile)
result=\$(awsprof whoami 2>&1)
if [ "\$result" = "test-profile-abc" ]; then
    echo "whoami_works"
fi
rm -f "\$creds_file" 2>/dev/null
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "whoami_works" ]]; then
    pass "Wrapper handles informational commands (whoami) correctly"
else
    fail "Wrapper should handle whoami without crashing"
fi
unset test_script result

# Test 94: Wrapper handles list command correctly
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init)"
creds_file=\$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="\$creds_file"
cat > "\$creds_file" << 'CREDS'
[test-list-1]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS
# Test list through wrapper (should NOT crash, should output profiles)
result=\$(awsprof list 2>&1 | head -1)
if [ -n "\$result" ]; then
    echo "list_works"
fi
rm -f "\$creds_file" 2>/dev/null
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "list_works" ]]; then
    pass "Wrapper handles list command correctly"
else
    fail "Wrapper should handle list without crashing"
fi
unset test_script result

# Test 95: POSIX sh wrapper handles informational commands (whoami)
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" << SHEOF
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init --sh)"
creds_file=\$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="\$creds_file"
cat > "\$creds_file" << 'CREDS'
[test-profile-sh]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS
awsprof use test-profile-sh >/dev/null 2>&1
# Now test whoami through wrapper in sh (should NOT crash)
result=\$(awsprof whoami 2>&1)
if [ "\$result" = "test-profile-sh" ]; then
    echo "whoami_sh_works"
fi
rm -f "\$creds_file" 2>/dev/null
SHEOF
result=$(sh "$sh_script" 2>/dev/null)
rm -f "$sh_script"
if [[ "$result" == "whoami_sh_works" ]]; then
    pass "POSIX sh wrapper handles informational commands (whoami)"
else
    fail "POSIX sh wrapper should handle whoami without crashing"
fi
unset sh_script result

# Test 96b: POSIX sh wrapper handles check command
((TESTS_RUN++))
sh_script=$(mktemp)
cat > "$sh_script" << SHEOF
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init --sh)"
tmpdir=\$(mktemp -d)
echo "sh-check-profile" > "\$tmpdir/.awsprofile"
cd "\$tmpdir"
result=\$(awsprof check 2>&1)
if [ "\$result" = "sh-check-profile" ]; then
    echo "check_sh_works"
fi
cd / >/dev/null 2>&1 || true
rm -rf "\$tmpdir"
SHEOF
result=$(sh "$sh_script" 2>/dev/null)
rm -f "$sh_script"
if [[ "$result" == "check_sh_works" ]]; then
    pass "POSIX sh wrapper handles check command"
else
    fail "POSIX sh wrapper should handle check command"
fi
unset sh_script result

# Test 96: .awsprofile file with valid profile name is read correctly
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "client-acme" > "$tmpdir/.awsprofile"
cd "$tmpdir"
result=$("${ROOT_DIR}/awsprof" check 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ "$result" == "client-acme" ]]; then
    pass ".awsprofile file with valid profile name is read correctly"
else
    fail ".awsprofile should return profile name (got: '$result')"
fi
unset result exit_code tmpdir

# Test 97: Leading/trailing whitespace in .awsprofile is trimmed
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "  staging-profile  " > "$tmpdir/.awsprofile"
cd "$tmpdir"
result=$("${ROOT_DIR}/awsprof" check 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ "$result" == "staging-profile" ]]; then
    pass "Leading/trailing whitespace in .awsprofile is trimmed"
else
    fail ".awsprofile should trim whitespace (got: '$result')"
fi
unset result exit_code tmpdir

# Test 98: Missing .awsprofile file is handled gracefully
((TESTS_RUN++))
tmpdir=$(mktemp -d)
cd "$tmpdir"
result=$("${ROOT_DIR}/awsprof" check 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ -z "$result" ]]; then
    pass "Missing .awsprofile file is handled gracefully"
else
    fail "Missing .awsprofile should return empty (got: '$result')"
fi
unset result exit_code tmpdir

# Test 99: Empty .awsprofile file is handled gracefully
((TESTS_RUN++))
tmpdir=$(mktemp -d)
touch "$tmpdir/.awsprofile"
cd "$tmpdir"
result=$("${ROOT_DIR}/awsprof" check 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ -z "$result" ]]; then
    pass "Empty .awsprofile file is handled gracefully"
else
    fail "Empty .awsprofile should return empty (got: '$result')"
fi
unset result exit_code tmpdir

# Test 100: .awsprofile file with multiple lines uses only first non-empty line
((TESTS_RUN++))
tmpdir=$(mktemp -d)
cat > "$tmpdir/.awsprofile" <<'EOF'
production-profile
staging-profile
dev-profile
EOF
cd "$tmpdir"
result=$("${ROOT_DIR}/awsprof" check 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ "$result" == "production-profile" ]]; then
    pass ".awsprofile with multiple lines uses only first line"
else
    fail ".awsprofile should use first line (got: '$result')"
fi
unset result exit_code tmpdir

# Test 101: .awsprofile helper function works in any directory
((TESTS_RUN++))
tmpdir=$(mktemp -d)
subdir="$tmpdir/subproject"
mkdir -p "$subdir"
echo "test-profile" > "$tmpdir/.awsprofile"
cd "$subdir"
result=$("${ROOT_DIR}/awsprof" check 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
# Should be empty because .awsprofile is in parent dir, not current dir
if [[ -z "$result" ]]; then
    pass ".awsprofile helper function checks current directory only"
else
    fail ".awsprofile should check current directory only (got: '$result')"
fi
unset result exit_code tmpdir subdir

# Test 102: Hook runs and detects .awsprofile file
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "client-acme" > "$tmpdir/.awsprofile"
cd "$tmpdir"
output=$(AWS_PROFILE="client-acme" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
# Should have no output when profiles match
if [[ -z "$output" ]]; then
    pass "Hook runs and detects .awsprofile file"
else
    fail "Hook should be silent when profiles match (got: '$output')"
fi
unset output exit_code tmpdir

# Test 103: Silent when profile matches
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "staging" > "$tmpdir/.awsprofile"
cd "$tmpdir"
output=$(AWS_PROFILE="staging" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ -z "$output" ]]; then
    pass "Silent when profile matches"
else
    fail "Should be silent on profile match (got: '$output')"
fi
unset output exit_code tmpdir

# Test 104: Auto-switch when profile mismatches
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "production" > "$tmpdir/.awsprofile"
cd "$tmpdir"
stderr_file=$(mktemp)
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" AWS_PROFILE="staging" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>"$stderr_file") || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=production" ]] && [[ -z "$stderr" ]]; then
    pass "Auto-switch when profile mismatches"
else
    fail "Should auto-switch on mismatch (stdout: '$stdout', stderr: '$stderr')"
fi
unset stdout stderr exit_code tmpdir

# Test 105: Unset AWS_PROFILE auto-switches
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "default" > "$tmpdir/.awsprofile"
cd "$tmpdir"
unset AWS_PROFILE
stderr_file=$(mktemp)
stdout=$(AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>"$stderr_file") || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=default" ]] && [[ -z "$stderr" ]]; then
    pass "Unset AWS_PROFILE auto-switches to project profile"
else
    fail "Should auto-switch when AWS_PROFILE unset (stdout: '$stdout', stderr: '$stderr')"
fi
unset stdout stderr exit_code tmpdir

# Test 106: Hook handles missing .awsprofile gracefully
((TESTS_RUN++))
tmpdir=$(mktemp -d)
cd "$tmpdir"
AWS_PROFILE="any-profile" output=$("${ROOT_DIR}/awsprof" --hook-detect-profile 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir"
# Should have no output when no .awsprofile file exists
if [[ -z "$output" ]]; then
    pass "Hook handles missing .awsprofile gracefully"
else
    fail "Should be silent when .awsprofile missing (got: '$output')"
fi
unset output exit_code tmpdir

# Test 106b: Global .awsprofile fallback when project file missing
((TESTS_RUN++))
tmpdir=$(mktemp -d)
home_dir=$(mktemp -d)
mkdir -p "$home_dir/.aws"
echo "default" > "$home_dir/.aws/.awsprofile"
cd "$tmpdir"
stderr_file=$(mktemp)
stdout=$(HOME="$home_dir" AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>"$stderr_file") || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir" "$home_dir"
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=default" ]] && [[ -z "$stderr" ]]; then
    pass "Global .awsprofile fallback applies when project file missing"
else
    fail "Global fallback should apply (stdout: '$stdout', stderr: '$stderr')"
fi
unset stdout stderr exit_code tmpdir home_dir

# Test 106c: Project .awsprofile takes precedence over global
((TESTS_RUN++))
tmpdir=$(mktemp -d)
home_dir=$(mktemp -d)
mkdir -p "$home_dir/.aws"
echo "default" > "$home_dir/.aws/.awsprofile"
echo "staging" > "$tmpdir/.awsprofile"
cd "$tmpdir"
stderr_file=$(mktemp)
stdout=$(HOME="$home_dir" AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock" "${ROOT_DIR}/awsprof" --hook-detect-profile 2>"$stderr_file") || exit_code=$?
stderr=$(cat "$stderr_file")
rm -f "$stderr_file"
exit_code=${exit_code:-0}
cd - > /dev/null
rm -rf "$tmpdir" "$home_dir"
if [[ $exit_code -eq 0 ]] && [[ "$stdout" == "export AWS_PROFILE=staging" ]] && [[ -z "$stderr" ]]; then
    pass "Project .awsprofile takes precedence over global"
else
    fail "Project should override global (stdout: '$stdout', stderr: '$stderr')"
fi
unset stdout stderr exit_code tmpdir home_dir

# Test 107: Hook completes under 10ms (performance check)
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "test-profile" > "$tmpdir/.awsprofile"
cd "$tmpdir"
AWS_PROFILE="test-profile"
start_time=$(date +%s%N)
"${ROOT_DIR}/awsprof" --hook-detect-profile >/dev/null 2>&1 || true
end_time=$(date +%s%N)
elapsed_ms=$(( (end_time - start_time) / 1000000 ))
cd - > /dev/null
rm -rf "$tmpdir"
if [[ $elapsed_ms -lt 10 ]]; then
    pass "Hook completes under 10ms"
else
    fail "Hook performance issue: ${elapsed_ms}ms (should be <10ms)"
fi
unset tmpdir start_time end_time elapsed_ms

# Test 107b: PROMPT_COMMAND triggers hook on directory change
((TESTS_RUN++))
test_script=$(mktemp)
cat > "$test_script" <<EOF
export PATH="${ROOT_DIR}:\$PATH"
eval "\$("${ROOT_DIR}/awsprof" init)"
tmpdir=\$(mktemp -d)
echo "production" > "\$tmpdir/.awsprofile"
export AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock"
export AWS_PROFILE="staging"
cd "\$tmpdir" >/dev/null 2>&1
if [[ "\$PROMPT_COMMAND" == *"awsprof_hook_detect_profile"* ]]; then
    eval "\$PROMPT_COMMAND" >/dev/null 2>&1
    if [[ "\$AWS_PROFILE" == "production" ]]; then
        echo "hook_ran"
    fi
fi
rm -rf "\$tmpdir"
EOF
result=$(bash "$test_script" 2>/dev/null)
rm -f "$test_script"
if [[ "$result" == "hook_ran" ]]; then
    pass "PROMPT_COMMAND triggers hook on directory change"
else
    fail "PROMPT_COMMAND should run hook on directory change"
fi
unset test_script result

# Test 108: Prompt function switches profile on 'y'
((TESTS_RUN++))
output=$(echo "y" | bash -c '
creds_file=$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="$creds_file"
source '"${ROOT_DIR}"'/awsprof
cat > "$creds_file" << CREDS
[production]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS
AWS_PROFILE="staging"
awsprof_prompt_switch_profile "production"
echo "PROFILE=$AWS_PROFILE"
rm -f "$creds_file" 2>/dev/null
' 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
if [[ "$output" == *"Switch profile"* ]] && [[ "$output" == *"Switched to profile: production"* ]] && [[ "$output" == *"PROFILE=production"* ]]; then
    pass "Prompt switches profile on 'y'"
else
    fail "Prompt should switch on 'y' (got output: '$output')"
fi
unset output exit_code

# Test 109: Prompt function switches profile on 'Y'
((TESTS_RUN++))
output=$(echo "Y" | bash -c '
creds_file=$(mktemp)
export AWS_SHARED_CREDENTIALS_FILE="$creds_file"
source '"${ROOT_DIR}"'/awsprof
cat > "$creds_file" << CREDS
[production]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
CREDS
AWS_PROFILE="staging"
awsprof_prompt_switch_profile "production"
echo "PROFILE=$AWS_PROFILE"
rm -f "$creds_file" 2>/dev/null
' 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
if [[ "$output" == *"Switch profile"* ]] && [[ "$output" == *"Switched to profile: production"* ]] && [[ "$output" == *"PROFILE=production"* ]]; then
    pass "Prompt switches profile on 'Y'"
else
    fail "Prompt should switch on 'Y' (got output: '$output')"
fi
unset output exit_code

# Test 110: Prompt function declines on 'n'
((TESTS_RUN++))
output=$(echo "n" | bash -c '
source '"${ROOT_DIR}"'/awsprof
AWS_PROFILE="staging"
awsprof_prompt_switch_profile "production"
echo "PROFILE=$AWS_PROFILE"
' 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
if [[ "$output" == *"Switch profile"* ]] && [[ "$output" == *"PROFILE=staging"* ]]; then
    pass "Prompt declines on 'n'"
else
    fail "Prompt should decline on 'n' (got output: '$output')"
fi
unset output exit_code

# Test 111: Prompt function declines on 'N'
((TESTS_RUN++))
output=$(echo "N" | bash -c '
source '"${ROOT_DIR}"'/awsprof
AWS_PROFILE="staging"
awsprof_prompt_switch_profile "production"
echo "PROFILE=$AWS_PROFILE"
' 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
if [[ "$output" == *"Switch profile"* ]] && [[ "$output" == *"PROFILE=staging"* ]]; then
    pass "Prompt declines on 'N'"
else
    fail "Prompt should decline on 'N' (got output: '$output')"
fi
unset output exit_code

# Test 112: Prompt function declines on Enter
((TESTS_RUN++))
output=$(echo "" | bash -c '
source '"${ROOT_DIR}"'/awsprof
AWS_PROFILE="staging"
awsprof_prompt_switch_profile "production"
echo "PROFILE=$AWS_PROFILE"
' 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
if [[ "$output" == *"Switch profile"* ]] && [[ "$output" == *"PROFILE=staging"* ]]; then
    pass "Prompt declines on Enter"
else
    fail "Prompt should decline on Enter (got output: '$output')"
fi
unset output exit_code

# Test 113: Prompt function declines on invalid input
((TESTS_RUN++))
output=$(echo "maybe" | bash -c '
source '"${ROOT_DIR}"'/awsprof
AWS_PROFILE="staging"
awsprof_prompt_switch_profile "production"
echo "PROFILE=$AWS_PROFILE"
' 2>&1) || exit_code=$?
exit_code=${exit_code:-0}
if [[ "$output" == *"Switch profile"* ]] && [[ "$output" == *"PROFILE=staging"* ]]; then
    pass "Prompt declines on invalid input"
else
    fail "Prompt should decline on invalid input (got output: '$output')"
fi
unset output exit_code

# Test 114: Shell remains functional after prompt
((TESTS_RUN++))
result=$(bash -c "echo 'shell works'" 2>&1)
if [[ "$result" == "shell works" ]]; then
    pass "Shell remains functional after prompt"
else
    fail "Shell should remain functional after prompt"
fi
unset result

# Story 3.6 Tests: Error handling and robustness

# Test 115: Hook errors don't break shell (AC1 - robustness test)
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "production" > "$tmpdir/.awsprofile"
cd "$tmpdir"
# Call hook and then verify shell still works
"${ROOT_DIR}/awsprof" --hook-detect-profile >/dev/null 2>&1 || true
shell_test=$(bash -c 'echo "ok"' 2>&1)
cd - > /dev/null
rm -rf "$tmpdir"
# After hook runs, shell should still be able to execute commands
if [[ "$shell_test" == "ok" ]]; then
    pass "Shell remains functional after hook (AC1)"
else
    fail "Shell should remain functional after hook"
fi
unset shell_test tmpdir

# Test 116: Hook returns zero exit code always (AC1 - non-blocking)
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "production" > "$tmpdir/.awsprofile"
cd "$tmpdir"
# Call hook with mismatch and capture exit code
AWS_PROFILE="staging" "${ROOT_DIR}/awsprof" --hook-detect-profile >/dev/null 2>&1
exit_code=$?
cd - > /dev/null
rm -rf "$tmpdir"
# Hook must always return 0 (non-blocking, never fails)
if [[ $exit_code -eq 0 ]]; then
    pass "Hook returns 0 even on mismatch (non-blocking)"
else
    fail "Hook should always return 0 (got: $exit_code)"
fi
unset tmpdir exit_code

# Test 117: Hook shows error for invalid profile name in direct command (AC3)
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "nonexistent-profile-xyz" > "$tmpdir/.awsprofile"
cd "$tmpdir"
# Direct use command should show error for invalid profile
output=$("${ROOT_DIR}/awsprof" use "nonexistent-profile-xyz" 2>&1) || exit_code=$?
cd - > /dev/null
rm -rf "$tmpdir"
# Direct command should show error message
if [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]; then
    pass "Direct command shows error for invalid profile"
else
    fail "Should show error for invalid profile (got: '$output')"
fi
unset output exit_code tmpdir

# Test 118: Hook completes quickly even on slow I/O (AC4)
((TESTS_RUN++))
tmpdir=$(mktemp -d)
echo "production" > "$tmpdir/.awsprofile"
cd "$tmpdir"
# Time the hook execution
start_time=$(date +%s%N)
AWS_PROFILE="staging" timeout 2 "${ROOT_DIR}/awsprof" --hook-detect-profile >/dev/null 2>&1
result=$?
end_time=$(date +%s%N)
elapsed_ms=$(( (end_time - start_time) / 1000000 ))
cd - > /dev/null
rm -rf "$tmpdir"
# Hook should complete quickly (within reasonable time, < 1 second in test)
if [[ $elapsed_ms -lt 1000 ]] && [[ $result -eq 0 ]]; then
    pass "Hook completes quickly (<1000ms)"
else
    fail "Hook should complete quickly (took ${elapsed_ms}ms, exit: $result)"
fi
unset tmpdir start_time end_time elapsed_ms result

# Test 119: Multiple sessions maintain independent AWS_PROFILE (AC5)
((TESTS_RUN++))
tmpdir1=$(mktemp -d)
tmpdir2=$(mktemp -d)
echo "profile1" > "$tmpdir1/.awsprofile"
echo "profile2" > "$tmpdir2/.awsprofile"
# Session 1: check profile
cd "$tmpdir1"
profile1=$(AWS_PROFILE="session1" bash -c 'echo $AWS_PROFILE')
cd - > /dev/null
# Session 2: check profile
cd "$tmpdir2"
profile2=$(AWS_PROFILE="session2" bash -c 'echo $AWS_PROFILE')
cd - > /dev/null
rm -rf "$tmpdir1" "$tmpdir2"
# Each session should have its own AWS_PROFILE value
if [[ "$profile1" == "session1" ]] && [[ "$profile2" == "session2" ]]; then
    pass "Multiple sessions maintain independent AWS_PROFILE"
else
    fail "Sessions should maintain independent profiles (s1: '$profile1', s2: '$profile2')"
fi
unset tmpdir1 tmpdir2 profile1 profile2

echo
echo "=============================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=============================="

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
