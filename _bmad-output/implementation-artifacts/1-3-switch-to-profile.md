# Story 1.3: Switch to Profile

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to switch to a specific AWS profile by name,
So that my AWS CLI commands target the correct account.

## Acceptance Criteria

### AC1: Successfully switch to existing profile

**Given** the user has a profile named "client-acme" in their credentials
**When** the user runs `eval "$(awsprof use client-acme)"`
**Then** the `AWS_PROFILE` environment variable is set to "client-acme" (FR11)
**And** stdout contains `export AWS_PROFILE=client-acme` for eval (FR26)
**And** stderr displays "Switched to profile: client-acme" (FR12)
**And** the command exits with status code 0 (FR27)

### AC2: Reject non-existent profile

**Given** the user attempts to switch to a non-existent profile "foo"
**When** the user runs `awsprof use foo`
**Then** the command validates the profile exists first (FR30)
**And** displays "Error: Profile 'foo' not found" to stderr (FR13, FR29)
**And** does not output any eval code to stdout
**And** exits with status code 1 (FR28)

### AC3: Require profile name parameter

**Given** the user runs `awsprof use` without providing a profile name
**When** the command is executed
**Then** a clear usage error is displayed to stderr (FR29)
**And** exits with status code 1 (FR28)

### AC4: Performance requirement

**Given** the credentials file is accessible and valid
**When** the user switches profiles
**Then** the operation completes in under 100ms (NFR1)

## Tasks / Subtasks

