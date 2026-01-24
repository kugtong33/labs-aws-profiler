# Story 2.5: Import Existing Profiles

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to import profiles from my existing AWS credentials file,
So that I can verify awsprof recognizes all my configured accounts.

## Acceptance Criteria

**AC1: List all profiles with count**
- Given the user has existing profiles in `~/.aws/credentials`
- When the user runs `awsprof import`
- Then the command reads and lists all profiles found (FR7, FR8)
- And displays a count: "Found X profiles: profile1, profile2, profile3..."
- And confirms "All profiles are accessible to awsprof"

**AC2: Handle complex formatting (read-only)**
- Given the credentials file has complex formatting (comments, blank lines, spacing)
- When import is executed
- Then the original file structure is preserved (FR9)
- And the import is read-only (no modifications made)
- And all valid profile sections are detected (FR8)

**AC3: Handle missing credentials file gracefully**
- Given no credentials file exists
- When the user runs `awsprof import`
- Then a clear message is displayed: "No credentials file found at ~/.aws/credentials"
- And the command exits with status code 0 (informational, not an error)

**AC4: Handle malformed files gracefully**
- Given the credentials file is malformed
- When import is attempted
- Then the command handles errors gracefully (NFR12)
- And reports which profiles were successfully detected vs. errors encountered

## Tasks / Subtasks

- [ ] Implement `awsprof_cmd_import()` function in main script (AC: 1, 2, 3, 4)
  - [ ] Check if credentials file exists
  - [ ] If missing: display informational message, exit 0
  - [ ] If exists: call `awsprof_ini_list_sections()` to get all profiles
  - [ ] Count profiles and format display output
  - [ ] Handle parsing errors gracefully
  - [ ] Return correct exit code (always 0 for informational command)
- [ ] Add `import` case to main dispatch (AC: 1, 2, 3, 4)
  - [ ] Add case statement for "import" command
  - [ ] Call `awsprof_cmd_import()` with no parameters
  - [ ] Ensure exit code propagation
- [ ] Update help text documentation (AC: 1)
  - [ ] Add "import" to help output
- [ ] Create comprehensive test suite (AC: 1, 2, 3, 4)
  - [ ] Test: Import profiles from valid credentials file
  - [ ] Test: Import with empty credentials file
  - [ ] Test: Import with single profile
  - [ ] Test: Import with many profiles (10+, perf test)
  - [ ] Test: Import with comments and blank lines
  - [ ] Test: Import when credentials file missing
  - [ ] Test: Import with malformed INI syntax
  - [ ] Test: Import with special characters in names
  - [ ] Test: Integration - import then list consistency
  - [ ] Test: Exit codes always 0 (informational)

## Dev Notes

### Architecture Requirements & Constraints

