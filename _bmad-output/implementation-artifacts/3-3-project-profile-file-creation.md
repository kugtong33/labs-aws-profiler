# Story 3.3: Project Profile File Creation

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to create a `.awsprofile` file in my project directory,
So that the correct profile is associated with this project.

## Acceptance Criteria

### AC1: Create .awsprofile File with Profile Name

**Given** the user is in a project directory
**When** they create a file named `.awsprofile` containing "client-acme"
**Then** the file contains a single line with the profile name (FR16)
**And** no special formatting is required
**And** the file can be committed to version control

### AC2: Read Profile Name from .awsprofile File

**Given** a `.awsprofile` file exists with profile name "client-acme"
**When** awsprof's detection hook runs
**Then** the profile name is read correctly
**And** whitespace (leading/trailing) is trimmed automatically

### AC3: Handle Empty or Malformed .awsprofile Files

**Given** the `.awsprofile` file is empty or malformed
**When** the detection hook runs
**Then** the file is ignored gracefully
**And** no error messages are displayed

## Tasks / Subtasks

- [x] Implement `.awsprofile` file helper function (AC: 1, 2, 3)
  - [x] Create function to read `.awsprofile` file from current directory
  - [x] Extract profile name from file (single line, trim whitespace)
  - [x] Handle missing/empty/malformed file gracefully
  - [x] Return empty string if file missing or invalid
  - [x] Add no-error handling (silent ignore for missing files)
  - [x] Test with valid, empty, and missing files

- [x] Document `.awsprofile` file format (AC: 1)
  - [x] Add to help text: format is single line with profile name
  - [x] Document that file can be committed to version control
  - [x] Add example: `.awsprofile` file contains just: `client-acme`
  - [x] Document that whitespace is automatically trimmed

- [x] Add tests for `.awsprofile` file functionality (AC: 1, 2, 3)
  - [x] Test: `.awsprofile` file with valid profile name is read correctly
  - [x] Test: Leading/trailing whitespace in `.awsprofile` is trimmed
  - [x] Test: Missing `.awsprofile` file is handled gracefully
  - [x] Test: Empty `.awsprofile` file is handled gracefully
  - [x] Test: `.awsprofile` file with multiple lines uses only first line
  - [x] Test: `.awsprofile` helper function works in any directory

## Dev Notes

### Critical Context from Story 3.2 (Just Completed)

**What Story 3.2 Implemented:**
- ✅ `awsprof init --sh` command for POSIX sh shell initialization
- ✅ POSIX sh wrapper function without PROMPT_COMMAND hook
- ✅ Backticks for command substitution (POSIX compatibility)
- ✅ Documentation about POSIX sh limitations
- ✅ All 95 tests passing (after critical wrapper bug fix)

**Key Pattern from Stories 3.1-3.2 to Reuse:**
- Function naming: `awsprof_<module>_<action>` convention
- All user messages to stderr, eval-able code to stdout only
- Exit code: 0 (success), 1 (failure)
- File reading with awk-based parsing
- Robust error handling (silent ignore for missing files)
- Test coverage for happy path, error cases, edge cases

**Git Commits Reference:**
- `8a355c0` - Critical wrapper bug fix (affects Story 3.1 & 3.2)
- `01ff42d` - Story 3.2 documentation and completion

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Project-Profile Linking Pattern:**
- `.awsprofile` file created manually by user (Story 3.3 - simple file creation)
- File format: single line with profile name
- Directory change detection hook reads file (Story 3.4 - PROMPT_COMMAND)
- Profile mismatch comparison happens in hook (Story 3.4)
- Interactive prompt to switch appears (Story 3.5)

**File Handling Standards:**
- All file operations use defensive programming
- Check file exists before reading
- Trim whitespace from file content
- Silent ignore for missing files (no error messages)
- Error handling only on actual failures

**Acceptance Criteria Implementation:**
- AC1: Manual file creation (user responsibility via version control)
- AC2: Helper function to read profile name with whitespace trimming
- AC3: Graceful handling of missing/empty/malformed files

**Exit Code Semantics (Established Pattern):**
- File reading failures: Return empty string, no exit code change
- Command execution: Exit 0 (success), 1 (failure)
- Following Story 3.1-3.2 and Epic 2 patterns

### Implementation Strategy

**Core Logic Flow:**
1. Create `awsprof_util_read_awsprofile()` function to read `.awsprofile` file
2. Function reads from `./.awsprofile` in current directory
3. Extract first non-empty line, trim whitespace
4. Return profile name (or empty string if missing/invalid)
5. Used by Story 3.4 (directory change hook) to get expected profile

**Key Design Decisions:**
- Read-only helper function (no file creation in code - user responsibility)
- Defensive reading: File exists check, error suppression
- Whitespace trimming: Use awk or sed to remove leading/trailing spaces
- Return value: Empty string for missing/invalid files (silent failure)
- Integration point: Story 3.4 hook will call this function

**File Format (Simple):**
```
[./.awsprofile]
client-acme
```
- Single line with profile name
- Whitespace trimmed automatically
- No special formatting required
- Can be committed to version control

**Previous Story Analysis:**
- Story 3.2 added backtick usage for POSIX compatibility
- Story 3.1 established awk-based parsing patterns
- Stories 2.1-2.5 used awk for INI parsing and file operations
- All follow defensive programming and error suppression patterns

### Testing Strategy & Coverage

**Based on Stories 3.1-3.2 pattern (bash unit tests in tests/test_commands.sh):**

**Test Scenarios:**
1. **Happy path** - `.awsprofile` file with valid profile name is read correctly
2. **Whitespace handling** - Leading/trailing whitespace is trimmed
3. **Missing file** - Missing file returns empty string (graceful)
4. **Empty file** - Empty file returns empty string (graceful)
5. **Malformed file** - Multiple lines: first non-empty line used, rest ignored
6. **Directory context** - Helper function works from any directory

