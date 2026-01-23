# Story 1.4: Show Current Profile

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to see which AWS profile is currently active,
So that I always know which account my commands will affect.

## Acceptance Criteria

### AC1: Display active profile when AWS_PROFILE is set

**Given** the `AWS_PROFILE` environment variable is set to "client-acme"
**When** the user runs `awsprof whoami`
**Then** the command displays "client-acme" (FR15)
**And** exits with status code 0 (FR27)

### AC2: Display message when AWS_PROFILE is not set

**Given** the `AWS_PROFILE` environment variable is not set
**When** the user runs `awsprof whoami`
**Then** the command displays "No profile set (using default)" or similar (FR15)
**And** exits with status code 0 (FR27)

### AC3: Performance requirement

**Given** any state of the AWS_PROFILE variable
**When** the user queries the current profile
**Then** the operation completes in under 100ms (NFR1)

## Tasks / Subtasks

- [x] Implement `awsprof_cmd_whoami()` command function (AC: #1, #2, #3)
  - [x] Create function following naming convention
  - [x] Check `AWS_PROFILE` environment variable
  - [x] Output current profile name if set
  - [x] Output "No profile set (using default)" if not set
  - [x] Return appropriate exit codes

- [x] Add `whoami` command to main dispatch (AC: #1)
  - [x] Add case statement entry for `whoami`
  - [x] Call `awsprof_cmd_whoami` function
  - [x] Update help text to include `whoami` command

- [x] Write unit tests for whoami command (AC: #1, #2, #3)
  - [x] Test with AWS_PROFILE set
  - [x] Test with AWS_PROFILE not set
  - [x] Test with AWS_PROFILE set to empty string
  - [x] Verify exit codes
  - [x] Verify performance (<100ms)

- [x] Add integration test for end-to-end workflow (AC: #1, #2)
  - [x] Test running `./awsprof whoami` after setting profile
  - [x] Test running `./awsprof whoami` in clean environment
  - [x] Verify output format

## Dev Notes

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Critical Implementation Rules:**

1. **Command Structure**
   - Function name: `awsprof_cmd_whoami()` (follows `awsprof_cmd_<command>` pattern)
   - Location: Add to `#=== PROFILE COMMANDS ===` section
   - Main dispatch: Add `whoami)` case entry

2. **Output Pattern**
   - Profile name/message goes to **stdout** (clean, parseable)
   - Status/error messages go to **stderr** (if needed)
   - Example:
     ```
     # stdout (with AWS_PROFILE=staging):
     staging

     # stdout (without AWS_PROFILE):
     No profile set (using default)

     # stderr: (none on success)
     ```

3. **Exit Codes**
   - 0: Always success - even when no profile is set (FR27)
   - This is informational only, not an error condition

4. **Performance Requirements**
   - Must complete in <100ms (NFR1)
   - Simple environment variable check - no file I/O needed
   - Should be near-instant execution

### Technical Requirements

**Dependencies on Previous Stories:**
- ✅ Story 1.1: Output utilities (`awsprof_msg()`) - for informational messages
- ✅ Story 1.2: Command pattern established
- ✅ Story 1.2: Main dispatch structure exists
- ✅ Story 1.2: Test infrastructure (`tests/test_commands.sh`)
- ✅ Story 1.3: Profile switching functionality to test against

**Implementation Approach:**
Story 1.4 is the simplest command - just read an environment variable. This provides visibility into the current state set by Story 1.3's `use` command.

### Implementation Pattern

**Command Function Template:**
```bash
#=== PROFILE COMMANDS ===
awsprof_cmd_whoami() {
    # Check if AWS_PROFILE is set and non-empty
    if [[ -n "${AWS_PROFILE:-}" ]]; then
        # Output current profile to stdout
        echo "$AWS_PROFILE"
    else
        # Output default message to stdout
        echo "No profile set (using default)"
    fi

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
        awsprof_cmd_use "${2:-}"
        exit $?
        ;;
    whoami)
        awsprof_cmd_whoami
        exit $?
        ;;
    help|--help|-h|"")
        # Update help text to include 'whoami'
        ;;
esac
```

### File Structure (Modifications)

```
labs-aws-profiler/
├── awsprof                     # THIS STORY: Add whoami command
└── tests/
    ├── test_commands.sh        # THIS STORY: Add whoami command tests
    ├── test_ini.sh             # From Story 1.1: Existing
    └── fixtures/
        ├── credentials.mock    # From Story 1.1: Reuse
        └── credentials_empty.mock  # From Story 1.2: Reuse
```

### Testing Standards

**Test Pattern (from Stories 1.1, 1.2, 1.3):**
- Add tests to existing `tests/test_commands.sh`
- Simple bash assertions
- Test both success cases (profile set and not set)

**New Tests to Add:**
```bash
# Test 11: whoami with AWS_PROFILE set
test_whoami_with_profile() {
    result=$(AWS_PROFILE="staging" "${ROOT_DIR}/awsprof" whoami 2>&1)
    exit_code=$?
    [[ $exit_code -eq 0 ]] || fail
    [[ "$result" == "staging" ]] || fail
    pass "awsprof whoami displays current profile"
}

# Test 12: whoami without AWS_PROFILE set
test_whoami_without_profile() {
    result=$(unset AWS_PROFILE; "${ROOT_DIR}/awsprof" whoami 2>&1)
    exit_code=$?
    [[ $exit_code -eq 0 ]] || fail
    [[ "$result" == *"No profile set"* ]] || fail
    pass "awsprof whoami displays default message when no profile set"
}

# Test 13: whoami with empty AWS_PROFILE
test_whoami_empty_profile() {
    result=$(AWS_PROFILE="" "${ROOT_DIR}/awsprof" whoami 2>&1)
    exit_code=$?
    [[ $exit_code -eq 0 ]] || fail
    [[ "$result" == *"No profile set"* ]] || fail
    pass "awsprof whoami handles empty AWS_PROFILE"
}

# Test 14: whoami performance (<100ms)
test_whoami_performance() {
    start_ns=$(date +%s%N)
    AWS_PROFILE="test" "${ROOT_DIR}/awsprof" whoami >/dev/null 2>&1
    exit_code=$?
    end_ns=$(date +%s%N)
    elapsed_ns=$((end_ns - start_ns))
    [[ $exit_code -eq 0 ]] || fail
    [[ $elapsed_ns -lt 100000000 ]] || fail
    pass "awsprof whoami completes within 100ms"
}

# Test 15: integration - whoami after use
test_integration_use_then_whoami() {
    (
        export AWS_SHARED_CREDENTIALS_FILE="${SCRIPT_DIR}/fixtures/credentials.mock"
        eval "$("${ROOT_DIR}/awsprof" use default 2>/dev/null)"
        result=$("${ROOT_DIR}/awsprof" whoami)
        [[ "$result" == "default" ]] || exit 1
    )
    [[ $? -eq 0 ]] || fail
    pass "awsprof whoami shows profile after use command"
}
```

### Previous Story Intelligence

**Learnings from Story 1.1:**
- ✅ INI parsing works and is tested
- ✅ Output utilities working properly
- ✅ Conditional strict mode allows script sourcing for tests

**Learnings from Story 1.2:**
- ✅ Command pattern established: `awsprof_cmd_<command>`
- ✅ Main dispatch handles commands correctly
- ✅ Test infrastructure for commands ready
- ✅ Performance validation pattern established

**Learnings from Story 1.3:**
- ✅ Eval pattern working correctly with stdout/stderr separation
- ✅ Environment variable export successful via eval wrapper
- ✅ Parameter handling with `"${2:-}"` for optional parameters
- ✅ Test pattern for integration scenarios established

**Files to Modify:**
- `awsprof` - Add `awsprof_cmd_whoami()` and update main dispatch
- `tests/test_commands.sh` - Add whoami command tests

**Patterns to Follow:**
- Function naming: `awsprof_cmd_whoami` (established in Story 1.2)
- No parameters needed from main dispatch
- Output to stdout (profile name or default message)
- Testing: Add to existing test_commands.sh file
- Exit code 0 always (informational, never an error)

### Implementation Sequence

1. **Add command function**
   - Create `awsprof_cmd_whoami()` in PROFILE COMMANDS section
   - Check `AWS_PROFILE` environment variable
   - Output current value or default message to stdout
   - Return 0 (always success)

2. **Add main dispatch entry**
   - Add `whoami)` case to main dispatch
   - Call command function
   - Exit with function's return code
   - Update help text to include whoami command

3. **Write tests**
   - Add to existing `tests/test_commands.sh`
   - Test with profile set
   - Test without profile set
   - Test with empty profile
   - Test exit codes (always 0)
   - Test performance (<100ms)
   - Test integration with use command

4. **Run tests and verify**
   - All existing tests still pass (17 tests from previous stories)
   - New whoami tests pass (5 new tests)
   - Performance verified (<100ms)
   - Integration with use command works

### Project Context Notes

**Project Status:** Building on Stories 1.1, 1.2, and 1.3
- Story 1.1 complete and in review (INI parsing foundation)
- Story 1.2 complete and in review (list command)
- Story 1.3 complete and in review (use command with eval pattern)
- Adding profile status visibility

**Dependencies:**
- **Depends on:** Story 1.1 (Script foundation) - COMPLETE
- **Depends on:** Story 1.2 (Command pattern) - COMPLETE
- **Depends on:** Story 1.3 (Profile switching) - COMPLETE (provides AWS_PROFILE to query)
- **Blocks:** None (completes Epic 1 core functionality)

**Blockers:** None

**Critical Success Factor:**
This is a simple informational command. The key is consistency with established patterns and ensuring it works seamlessly with the `use` command from Story 1.3.

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Command Boundary]
- [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.4: Show Current Profile]
- [Source: _bmad-output/implementation-artifacts/1-1-script-foundation-ini-reading.md#Output Utilities]
- [Source: _bmad-output/implementation-artifacts/1-2-list-available-profiles.md#Command Pattern]
- [Source: _bmad-output/implementation-artifacts/1-3-switch-to-profile.md#Eval Pattern]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

- Tests: `bash tests/test_commands.sh`

### Completion Notes List

✅ Implemented `awsprof_cmd_whoami()` command function
✅ Added environment variable check for `AWS_PROFILE`
✅ Implemented dual output paths:
   - Displays profile name when `AWS_PROFILE` is set
   - Displays "No profile set (using default)" when not set
✅ Added `whoami` case to main dispatch
✅ Updated help text to include `whoami` command
✅ Added 5 comprehensive tests to `tests/test_commands.sh`:
   - Test with AWS_PROFILE set (displays profile name)
   - Test without AWS_PROFILE set (displays default message)
   - Test with empty AWS_PROFILE (handles gracefully)
   - Performance validation (<100ms)
   - Integration test with use command
✅ All 16 command tests passing (see `tests/test_commands.sh`)
✅ Performance requirement met (<100ms - near-instant execution)
✅ Integration verified: whoami correctly shows profile after use command

**Technical Implementation:**
- Function follows established `awsprof_cmd_<command>` pattern
- Uses `${AWS_PROFILE:-}` for safe variable checking with strict mode
- Output goes to stdout for clean, parseable format
- Exit code 0 always (informational command, never an error)
- Simplest command in the suite - just reads environment variable

**Epic 1 Status:**
✅ Story 1.1: Script Foundation & INI Reading (complete)
✅ Story 1.2: List Available Profiles (complete)
✅ Story 1.3: Switch to Profile (complete)
✅ Story 1.4: Show Current Profile (complete)
**Epic 1 core functionality complete!**

### File List

- awsprof (modified) - Added `awsprof_cmd_whoami()` function and `whoami` case to main dispatch
- tests/test_commands.sh (modified) - Added tests for whoami command and stdout/stderr separation
- _bmad-output/implementation-artifacts/1-4-show-current-profile.md (modified) - Updated status and completion notes
- _bmad-output/implementation-artifacts/sprint-status.yaml (modified) - Updated story status to done
