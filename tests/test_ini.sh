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

#=== FILE OPERATIONS TESTS ===

# Test 9: Backup creates timestamped file
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_backup_source.tmp"
echo "[test]" > "$test_file"
echo "key=value" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_backup_credentials 2>/dev/null && backup_exit=0 || backup_exit=$?
backup_created=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
if [[ $backup_exit -eq 0 ]] && [[ $backup_created -ge 1 ]]; then
    backup_file=$(ls -t "${test_file}.bak."* 2>/dev/null | head -n 1)
    if [[ "$backup_file" =~ \.bak\.[0-9]{8}-[0-9]{6}$ ]]; then
        pass "awsprof_backup_credentials creates timestamped backup"
    else
        fail "awsprof_backup_credentials backup format incorrect: $backup_file"
    fi
else
    fail "awsprof_backup_credentials did not create backup"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 10: Backup preserves file contents
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_backup_content.tmp"
original_content="[default]
aws_access_key_id=TEST123
aws_secret_access_key=SECRET456"
echo "$original_content" > "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_backup_credentials 2>/dev/null
backup_file=$(ls -t "${test_file}.bak."* 2>/dev/null | head -n 1)
backup_content=$(cat "$backup_file" 2>/dev/null)
if [[ "$backup_content" == "$original_content" ]]; then
    pass "awsprof_backup_credentials preserves file contents"
else
    fail "awsprof_backup_credentials backup content mismatch"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 11: Write section adds new section
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_write_add.tmp"
echo "[existing]" > "$test_file"
echo "key=value" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "newsection" "aws_access_key_id=NEWKEY123" "aws_secret_access_key=NEWSECRET456" 2>/dev/null
result=$(grep -A2 "^\[newsection\]" "$test_file" 2>/dev/null)
if [[ "$result" == *"NEWKEY123"* ]] && [[ "$result" == *"NEWSECRET456"* ]]; then
    pass "awsprof_ini_write_section adds new section"
else
    fail "awsprof_ini_write_section failed to add new section"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 12: Write section updates existing section
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_write_update.tmp"
echo "[default]" > "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "aws_secret_access_key=OLDSECRET" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "default" "aws_access_key_id=UPDATED123" "aws_secret_access_key=UPDATEDSECRET456" 2>/dev/null
result=$(grep -A2 "^\[default\]" "$test_file" 2>/dev/null)
if [[ "$result" == *"UPDATED123"* ]] && [[ "$result" == *"UPDATEDSECRET456"* ]] && [[ "$result" != *"OLDKEY"* ]]; then
    pass "awsprof_ini_write_section updates existing section"
else
    fail "awsprof_ini_write_section failed to update section"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 13: Write section preserves other sections
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_write_preserve.tmp"
echo "[section1]" > "$test_file"
echo "key1=value1" >> "$test_file"
echo "" >> "$test_file"
echo "[section2]" >> "$test_file"
echo "key2=value2" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "section1" "key1=newvalue1" 2>/dev/null
section2_preserved=$(grep -A1 "^\[section2\]" "$test_file" 2>/dev/null | grep "key2=value2")
if [[ -n "$section2_preserved" ]]; then
    pass "awsprof_ini_write_section preserves other sections"
else
    fail "awsprof_ini_write_section damaged other sections"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 14: Write section preserves comments
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_write_comments.tmp"
echo "# Important comment" > "$test_file"
echo "[default]" >> "$test_file"
echo "key=value" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "default" "key=newvalue" 2>/dev/null
comment_preserved=$(grep "# Important comment" "$test_file" 2>/dev/null)
if [[ -n "$comment_preserved" ]]; then
    pass "awsprof_ini_write_section preserves comments"
else
    fail "awsprof_ini_write_section lost comments"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 15: Delete section removes target only
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_delete_section.tmp"
echo "[section1]" > "$test_file"
echo "key1=value1" >> "$test_file"
echo "" >> "$test_file"
echo "[section2]" >> "$test_file"
echo "key2=value2" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_delete_section "section1" 2>/dev/null
section1_gone=$(grep "^\[section1\]" "$test_file" 2>/dev/null)
section2_preserved=$(grep -A1 "^\[section2\]" "$test_file" 2>/dev/null | grep "key2=value2")
if [[ -z "$section1_gone" ]] && [[ -n "$section2_preserved" ]]; then
    pass "awsprof_ini_delete_section removes target section only"
else
    fail "awsprof_ini_delete_section incorrect deletion"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 16: Delete section preserves formatting
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_delete_formatting.tmp"
echo "# Header comment" > "$test_file"
echo "[section1]" >> "$test_file"
echo "key1=value1" >> "$test_file"
echo "" >> "$test_file"
echo "# Section 2 comment" >> "$test_file"
echo "[section2]" >> "$test_file"
echo "key2=value2" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_delete_section "section1" 2>/dev/null
comment1_preserved=$(grep "# Header comment" "$test_file" 2>/dev/null)
comment2_preserved=$(grep "# Section 2 comment" "$test_file" 2>/dev/null)
if [[ -n "$comment1_preserved" ]] && [[ -n "$comment2_preserved" ]]; then
    pass "awsprof_ini_delete_section preserves formatting"