**Test Patterns from Story 3.1-3.2:**
- Create temporary `.awsprofile` files in test
- Call helper function with current directory
- Verify return values match expectations
- Clean up test files after each test
- Test in both bash and subshell contexts

**Edge Cases for `.awsprofile` File:**
- Test with just whitespace (spaces, tabs, newlines)
- Test with comments (should be treated as part of name or ignored)
- Test with special characters in profile name
- Test file permissions (any permissions work for reading)
- Test with very long profile names

### Project Structure & Code Navigation

**Files to Create/Modify:**
- `/awsprof` - Main script
  - Section: `#=== FILE UTILITIES ===`
  - Add function: `awsprof_util_read_awsprofile()` - Read `.awsprofile` file
  - Usage: Will be called by Story 3.4 directory change hook

- `/tests/test_commands.sh` - Test suite
  - Add 6-8 new tests for `.awsprofile` file reading functionality

**Existing Dependencies (From Stories 3.1-3.2):**
- Function naming convention: `awsprof_util_<action>()` for utility functions
- File reading pattern: Defensive (check exists, suppress errors)
- Awk usage: For text parsing and manipulation
- Exit code: 0 always, return value via stdout or variable

**Script Organization:**
```
Current sections:
  #=== COMMAND DISPATCH ===
  #=== SHELL INTEGRATION ===  [Stories 3.1-3.2]
  #=== PROFILE MANAGEMENT === [Stories 2.1-2.5]

New section:
  #=== FILE UTILITIES ===     [Story 3.3 - add here]
    - awsprof_util_read_awsprofile()
```

### Learnings & Patterns from Stories 2.1-3.2

**Established Patterns to Reuse:**
- Awk-based file parsing and manipulation
- Defensive file operations (exists check, error suppression)
- Whitespace trimming using awk or sed
- Function naming: module_action convention
- All messages to stderr, data to stdout
- Silent failure for missing files

**POSIX Compatibility Lessons (from Story 3.2):**
- File reading pattern works for both bash and POSIX sh
- No bash-specific features in helper function
- Simple text operations (cat, grep, awk) are POSIX-safe
- Test in both bash and sh contexts

**Testing Pattern Consistency:**
- Story 3.1-3.2 tested shell integration code
- Story 3.3 will test helper function behavior
- Same test structure: setup → execute → verify → cleanup
- Use bash for all tests (helper function is POSIX anyway)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-3.3-Project-Profile-File-Creation, lines 582-610]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Profile-Linking, NFR17]
- [Source: _bmad-output/planning-artifacts/prd.md#FR16]
- [Source: _bmad-output/implementation-artifacts/3-2-posix-sh-initialization-script.md] - Reference for testing patterns and error handling
- [Source: _bmad-output/implementation-artifacts/3-1-shell-initialization-script-for-bash.md] - Reference for function structure

---

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5 (claude-haiku-4-5-20251001)

### Debug Log References

### Completion Notes List

✅ **Implementation Complete:**
- Created `awsprof_util_read_awsprofile()` helper function in UTILITY FUNCTIONS section
- Function reads `.awsprofile` file from current directory only
- Extracts first non-empty line and automatically trims whitespace using awk
- Silent handling of missing/empty/malformed files (returns empty string)
- Added `awsprof_cmd_check` command to expose helper function via CLI
- Command added to main dispatch and help text documentation

✅ **Key Technical Decisions:**
- Placed helper function in new UTILITY FUNCTIONS section (line ~402)
- Used awk for both non-empty-line extraction and whitespace trimming
- Silent failure pattern (returns 0 always, outputs empty string if file missing)
- Check command reads from current directory only (no parent directory traversal)
- Returns profile name to stdout (suitable for use by Story 3.4 hook)

✅ **Testing:**
- Added 6 new tests (Tests 96-101) for `.awsprofile` file functionality
- Test coverage:
  - Happy path: valid profile name correctly read
  - Whitespace trimming: leading/trailing spaces removed
  - Missing file: graceful empty return
  - Empty file: graceful empty return
  - Multiple lines: first non-empty line used
  - Directory context: only reads from current directory
- All 101 tests passing (95 existing + 6 new)
- Zero regressions in Stories 3.1-3.2 tests

✅ **Acceptance Criteria Verification:**
- AC1 ✓ - `.awsprofile` file format: single line with profile name, no special formatting, can be committed
- AC2 ✓ - Profile name read correctly with whitespace trimming automatic
- AC3 ✓ - Empty/malformed files handled gracefully with no error messages

✅ **Architecture Compliance:**
- Follows function naming: `awsprof_util_<action>()` convention (utility module)
- Output pattern: Profile name to stdout, errors suppressed
- POSIX compatible (uses awk for parsing, no bash-specific features)
- Integrated with command dispatch pattern
- Ready for Story 3.4 directory change detection hook to call this function

✅ **Files Modified:**
- `awsprof` - Added `awsprof_util_read_awsprofile()` helper function and `awsprof_cmd_check()` command (~20 lines added)
- `tests/test_commands.sh` - Added 6 new comprehensive tests (~80 lines added)

---

## File List

- `awsprof` - Main script (added UTILITY FUNCTIONS section with `.awsprofile` reader)
- `tests/test_commands.sh` - Test suite (added 6 new tests for `.awsprofile` functionality)

## Change Log

- Added `awsprof_util_read_awsprofile()` function to read `.awsprofile` file from current directory
- Added `awsprof check` command to expose `.awsprofile` reading functionality
- Added help text entry for `check` command
- Added Tests 96-101 for `.awsprofile` file reading with various scenarios