**Relevant Architecture Patterns:** [Source: architecture.md#Function-Naming-Convention, #INI-File-Handling, #Output-Patterns]

**Function Naming Convention:**
```bash
Pattern: awsprof_<module>_<action>
Applied: awsprof_cmd_import() [command module, import action]
Locals: Use `local` keyword for all function-local variables
```

**INI File Handling (Story 1.1 Foundation):**
```bash
# Story 2.5 REUSES existing Story 1.1 infrastructure:
# - awsprof_ini_list_sections() - Already handles all profile parsing
# - Already tested with 100+ profiles (NFR2)
# - Already handles malformed files gracefully (NFR12)
# - Already tested comprehensively (17 INI tests, all passing)

# Import operation is READ-ONLY:
#   1. Check if credentials file exists
#   2. Call awsprof_ini_list_sections()
#   3. Process output and count profiles
#   4. Display results to stderr
#   5. Return 0 (always success, informational)
```

**Output Patterns:** [Source: architecture.md#Output-Patterns]
```bash
# User messages to stderr via helper functions:
awsprof_msg "message"       # informational
awsprof_error "message"     # error (sets exit 1)
awsprof_success "message"   # success confirmation

# NOTE: import is informational command
# - Always exit 0 (even if file missing)
# - Never exit 1 (no error conditions)
# - Output format: "Found X profiles: profile1 profile2 profile3..."
# - Confirmation: "All profiles are accessible to awsprof"
```

**File Path Resolution:**
```bash
# From Story 2.1 pattern:
# Uses AWS_SHARED_CREDENTIALS_FILE if set, otherwise default to ~/.aws/credentials
# Configuration already in place:
_awsprof_credentials="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
```

### Implementation Sequence & Key Decisions

**Core Logic Flow:**
1. **Resolve credentials file path** - Use `AWS_SHARED_CREDENTIALS_FILE` env var if set, else `~/.aws/credentials`
2. **Check if file exists** - If not, display informational message and return 0
3. **List profiles** - Call `awsprof_ini_list_sections()` which handles parsing and errors
4. **Count and format** - Process profile list into count and space-separated display
5. **Display results** - Show count and confirmation message
6. **Return 0** - Always exit 0 (informational command, never fails)

**Key Design Notes:**
- Story 2.5 is READ-ONLY - No credential input, no file modifications
- Simplest story of Epic 2 - Reuses 95%+ of existing functionality
- Exit code is always 0 (differs from add/edit/remove which exit 1 on errors)
- Missing credentials file is informational, not an error
- Leverages proven `awsprof_ini_list_sections()` from Story 1.1

### Testing Strategy & Coverage

**Test Framework:** Following Stories 2.1-2.4 pattern (bash unit tests in tests/test_commands.sh)

**Critical Test Scenarios:**
1. **Happy path** - List all profiles with count and confirmation
2. **Edge cases** - Empty file, single profile, 10+ profiles
3. **Formatting** - Comments, blank lines, special characters
4. **Missing file** - Graceful handling, informational message, exit 0
5. **Malformed data** - Error handling without crashing, report results

**Test Patterns from Story 2.4:**
- Use `setup_test()` and `teardown_test()` for test isolation
- Create mock credentials files with known content
- Verify command output, exit code, and results
- Check message formatting matches specification
- All test functions prefixed with `test_cmd_import_*`

**Acceptance Criteria Coverage:**
- AC1 (list with count, confirmation): Tests 37, 39, 40
- AC2 (preserve format, read-only, detect all): Tests 41, 42, 44
- AC3 (missing file gracefully): Test 43
- AC4 (malformed files): Tests 45, 46

### Project Structure & Code Navigation

**Primary Files to Modify:**
- `/awsprof` - Main script, functions and dispatch
  - Section: `#=== PROFILE COMMANDS ===` - Add `awsprof_cmd_import()` function
  - Section: `#=== MAIN DISPATCH ===` - Add `import` case statement
  - Update help text with import command
- `/tests/test_commands.sh` - Test suite
  - Add 10 test functions following Story 2.4 pattern

**Existing Dependencies (Already Implemented):**
- `awsprof_ini_list_sections()` - Lists all profiles (Story 1.1, proven with 100+ profiles)
- `awsprof_msg()`, `awsprof_error()`, `awsprof_success()` - Output helpers (Story 1.1)
- `_awsprof_credentials` - Credentials file path resolution (Story 1.1)
- Error state management (`set +e`, reach checking) - Story 1.1

**Script Organization:** [Source: architecture.md#Script-Organization]
```
Current sections:
  #=== CONFIGURATION ===         (paths, constants)
  #=== INI HANDLING ===          (parsing, reading, writing - Stories 1.1, 2.1)
  #=== PROFILE COMMANDS ===      (list, use, whoami, add, edit, remove - ADD import HERE)
  #=== SHELL INTEGRATION ===     (init, eval wrapper - Stories 3.1-3.6)
  #=== MAIN DISPATCH ===         (command routing - ADD import case HERE)
```

### Learnings & Patterns from Stories 2.1-2.4

**Code Reuse Strategy:**
- Story 2.4 pattern for profile existence check (reusable)
- Story 2.3 pattern for function structure (proven efficient)
- Story 2.2 pattern for output helpers (standard across all commands)
- Story 2.1 pattern for file path resolution (already implemented)

**Key Difference from Previous Stories:**
- Previous stories (add/edit/remove): Modify files, require validation, exit 1 on error
- Story 2.5 (import): Read-only, informational, ALWAYS exit 0

**Exit Code Philosophy:**
- add/edit/remove: `exit 0` on success, `exit 1` on error
- import: `exit 0` always (informational command, never fails)

**Test Success Pattern from Stories 2.1-2.4:**
- All tests passed on first run (Story 2.3: 10 tests, Story 2.4: 10 tests)
- Pattern: Simple setup → execute → assert → cleanup
- No regressions in existing tests

**Estimated Implementation Time:**
- ~30 minutes total
- Function implementation: ~15 minutes (very simple, read-only)
- Testing: ~15 minutes (10 tests with various scenarios)
- Commits: ~5 minutes

### References

- Story Requirements: [Source: epics.md#Story-2.5-Import-Existing-Profiles, lines 470-505]
- INI Operations: [Source: architecture.md#INI-File-Handling, lines 334-359]
- Function Naming: [Source: architecture.md#Function-Naming-Convention, lines 265-275]
- Output Patterns: [Source: architecture.md#Output-Patterns, lines 287-331]
- Story 2.4 Patterns: [Source: 2-4-remove-profile.md#Dev-Notes, lines 119-200]
- Story 2.3 Patterns: [Source: 2-3-edit-existing-profile.md#Dev-Agent-Record, lines 437-441]
- Story 2.2 Security: [Source: 2-2-add-new-profile.md#Security-Checklist, lines 341-351]

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5

### Debug Log References

- Analysis ID: a106e83 (comprehensive artifact analysis for story context)

### Completion Notes List

- Story created: 2026-01-24
- Status: ready-for-dev
- Ultimate context engine analysis completed - comprehensive developer guide created
- All acceptance criteria documented with explicit test mapping
- Architecture constraints and patterns integrated throughout
- Code reuse opportunities identified from Stories 2.1-2.4
- Test strategy aligned with established patterns from Story 2.4
- Key insight: Read-only informational command, always exits 0

### File List

**Files to be created/modified during implementation:**
- `awsprof` - Main script (modify existing)
- `tests/test_commands.sh` - Test suite (modify existing)

**Files to be created during commits:**
- Implementation commit: update to awsprof and tests
- Documentation commit: completion notes added to this story file