- [x] Implement `awsprof_cmd_use()` command function (AC: #1, #2, #3, #4)
  - [x] Create function following naming convention
  - [x] Validate profile name parameter provided
  - [x] Validate profile exists using `awsprof_ini_list_sections()`
  - [x] Output `export AWS_PROFILE=<name>` to stdout for eval
  - [x] Output success message to stderr
  - [x] Handle missing profile with clear error
  - [x] Return appropriate exit codes

- [x] Add `use` command to main dispatch (AC: #1)
  - [x] Add case statement entry for `use`
  - [x] Pass profile name parameter to command function
  - [x] Update help text to include `use` command

- [x] Write unit tests for use command (AC: #1, #2, #3, #4)
  - [x] Test switching to valid profile
  - [x] Test switching to non-existent profile
  - [x] Test missing profile parameter
  - [x] Test eval output format (stdout)
  - [x] Test success message format (stderr)
  - [x] Verify exit codes

- [x] Add integration test for end-to-end workflow (AC: #1, #4)
  - [x] Test eval pattern: `eval "$(./awsprof use profile)"`
  - [x] Verify AWS_PROFILE is set in current shell
  - [x] Verify performance (<100ms)

## Dev Notes

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Critical Implementation Rules:**

1. **Eval Output Pattern** (MOST IMPORTANT for Story 1.3)
   - **stdout:** ONLY executable shell code (`export AWS_PROFILE=name`)
   - **stderr:** User messages ("Switched to profile: name")
   - This enables: `eval "$(awsprof use profile)"` to set env var in current shell
   - Example:
     ```bash
     # Command: awsprof use staging
     # stdout: export AWS_PROFILE=staging
     # stderr: Switched to profile: staging
     ```

2. **Command Structure**
   - Function name: `awsprof_cmd_use()` (follows pattern from Story 1.2)
   - Takes profile name as first parameter
   - Location: `#=== PROFILE COMMANDS ===` section

3. **Profile Validation** (FR30)
   - Must validate profile exists before switching
   - Use `awsprof_ini_list_sections()` from Story 1.1
   - Check if provided name is in the list
   - No eval output on error (keeps shell clean)

4. **Exit Codes**
   - 0: Profile switched successfully (FR27)
   - 1: Profile not found or missing parameter (FR28)

5. **Performance Requirements**
   - Must complete in <100ms (NFR1)
   - `awsprof_ini_list_sections()` already optimized

### Technical Requirements

**Dependencies on Previous Stories:**
- ✅ Story 1.1: `awsprof_ini_list_sections()` - for profile validation
- ✅ Story 1.1: `awsprof_error()`, `awsprof_success()` - for messages
- ✅ Story 1.2: Command pattern established
- ✅ Story 1.2: Main dispatch structure exists
- ✅ Story 1.2: Test infrastructure (`tests/test_commands.sh`)

**Implementation Approach:**
Story 1.3 introduces the critical eval pattern that enables environment variable export to the parent shell.

### Implementation Pattern

**Command Function Template:**
```bash
#=== PROFILE COMMANDS ===
awsprof_cmd_use() {
    local profile_name="$1"

    # Validate parameter provided
    if [[ -z "$profile_name" ]]; then
        awsprof_error "Profile name required"
        awsprof_msg "Usage: awsprof use <profile-name>"
        return 1
    fi

    # Validate profile exists
    local profiles
    profiles=$(awsprof_ini_list_sections 2>/dev/null) || return 1

    if ! echo "$profiles" | grep -qx "$profile_name"; then
        awsprof_error "Profile '$profile_name' not found"
        return 1
    fi

    # Output eval code to stdout
    echo "export AWS_PROFILE=$profile_name"

    # Output success message to stderr
    awsprof_success "Switched to profile: $profile_name"

    return 0
}
```

**Main Dispatch Addition:**
```bash
case "${1:-}" in
    list)
        awsprof_cmd_list
        exit $?
        ;;
    use)
        awsprof_cmd_use "$2"
        exit $?
        ;;
    help|--help|-h|"")
        # Update help text to include 'use'
        ;;
esac
```

### File Structure (Modifications)

```
labs-aws-profiler/
├── awsprof                     # THIS STORY: Add use command
└── tests/
    ├── test_commands.sh        # THIS STORY: Add use command tests
    ├── test_ini.sh             # From Story 1.1: Existing
    └── fixtures/
        ├── credentials.mock    # From Story 1.1: Reuse
        └── credentials_empty.mock  # From Story 1.2: Reuse
```

### Testing Standards

**Test Pattern (from Stories 1.1 & 1.2):**
- Add tests to existing `tests/test_commands.sh`
- Simple bash assertions
- Test both success and error cases

**New Tests to Add:**
```bash
# Test valid profile switch
test_use_valid_profile() {
    result=$(./awsprof use default 2>&1)
    # Check stdout has export statement
    [[ "$result" == *"export AWS_PROFILE=default"* ]] || fail
    # Check stderr has success message
    [[ "$result" == *"Switched to profile: default"* ]] || fail
    pass "awsprof use switches to valid profile"
}

# Test non-existent profile
test_use_nonexistent_profile() {
    result=$(./awsprof use nonexistent 2>&1)
    exit_code=$?
    [[ $exit_code -eq 1 ]] || fail
    [[ "$result" == *"not found"* ]] || fail
    # Should not have export statement
    [[ "$result" != *"export"* ]] || fail
    pass "awsprof use rejects non-existent profile"
}

# Test missing parameter
test_use_missing_parameter() {
    result=$(./awsprof use 2>&1)
    exit_code=$?
    [[ $exit_code -eq 1 ]] || fail
    [[ "$result" == *"required"* ]] || fail
    pass "awsprof use requires profile name"
}

# Test eval integration
test_use_eval_integration() {
    # Test that eval actually sets the variable
    (
        eval "$(./awsprof use default 2>/dev/null)"
        [[ "$AWS_PROFILE" == "default" ]] || exit 1
    )
    [[ $? -eq 0 ]] || fail
    pass "awsprof use works with eval pattern"
}
```

### Previous Story Intelligence

**Learnings from Story 1.1:**
- ✅ INI parsing works and is tested
- ✅ `awsprof_ini_list_sections()` returns newline-separated profile names
- ✅ Output utilities working properly

**Learnings from Story 1.2:**
- ✅ Command pattern established and working
- ✅ Main dispatch handles parameters correctly
- ✅ Test infrastructure for commands ready
- ✅ Performance validation pattern established

**Files to Modify:**
- `awsprof` - Add `awsprof_cmd_use()` and update main dispatch
- `tests/test_commands.sh` - Add use command tests

**Patterns to Follow:**
- Function naming: `awsprof_cmd_use` (established in Story 1.2)
- Parameter handling: `"$2"` from main dispatch
- Output separation: stdout for eval code, stderr for messages
- Testing: Add to existing test_commands.sh file

### Implementation Sequence

1. **Add command function**
   - Create `awsprof_cmd_use()` in PROFILE COMMANDS section
   - Validate parameter exists
   - Validate profile exists using `awsprof_ini_list_sections()`
   - Output export statement to stdout
   - Output success message to stderr

2. **Add main dispatch entry**
   - Add `use)` case with `"$2"` parameter
   - Update help text to include use command

3. **Write tests**
   - Add to existing `tests/test_commands.sh`
   - Test valid profile switch
   - Test non-existent profile error
   - Test missing parameter error
   - Test eval integration
   - Test exit codes

4. **Run tests and verify**
   - All existing tests still pass (no regressions)
   - New use command tests pass
   - Performance verified (<100ms)
   - Eval pattern actually works in shell

### Project Context Notes

**Project Status:** Building on Stories 1.1 and 1.2
- Story 1.1 complete and in review (INI parsing foundation)
- Story 1.2 complete and in review (list command)
- Adding core switching functionality

**Dependencies:**
- **Depends on:** Story 1.1 (INI parsing) - COMPLETE
- **Depends on:** Story 1.2 (command pattern) - COMPLETE
- **Blocks:** Story 1.4 (Show Current Profile) - needs switching to test

**Blockers:** None

**Critical Success Factor:**
The eval pattern MUST work correctly - this is the core functionality that enables setting environment variables in the parent shell.

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Eval Output Pattern]
- [Source: _bmad-output/planning-artifacts/architecture.md#Command Boundary]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.3: Switch to Profile]
- [Source: _bmad-output/implementation-artifacts/1-1-script-foundation-ini-reading.md#INI Parsing]
- [Source: _bmad-output/implementation-artifacts/1-2-list-available-profiles.md#Command Pattern]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

- Initial test failure: `$2` unbound variable error when calling `awsprof use` without parameter
- Fix: Changed `"$2"` to `"${2:-}"` in main dispatch to handle missing parameter gracefully
- Tests: All 17 tests passing (7 INI + 10 command tests)

### Completion Notes List

✅ Implemented `awsprof_cmd_use()` command function with eval pattern
✅ Added profile name validation (parameter required)
✅ Added profile existence validation using `awsprof_ini_list_sections()`
✅ Implemented critical stdout/stderr separation:
   - stdout: `export AWS_PROFILE=<name>` (for eval)
   - stderr: User feedback messages
✅ Added `use` case to main dispatch with `"${2:-}"` parameter handling
✅ Updated help text to include `use` command with eval hint
✅ Added 5 comprehensive tests to `tests/test_commands.sh`:
   - Valid profile switch with output verification
   - Non-existent profile rejection
   - Missing parameter handling
   - Eval integration (verifies AWS_PROFILE actually gets set)
   - Performance validation (<100ms)
✅ Fixed unbound variable issue in main dispatch
✅ All tests pass (17/17)
✅ Verified eval pattern works: `eval "$(awsprof use staging)"` correctly sets AWS_PROFILE

**Technical Decisions:**
- Used `grep -qx` for exact profile name matching (prevents partial matches)
- Used `"${2:-}"` instead of `"$2"` to handle missing parameters with strict mode
- Followed established pattern from Story 1.2 for command structure
- Maintained performance requirement (<100ms verified in tests)

### File List

- awsprof (modified) - Added `awsprof_cmd_use()` function and `use` case to main dispatch
- tests/test_commands.sh (modified) - Added 5 new tests for use command (tests 6-10)
- _bmad-output/implementation-artifacts/1-3-switch-to-profile.md (modified) - Updated status and completion notes
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified) - Updated story status to review