else
    fail "awsprof_ini_delete_section lost formatting"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 17: Atomic write sets chmod 600
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_chmod.tmp"
echo "[test]" > "$test_file"
chmod 644 "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "test" "key=value" 2>/dev/null
perms=$(stat -c "%a" "$test_file" 2>/dev/null || stat -f "%A" "$test_file" 2>/dev/null)
if [[ "$perms" == "600" ]]; then
    pass "awsprof_ini_write_section sets chmod 600"
else
    fail "awsprof_ini_write_section permissions incorrect: $perms"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 18: Write preserves comments and blank lines inside target section
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_write_inside_formatting.tmp"
echo "[default]" > "$test_file"
echo "# inside comment" >> "$test_file"
echo "" >> "$test_file"
echo "aws_access_key_id=OLDKEY" >> "$test_file"
echo "" >> "$test_file"
echo "; inside semicolon" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "default" "aws_access_key_id=NEWKEY" 2>/dev/null
inside_comment=$(grep "# inside comment" "$test_file" 2>/dev/null)
inside_semicolon=$(grep "; inside semicolon" "$test_file" 2>/dev/null)
if [[ -n "$inside_comment" ]] && [[ -n "$inside_semicolon" ]]; then
    pass "awsprof_ini_write_section preserves formatting inside section"
else
    fail "awsprof_ini_write_section lost formatting inside section"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 19: Delete section removes entire section including comments/blank lines
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_delete_full.tmp"
echo "[target]" > "$test_file"
echo "# comment in section" >> "$test_file"
echo "" >> "$test_file"
echo "key=value" >> "$test_file"
echo "" >> "$test_file"
echo "[other]" >> "$test_file"
echo "keep=me" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_delete_section "target" 2>/dev/null
target_gone=$(grep "^\[target\]" "$test_file" 2>/dev/null)
target_comment_gone=$(grep "comment in section" "$test_file" 2>/dev/null)
other_present=$(grep -A1 "^\[other\]" "$test_file" 2>/dev/null | grep "keep=me")
if [[ -z "$target_gone" ]] && [[ -z "$target_comment_gone" ]] && [[ -n "$other_present" ]]; then
    pass "awsprof_ini_delete_section removes full section"
else
    fail "awsprof_ini_delete_section did not remove full section"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 20: CRLF line endings preserved on write
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_crlf.tmp"
printf "[default]\r\naws_access_key_id=OLD\r\n" > "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "default" "aws_access_key_id=NEW" 2>/dev/null
if LC_ALL=C grep -q $'\r' "$test_file" && LC_ALL=C grep -q $'aws_access_key_id=NEW\r' "$test_file"; then
    pass "awsprof_ini_write_section preserves CRLF line endings"
else
    fail "awsprof_ini_write_section did not preserve CRLF line endings"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 21: Unicode section names and values
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_unicode.tmp"
echo "[existing]" > "$test_file"
unicode_section=$'unicode_\u2603'
unicode_value=$'value_\u00e9'
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "$unicode_section" "key=${unicode_value}" 2>/dev/null
unicode_found=$(grep -A1 "^\[$unicode_section\]" "$test_file" 2>/dev/null | grep "$unicode_value")
if [[ -n "$unicode_found" ]]; then
    pass "awsprof_ini_write_section handles unicode"
else
    fail "awsprof_ini_write_section failed unicode handling"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 22: Special characters in values preserved
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_special_chars.tmp"
echo "[default]" > "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "default" "key=va#l;ue=with=equals" 2>/dev/null
special_found=$(grep -A1 "^\[default\]" "$test_file" 2>/dev/null | grep "key=va#l;ue=with=equals")
if [[ -n "$special_found" ]]; then
    pass "awsprof_ini_write_section preserves special characters"
else
    fail "awsprof_ini_write_section lost special characters"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 23: Malformed file handling creates backup and proceeds
((TESTS_RUN++))
test_file="${SCRIPT_DIR}/fixtures/test_malformed_write.tmp"
echo "[default" > "$test_file"
echo "key=value" >> "$test_file"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
awsprof_ini_write_section "newsection" "key=newvalue" 2>/dev/null && write_exit=0 || write_exit=$?
backup_created=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
if [[ $backup_created -ge 1 ]] && [[ $write_exit -eq 0 ]]; then
    pass "awsprof_ini_write_section handles malformed file with backup"
else
    fail "awsprof_ini_write_section malformed handling failed"
fi
rm -f "$test_file" "${test_file}.bak."* 2>/dev/null
unset AWS_SHARED_CREDENTIALS_FILE

# Test 24: Temp file creation failure leaves original unchanged
((TESTS_RUN++))
temp_dir=$(mktemp -d)
test_file="${temp_dir}/credentials"
echo "[default]" > "$test_file"
echo "key=value" >> "$test_file"
chmod 500 "$temp_dir"
export AWS_SHARED_CREDENTIALS_FILE="$test_file"
orig_checksum=$(cksum "$test_file" | awk '{print $1}')
awsprof_ini_write_section "default" "key=newvalue" 2>/dev/null && write_exit=0 || write_exit=$?
new_checksum=$(cksum "$test_file" | awk '{print $1}')
if [[ $write_exit -ne 0 ]] && [[ "$orig_checksum" == "$new_checksum" ]]; then
    pass "awsprof_ini_write_section fails safely when temp file cannot be created"
else
    fail "awsprof_ini_write_section did not fail safely on temp file error"
fi
chmod 700 "$temp_dir"
rm -rf "$temp_dir"
unset AWS_SHARED_CREDENTIALS_FILE

echo
echo "=============================="
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "=============================="

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
