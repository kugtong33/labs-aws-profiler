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
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add duplicate 2>&1) && exit_code=0 || exit_code=$?
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
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add newprofile 2>&1) && exit_code=0 || exit_code=$?
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
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add newprofile 2>&1) && exit_code=0 || exit_code=$?
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
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add integration-test 2>/dev/null
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
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" add switch-test 2>/dev/null
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

#=== EDIT COMMAND TESTS ===

# Test 27: edit existing profile successfully
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

# Test 28: edit non-existent profile rejection
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_noexist.tmp"
echo "[existing]" > "$test_file"
echo "key=value" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit nonexistent 2>&1) && exit_code=0 || exit_code=$?
if [[ $exit_code -eq 1 ]] && [[ "$result" == *"not found"* ]]; then
    pass "awsprof edit rejects non-existent profile"
else
    fail "awsprof edit should reject non-existent profile (exit=$exit_code)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 29: edit missing profile name parameter
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

# Test 30: edit with empty access key
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

# Test 31: edit with empty secret key
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

# Test 32: edit preserves other profiles
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_preserve.tmp"
echo "[profile1]" > "$test_file"
echo "aws_access_key_id=KEY1" >> "$test_file"
echo "aws_secret_access_key=SECRET1" >> "$test_file"
echo "" >> "$test_file"
echo "[profile2]" >> "$test_file"
echo "aws_access_key_id=KEY2" >> "$test_file"
echo "aws_secret_access_key=SECRET2" >> "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit profile1 2>&1) && exit_code=0 || exit_code=$?
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

# Test 33: edit sets chmod 600
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_chmod.tmp"
echo "[testprofile]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
chmod 644 "$test_file"
result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit testprofile 2>&1) && exit_code=0 || exit_code=$?
perms=$(stat -c "%a" "$test_file" 2>/dev/null || stat -f "%A" "$test_file" 2>/dev/null)
if [[ $exit_code -eq 0 ]] && [[ "$perms" == "600" ]]; then
    pass "awsprof edit sets chmod 600"
else
    fail "awsprof edit should set chmod 600 (perms=$perms)"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset exit_code

# Test 34: edit never displays secret in output
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

# Test 35: integration - edit then list
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_list.tmp"
echo "[tolist]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit tolist 2>/dev/null
list_result=$(AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" list 2>/dev/null)
if [[ "$list_result" == *"tolist"* ]]; then
    pass "awsprof edit then list shows profile"
else
    fail "awsprof list should show edited profile"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null

# Test 36: integration - edit then use
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_edit_use.tmp"
echo "[touse]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | AWS_SHARED_CREDENTIALS_FILE="$test_file" "${ROOT_DIR}/awsprof" edit touse 2>/dev/null
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

echo
echo "=============================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=============================="

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
