# Story 1.2: List Available Profiles

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to see all available AWS profiles in a readable list,
So that I know which profiles are configured and can choose one to use.

## Acceptance Criteria

### AC1: List all profiles from valid credentials file

**Given** the user has multiple profiles in `~/.aws/credentials`
**When** the user runs `awsprof list`
**Then** all profile names are displayed, one per line
**And** the command completes in under 100ms (NFR1)
**And** the output is clean and parseable

### AC2: Handle large number of profiles efficiently

**Given** the credentials file contains 100+ profiles
**When** the user runs `awsprof list`
**Then** all profiles display immediately without noticeable delay (NFR2)

### AC3: Handle missing credentials file

**Given** no credentials file exists
**When** the user runs `awsprof list`
**Then** the command displays a clear error message to stderr (FR29)
**And** exits with status code 1 (FR28)

### AC4: Handle empty credentials file

**Given** the credentials file is empty
**When** the user runs `awsprof list`
**Then** the command displays "No profiles found" or similar message
**And** exits with status code 0 (FR27)

## Tasks / Subtasks

- [x] Implement `awsprof_cmd_list()` command function (AC: #1, #2, #3, #4)
  - [x] Create function following naming convention
  - [x] Call `awsprof_ini_list_sections()` to get profiles
  - [x] Output profile names to stdout (one per line)
  - [x] Handle empty result (no profiles found)
  - [x] Return appropriate exit codes

- [x] Add `list` command to main dispatch (AC: #1)
  - [x] Add case statement entry for `list`
  - [x] Call `awsprof_cmd_list` function
  - [x] Add help text mentioning `list` command

- [x] Write unit tests for list command (AC: #1, #2, #3, #4)
  - [x] Test listing profiles from valid file
  - [x] Test handling of missing credentials file
  - [x] Test handling of empty credentials file
  - [x] Verify exit codes for success and error cases

- [x] Add integration test for end-to-end workflow (AC: #1)
  - [x] Test running `./awsprof list` as executable
  - [x] Verify output format (one profile per line)
  - [x] Verify performance (<100ms)

## Dev Notes

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Critical Implementation Rules:**

1. **Command Structure**
   - Function name: `awsprof_cmd_list()` (follows `awsprof_cmd_<command>` pattern)
   - Location: Add to `#=== PROFILE COMMANDS ===` section
   - Main dispatch: Add `list)` case entry

2. **Output Pattern**
   - Profile names go to **stdout** (clean, parseable)
   - Status/error messages go to **stderr**
   - Example:
     ```
     # stdout:
     default
     staging
     production

     # stderr: (none on success)
     ```

3. **Exit Codes**
   - 0: Profiles found and listed successfully (FR27)
   - 1: Error (missing file, read error) (FR28)
   - 0: Empty file (no profiles) - informational, not an error (FR27)

4. **Performance Requirements**
   - Must complete in <100ms (NFR1)
   - Handle 100+ profiles without delay (NFR2)
   - `awsprof_ini_list_sections()` already optimized (awk-based)

### Technical Requirements

**Dependencies on Story 1.1:**
- ✅ `awsprof_ini_list_sections()` - already implemented
- ✅ `awsprof_error()` - already implemented
- ✅ `awsprof_msg()` - already implemented
- ✅ Main script structure exists
- ✅ Test infrastructure exists

**Implementation Approach:**
Story 1.2 is primarily about adding a command interface to existing functionality. The heavy lifting (INI parsing) is already done.

### Implementation Pattern

**Command Function Template:**
```bash
#=== PROFILE COMMANDS ===
awsprof_cmd_list() {
    # Call existing INI parsing function
    local profiles
    profiles=$(awsprof_ini_list_sections 2>&1) || {
        # Error already printed by awsprof_ini_list_sections
        return 1
    }

    # Check if empty
    if [[ -z "$profiles" ]]; then
        awsprof_msg "No profiles found"
        return 0
    fi

    # Output to stdout (clean, parseable)
    echo "$profiles"
    return 0
}
```

**Main Dispatch Addition:**
```bash
#=== MAIN DISPATCH ===
case "$1" in
    list)
        awsprof_cmd_list
        exit $?
        ;;
    help|--help|-h|"")
        # Help text
        ;;
    *)
        awsprof_error "Unknown command: $1"
        exit 1
        ;;
esac
```

### File Structure (Modifications)

```
labs-aws-profiler/
├── awsprof                     # THIS STORY: Add list command
└── tests/
    ├── test_commands.sh        # THIS STORY: New test file for commands
    ├── test_ini.sh             # From Story 1.1: Existing
    └── fixtures/
        ├── credentials.mock    # From Story 1.1: Reuse
        ├── credentials_malformed.mock  # From Story 1.1: Reuse
        └── credentials_empty.mock      # THIS STORY: Add for AC4
```

### Testing Standards

**Test Pattern (from Story 1.1):**
- Source awsprof script
- Simple bash assertions
- Separate test file per module

**New Test File:** `tests/test_commands.sh`
```bash
#!/usr/bin/env bash
source ./awsprof

# Test awsprof list with valid file
test_list_valid() {
    result=$(./awsprof list 2>&1)
    [[ "$result" == *"default"* ]] || fail
    pass "awsprof list shows profiles"
}
```

### Previous Story Intelligence (Story 1.1)

**Learnings Applied:**
- ✅ Script foundation exists - only need to add command
- ✅ INI parsing works and is tested - reuse `awsprof_ini_list_sections()`
- ✅ Test pattern established - follow same structure
- ✅ Conditional strict mode works - maintain for testability

**Files to Modify:**
- `awsprof` - Add `awsprof_cmd_list()` and main dispatch case

**Files to Create:**
- `tests/test_commands.sh` - Command-level tests
- `tests/fixtures/credentials_empty.mock` - Empty file for AC4

**Patterns to Follow:**
- Function naming: `awsprof_cmd_<command>`
- Output utilities: Use `awsprof_msg()`, `awsprof_error()`
- Exit codes: 0 for success, 1 for errors
- Testing: Simple bash assertions, comprehensive coverage

### Implementation Sequence

1. **Add command function**
   - Create `awsprof_cmd_list()` in PROFILE COMMANDS section
   - Use existing `awsprof_ini_list_sections()`
   - Handle empty results

2. **Add main dispatch entry**
   - Add `list)` case to main dispatch
   - Call command function
   - Exit with function's return code

3. **Create test infrastructure**
   - New `tests/test_commands.sh` file
   - Add `tests/fixtures/credentials_empty.mock`

4. **Write tests**
   - Test valid file listing
   - Test missing file error
   - Test empty file message
   - Test exit codes

5. **Run tests and verify**
   - All existing tests still pass (no regressions)
   - New command tests pass
   - Performance verified (<100ms)

### Project Context Notes

**Project Status:** Building on Story 1.1 foundation
- Story 1.1 complete and in review
- INI parsing infrastructure ready
- Adding first user-facing command

**Dependencies:**
- **Depends on:** Story 1.1 (Script Foundation & INI Reading) - COMPLETE
- **Blocks:** Story 1.3 (Switch to Profile) - needs list validation

**Blockers:** None

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Command Boundary]
- [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.2: List Available Profiles]
- [Source: _bmad-output/implementation-artifacts/1-1-script-foundation-ini-reading.md#Learnings]

## Dev Agent Record

### Agent Model Used

Codex (GPT-5)

### Debug Log References

- Tests: `bash tests/test_ini.sh`
- Tests: `bash tests/test_commands.sh`

### Completion Notes List

- Implemented `awsprof_cmd_list()` and added main dispatch `list` command with help text.
- Added large-profile fixture and assertions for 100+ profiles, plus stderr-clean assertion.
- Hardened awk parsing exit handling under `set -e` to preserve exit-code contract.
- Verified tests: INI parsing and command tests both pass.

### File List

- awsprof
- tests/test_commands.sh
- tests/fixtures/credentials_empty.mock
- tests/fixtures/credentials_many.mock

### Change Log

- Added `list` command implementation and tests for profile listing (2026-01-23)
