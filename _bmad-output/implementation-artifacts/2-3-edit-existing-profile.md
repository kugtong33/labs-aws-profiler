# Story 2.3: Edit Existing Profile

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to update credentials for an existing profile,
So that I can rotate keys without losing the profile configuration.

## Acceptance Criteria

### AC1: Prompt for new credentials with hidden input

**Given** a profile named "client-acme" exists
**When** the user runs `awsprof edit client-acme`
**Then** the command prompts for new Access Key ID
**And** prompts for new Secret Access Key with hidden input (FR32, NFR5)
**And** updates the profile in `~/.aws/credentials` (FR2)

### AC2: Update profile with safety mechanisms

**Given** the user provides new credentials
**When** the profile is updated
**Then** a timestamped backup is created first (NFR11)
**And** only the specified profile's credentials are changed (FR6)
**And** all other profiles remain unchanged
**And** file permissions are set to 600 (NFR8)
**And** the secret key is never displayed (FR33, NFR6)

### AC3: Reject non-existent profiles

**Given** the user attempts to edit a non-existent profile "foo"
**When** the command is executed
**Then** an error is displayed: "Error: Profile 'foo' not found" (FR29)
**And** the command exits with status code 1 (FR28)

### AC4: Validate credential format

**Given** the user provides invalid credential format
**When** validation occurs
**Then** the credentials are rejected (FR31)
**And** the original profile remains unchanged
**And** a clear error message is shown

## Tasks / Subtasks

- [ ] Implement `awsprof_cmd_edit()` command function (AC: #1, #2, #3, #4)
  - [ ] Validate profile name parameter provided
  - [ ] Check if profile exists (reject non-existent)
  - [ ] Prompt for new AWS Access Key ID
  - [ ] Prompt for new AWS Secret Access Key with hidden input (`read -s`)
  - [ ] Validate credential format (non-empty, basic format check)
  - [ ] Call `awsprof_ini_write_section()` to update profile
  - [ ] Display success message to stderr
  - [ ] Return appropriate exit codes

- [ ] Add `edit` command to main dispatch (AC: #1)
  - [ ] Add case statement entry for `edit`
  - [ ] Call `awsprof_cmd_edit` with profile name parameter
  - [ ] Update help text to include `edit` command

- [ ] Write comprehensive tests (AC: #1, #2, #3, #4)
  - [ ] Test edit existing profile successfully
  - [ ] Test non-existent profile rejection
  - [ ] Test missing profile name parameter
  - [ ] Test credential validation (empty values)
  - [ ] Test other profiles preserved
  - [ ] Test backup created before write
  - [ ] Test chmod 600 on credentials file
  - [ ] Test secret key never displayed in output
  - [ ] Test integration: edit profile, then use to verify
  - [ ] Test integration: edit profile, then list to verify still exists

## Dev Notes

### Critical Context from Stories 2.1 and 2.2

**What Was Just Built (Story 2.2 - commit 28aa95f):**
- ✅ `awsprof_cmd_add()` - Interactive profile creation
- ✅ Pattern for credential prompting (visible + hidden input)
- ✅ Duplicate checking logic
- ✅ Validation pattern (non-empty, format checking)
- ✅ 10 comprehensive tests for add command
- ✅ All 43 tests passing (17 INI + 26 command)

**Git Commits:**
- `28aa95f` - Story 2.2 (Add New Profile)
- `75be05e` - Story 2.1 (INI File Writing & Backup Safety)

**KEY INSIGHT from Story 2.2:**
Story 2.3 is **almost identical** to Story 2.2! The only difference:
- **Add:** Check profile does NOT exist (reject duplicates)
- **Edit:** Check profile DOES exist (reject non-existent)

Both use the same `awsprof_ini_write_section()` function which handles:
- ✅ Creating new sections (add)
- ✅ Updating existing sections (edit)

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Command Pattern (Same as Add):**
```bash
awsprof_cmd_edit() {
    local profile_name="$1"

    # Validation...
    # Check EXISTS (opposite of add)...
    # Prompt for input...
    # Call write function...
    # Success message...

    return 0
}
```

**Critical Patterns to Follow:**
1. **Function naming**: `awsprof_cmd_edit` (follows `awsprof_cmd_<command>` pattern)
2. **Messages to stderr**: All user output via `awsprof_msg()`, `awsprof_error()`, `awsprof_success()`
3. **Exit codes**: 0 for success, 1 for any error
4. **Hidden input**: Use `read -s` for secret access key

### Technical Implementation Guidance

**Implementation Sequence:**

1. **Add `awsprof_cmd_edit()` function** to PROFILE COMMANDS section

2. **Core Logic Flow (Compare to Add):**

**Story 2.2 (Add) Logic:**
```bash
awsprof_cmd_add() {
    local profile_name="$1"

    # Validate parameter
    if [[ -z "$profile_name" ]]; then
        awsprof_error "Profile name required"
        return 1
    fi

    # Check does NOT exist
    profiles=$(awsprof_ini_list_sections 2>/dev/null) || profiles=""
    if echo "$profiles" | grep -qx "$profile_name"; then
        awsprof_error "Profile '$profile_name' already exists. Use 'awsprof edit' to modify."
        return 1
    fi

    # Prompt for credentials
    # Validate
    # Write with awsprof_ini_write_section
}
```

**Story 2.3 (Edit) Logic:**
```bash
awsprof_cmd_edit() {
    local profile_name="$1"

    # Validate parameter (SAME)
    if [[ -z "$profile_name" ]]; then
        awsprof_error "Profile name required"
        awsprof_msg "Usage: awsprof edit <profile-name>"
        return 1
    fi

    # Check DOES exist (OPPOSITE)
    local profiles
    profiles=$(awsprof_ini_list_sections 2>/dev/null) || profiles=""
    if ! echo "$profiles" | grep -qx "$profile_name"; then
        awsprof_error "Profile '$profile_name' not found"
        return 1
    fi

    # Prompt for credentials (SAME)
    awsprof_msg "Editing profile: $profile_name"
    local access_key_id
    local secret_access_key
    read -p "AWS Access Key ID: " access_key_id
    read -s -p "AWS Secret Access Key: " secret_access_key
    echo  # Newline after hidden input

    # Validate credentials (SAME)
    if [[ -z "$access_key_id" ]] || [[ -z "$secret_access_key" ]]; then
        awsprof_error "Access Key ID and Secret Access Key are required"
        return 1
    fi

    # Basic format validation (SAME)
    if [[ ! "$access_key_id" =~ ^AK[A-Z0-9]{18}$ ]]; then
        awsprof_warn "Access Key ID format may be invalid (expected AKIA... format)"
    fi

    # Write profile using Story 2.1 function (SAME)
    # This function handles BOTH add and edit!
    if ! awsprof_ini_write_section "$profile_name" \
        "aws_access_key_id=$access_key_id" \
        "aws_secret_access_key=$secret_access_key"; then
        awsprof_error "Failed to update profile"
        return 1
    fi

    # Success message (DIFFERENT MESSAGE)
    awsprof_success "Profile '$profile_name' updated successfully"

    return 0
}
```

**Key Difference Summary:**
- **Line ~15:** `if echo "$profiles" | grep -qx "$profile_name"` becomes `if ! echo "$profiles" | grep -qx "$profile_name"`
- **Error message:** "already exists" becomes "not found"
- **Success message:** "added successfully" becomes "updated successfully"
- **Everything else is identical!**

3. **Add to main dispatch:**
   ```bash
   case "${1:-}" in
       edit)
           awsprof_cmd_edit "${2:-}"
           exit $?
           ;;
       # ... other commands
   esac
   ```

4. **Update help text:**
   ```bash
   awsprof_msg "  edit <profile>    Edit an existing AWS profile"
   ```

### Testing Requirements

**Unit Tests (add to `tests/test_commands.sh`):**

Based on Story 2.2's pattern (10 tests), add similar tests for edit:

1. **Test: Edit existing profile successfully**
   - Create profile first
   - Edit with new credentials
   - Verify credentials updated
   - Verify backup created

2. **Test: Non-existent profile rejection**
   - Attempt to edit "nonexistent-profile"
   - Verify error message contains "not found"
   - Verify exit code 1

3. **Test: Missing profile name**
   - Run `awsprof edit` without parameter
   - Verify error message
   - Verify exit code 1

4. **Test: Empty credentials**
   - Provide empty access key or secret
   - Verify rejection
   - Verify error message
   - Verify original profile unchanged

5. **Test: Other profiles preserved**
   - Start with file containing multiple profiles
   - Edit one profile
   - Verify all other profiles unchanged

6. **Test: Backup created**
   - Edit profile
   - Verify `.bak.YYYYMMDD-HHMMSS` file exists

7. **Test: chmod 600 enforced**
   - Edit profile
   - Verify file permissions are 600

8. **Test: Secret never displayed**
   - Capture all output (stdout + stderr)
   - Verify secret key not in output

9. **Integration: Edit then use**
   - Edit profile with new credentials
   - Run `awsprof use <profile>`
   - Verify switch succeeds

10. **Integration: Edit then list**
    - Edit profile
    - Run `awsprof list`
    - Verify profile still appears in list

**Test Pattern Example (Adapted from Story 2.2):**
```bash
# Test: Edit existing profile successfully
test_edit_existing_profile() {
    test_file="${SCRIPT_DIR}/fixtures/test_edit.tmp"
    echo "[testprofile]" > "$test_file"
    echo "aws_access_key_id=OLDKEY123" >> "$test_file"
    echo "aws_secret_access_key=OLDSECRET456" >> "$test_file"
    export AWS_SHARED_CREDENTIALS_FILE="$test_file"

    # Simulate user input with NEW credentials
    result=$(echo -e "AKIAIOSFODNN7EXAMPLE\nwJalrXUtnFEMI/K7MDENG" | "${ROOT_DIR}/awsprof" edit testprofile 2>&1)
    exit_code=$?

    # Verify success
    [[ $exit_code -eq 0 ]] || fail "Exit code should be 0"
    [[ "$result" == *"updated successfully"* ]] || fail "Missing success message"

    # Verify credentials were updated (not old values)
    new_key=$(grep "aws_access_key_id=AKIAIOSFODNN7EXAMPLE" "$test_file")
    old_key=$(grep "OLDKEY123" "$test_file")
    [[ -n "$new_key" ]] || fail "New key not in file"
    [[ -z "$old_key" ]] || fail "Old key still in file"

    # Verify backup created
    backup_count=$(ls "${test_file}.bak."* 2>/dev/null | wc -l)
    [[ $backup_count -ge 1 ]] || fail "Backup not created"

    rm -f "$test_file" "${test_file}.bak."*
    unset AWS_SHARED_CREDENTIALS_FILE
    pass "awsprof edit updates existing profile"
}
```

### Dependencies and Blockers

**Depends On:**
- ✅ Story 2.1 - INI writing and backup functions (COMPLETE - commit 75be05e)
- ✅ Story 2.2 - Add command pattern established (COMPLETE - commit 28aa95f)
- ✅ Story 1.1 - INI reading for existence check (COMPLETE)

**Blocks:**
- ⏳ Story 2.4 - Remove Profile (different pattern, uses delete function)
- ⏳ Story 2.5 - Import Existing Profiles

**No Blockers:** All dependencies complete.

### File Modifications Required

```
labs-aws-profiler/
├── awsprof                     # THIS STORY: Add 'edit' command
│   ├── #=== PROFILE COMMANDS ===
│   │   ├── awsprof_cmd_list (Epic 1)
│   │   ├── awsprof_cmd_use (Epic 1)
│   │   ├── awsprof_cmd_whoami (Epic 1)
│   │   ├── awsprof_cmd_add (Story 2.2)
│   │   └── awsprof_cmd_edit (NEW)
│   └── #=== MAIN DISPATCH ===
│       └── Add 'edit' case entry (NEW)
└── tests/
    └── test_commands.sh        # THIS STORY: Add 'edit' command tests
```

### Security and Safety Checklist

**CRITICAL - MUST BE VERIFIED:**
- [ ] Secret key input uses `read -s` (hidden)
- [ ] Secret key never echoed to terminal
- [ ] Secret key never appears in error messages
- [ ] Backup created before write (via `awsprof_ini_write_section`)
- [ ] chmod 600 enforced (via `awsprof_ini_write_section`)
- [ ] Non-existent profile check prevents errors
- [ ] Empty credential validation
- [ ] Exit codes correct (0=success, 1=error)
- [ ] Original profile unchanged on validation failure

### Learnings from Story 2.2

**From Story 2.2 Implementation (commit 28aa95f):**
- ✅ Pattern works well - interactive prompting is user-friendly
- ✅ `awsprof_ini_write_section()` handles both add and update seamlessly
- ✅ Hidden input with `read -s` is secure and tested
- ✅ Validation pattern (empty check + format warning) is comprehensive
- ✅ Test pattern is established and easy to adapt

**Code Reuse:**
Story 2.3 can reuse 95% of Story 2.2's code! Only changes:
1. Existence check (does exist vs doesn't exist)
2. Error messages ("not found" vs "already exists")
3. Success message ("updated" vs "added")

**Estimated Implementation Time:**
- ~20 minutes (vs 40 minutes for Story 2.2)
- Most time will be copy-paste-adapt from Story 2.2
- Tests follow same pattern

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3: Edit Existing Profile]
- [Source: _bmad-output/planning-artifacts/architecture.md#Command Boundary]
- [Source: _bmad-output/planning-artifacts/prd.md#FR2, FR6, FR31-33]
- [Source: _bmad-output/implementation-artifacts/2-1-ini-file-writing-backup-safety.md#Write Functions]
- [Source: _bmad-output/implementation-artifacts/2-2-add-new-profile.md#Command Implementation]

## Dev Agent Record

### Agent Model Used

(To be filled by dev agent)

### Debug Log References

(To be filled by dev agent)

### Completion Notes List

(To be filled by dev agent)

### File List

(To be filled by dev agent)
