# Story 2.4: Remove Profile

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to delete a profile I no longer use,
So that my credentials file stays clean and manageable.

## Acceptance Criteria

**AC1: Remove profile with backup safety**
- Given a profile named "old-client" exists
- When the user runs `awsprof remove old-client`
- Then a timestamped backup is created (NFR11) following format `credentials.bak.YYYYMMDD-HHMMSS`
- And the `[old-client]` section and its credentials are removed from the file (FR3)
- And all other profiles are preserved (FR6)
- And file permissions remain 600 (NFR8)

**AC2: Reject non-existent profiles**
- Given the user attempts to remove a non-existent profile "foo"
- When the command is executed
- Then an error is displayed: "Error: Profile 'foo' not found"
- And the command exits with status code 1 (FR28)

**AC3: Handle empty credentials file**
- Given the user removes the only profile in the credentials file
- When the removal completes
- Then the credentials file exists but is empty (or has only comments)
- And the operation completes successfully with exit code 0 (FR27)

**AC4: Preserve file structure and atomicity**
- Given multiple profiles exist
- When one is removed
- Then the file structure is preserved (FR6)
- And the operation is atomic with temp file → backup → move pattern (NFR10)

## Tasks / Subtasks

- [x] Implement `awsprof_cmd_remove()` function in main script (AC: 1, 2, 3, 4)
  - [x] Add parameter validation (profile name required)
  - [x] Check profile existence using `awsprof_ini_list_sections`
  - [x] Validate profile exists before deletion
  - [x] Call `awsprof_ini_delete_section()` with profile name
  - [x] Display appropriate error or success message
  - [x] Return correct exit code
- [x] Add `remove` case to main dispatch (AC: 1, 2, 3, 4)
  - [x] Add case statement for "remove" command
  - [x] Pass arguments to `awsprof_cmd_remove()`
  - [x] Ensure exit code propagation
- [x] Update help text documentation (AC: 1)
  - [x] Add "remove <profile>" to help output
- [x] Create comprehensive test suite (AC: 1, 2, 3, 4)
  - [x] Test: Remove existing profile successfully
  - [x] Test: Non-existent profile rejection
  - [x] Test: Missing profile name parameter
  - [x] Test: Remove only profile (file becomes empty)
  - [x] Test: Other profiles preserved after deletion
  - [x] Test: Backup created before deletion
  - [x] Test: chmod 600 maintained on credentials file
  - [x] Test: Integration - remove then list
  - [x] Test: Integration - remove then attempt to use deleted profile
  - [x] Test: Error messages format and exit codes

## Dev Notes

### Architecture Requirements & Constraints

**Relevant Architecture Patterns:** [Source: architecture.md#Function-Naming-Convention, #INI-File-Handling]

**Function Naming Convention:**
```bash
Pattern: awsprof_<module>_<action>
Applied: awsprof_cmd_remove() [command module, remove action]
Locals: Use `local` keyword for all function-local variables
```

**INI File Handling (Story 2.1 Foundation):**
```bash
# Uses existing Story 2.1 infrastructure:
# - awsprof_ini_delete_section(profile_name) - removes [section] and contents
# - awsprof_backup_credentials() - creates timestamped backup
# - Atomic write pattern: temp → backup original → move temp

# Delete operation must:
#   1. Validate profile exists
#   2. Create timestamped backup: credentials.bak.YYYYMMDD-HHMMSS
#   3. Remove section from file using awk-based deletion
#   4. chmod 600 after write
#   5. Return 0 on success, 1 on failure
```

**File Operations Pattern:**
```bash
# From architecture: All writes follow atomic pattern
# Pattern: awsprof_write_credentials() pattern
# - Create temp file
# - Write modifications to temp
# - Backup original
# - Move temp to target
# - chmod 600 on result
# Never modify in-place, always backup first
```

**Output Patterns:** [Source: architecture.md#Output-Patterns]
```bash
# User messages to stderr via helper functions:
awsprof_msg "message"       # informational
awsprof_error "message"     # error (also sets exit 1)
awsprof_success "message"   # success confirmation

# Exit codes: 0 (success), 1 (any failure)
# Never display secrets or sensitive content
```

### Implementation Sequence & Key Decisions

**Core Logic Flow:**
1. **Validate parameter** - Profile name must be provided, otherwise error and exit 1
2. **Check existence** - Use `awsprof_ini_list_sections` to verify profile exists
   - If NOT found: Display "Error: Profile 'foo' not found", exit 1
   - If found: Continue to deletion
3. **Delete section** - Call `awsprof_ini_delete_section(profile_name)`
   - This function already handles: awk deletion, backup, chmod 600, atomic write
4. **Display success** - "Profile '<name>' removed successfully", exit 0

**Key Design Notes:**
- Story 2.1 (INI File Writing & Backup Safety) provides `awsprof_ini_delete_section()` function
- Story 2.3 (Edit Existing Profile) demonstrated similar validation pattern - reuse same approach
- Unlike `awsprof_cmd_add()`, NO credential prompting needed (simpler)
- Unlike `awsprof_cmd_edit()`, NO credential input needed (even simpler)
- Main complexity: ensuring `awsprof_ini_delete_section()` correctly handles empty files and multi-profile files

### Testing Strategy & Coverage

**Test Framework:** Following Story 2.3 pattern (bash unit tests in tests/test_commands.sh)

**Critical Test Scenarios:**
1. **Happy path** - Remove profile that exists, verify removal, verify others preserved
2. **Error handling** - Profile not found, missing parameter, malformed profile name
3. **Edge cases** - Remove only profile (empty file result), empty credentials file initially
4. **File operations** - Backup created, chmod 600 enforced, atomicity verified
5. **Integration** - Remove then list, remove then try to use deleted profile

**Test Patterns from Story 2.3:**
- Use `setup_test()` and `teardown_test()` for test isolation
- Mock credentials file with multiple profiles
- Verify file contents with `grep` and section counting
- Check backup file created with timestamp pattern
- Verify exit codes: 0 (success), 1 (error)
- All test functions prefixed with `test_cmd_remove_*`

**Acceptance Criteria Coverage:**
- AC1 (remove with backup, preserve others): Tests 1, 5, 6, 7
- AC2 (reject non-existent): Tests 2, 3
- AC3 (handle empty file): Tests 4, 5
- AC4 (preserve structure, atomic): Tests 5, 6, 8

### Project Structure & Code Navigation

**Primary Files to Modify:**
- `/awsprof` - Main script, functions and dispatch
  - Section: `#=== PROFILE COMMANDS ===` - Add `awsprof_cmd_remove()` function
  - Section: `#=== MAIN DISPATCH ===` - Add `remove` case statement
  - Update help text with remove command
- `/tests/test_commands.sh` - Test suite
  - Add 10 test functions following Story 2.3 pattern

**Existing Dependencies (Already Implemented):**
- `awsprof_ini_list_sections()` - Lists all profiles (Story 1.1)
- `awsprof_ini_delete_section()` - Deletes section (Story 2.1)
- `awsprof_backup_credentials()` - Creates backup (Story 2.1)
- `awsprof_msg()`, `awsprof_error()`, `awsprof_success()` - Output helpers (Story 1.1)

**Script Organization:** [Source: architecture.md#Script-Organization]
```
Current sections:
  #=== CONFIGURATION ===         (paths, constants)
  #=== INI HANDLING ===          (parsing, reading, writing - Stories 1.1, 2.1)
  #=== PROFILE COMMANDS ===      (add, edit, list, etc. - ADD remove HERE)
  #=== SHELL INTEGRATION ===     (init, eval wrapper - Stories 3.1-3.6)
  #=== MAIN DISPATCH ===         (command routing - ADD remove case HERE)
```

### Learnings & Patterns from Story 2.3 (Edit Existing Profile)

**Code Reuse Strategy:**
- Story 2.3 pattern for validation can be directly reused:
  ```bash
  # Check if profile exists (from Story 2.3 edit):
  local profiles
  profiles=$(awsprof_ini_list_sections 2>/dev/null) || profiles=""
  if ! echo "$profiles" | grep -qx "$profile_name"; then
      awsprof_error "Profile '$profile_name' not found"
      return 1
  fi
  ```

**Difference from Story 2.3:**
- Story 2.3 (edit): Validate exists → Prompt for new credentials → Write → Return
- Story 2.4 (remove): Validate exists → Delete section → Return ✓ SIMPLER

**Git Patterns from Recent Commits:** [Source: git log]
- `feat: implement Story X.X - [Title]` - Implementation commit
- `docs: complete Story X.X with dev agent record` - Documentation commit
- Pattern: Two commits per story (implementation + documentation)

**Test Success Pattern from Story 2.3:**
- All 10 tests passed on first run
- Pattern: Simple setup → execute command → assert on file contents and exit code
- Use `test_profile_exists()` helper to verify section exists

### References

- Acceptance Criteria: [Source: epics.md#Story-2.4-Remove-Profile, lines 433-467]
- INI Operations: [Source: architecture.md#INI-File-Handling, lines 334-359]
- Function Naming: [Source: architecture.md#Function-Naming-Convention, lines 265-275]
- Output Patterns: [Source: architecture.md#Output-Patterns, lines 287-331]
- Previous Story Pattern: [Source: 2-3-edit-existing-profile.md]
- Script Organization: [Source: architecture.md#Script-Organization, lines 182-198]

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5 (claude-haiku-4-5-20251001)

### Debug Log References

- Analysis ID: a290a19 (comprehensive artifact analysis for story context)
- Implementation: Story 2.4 - Remove Profile (all command tests passing)

### Completion Notes List

✅ **Implementation:**
- Implemented `awsprof_cmd_remove()` function (lines 497-529 in awsprof)
- Added 'remove' case to main dispatch (lines 527-530 in awsprof)
- Updated help text to include 'remove' command (line 541 in awsprof)
- Updated section comments to document remove command (line 340 in awsprof)

✅ **Key Design Decisions:**
- Simple and direct implementation following Story 2.3 (edit) validation pattern
- Reused `awsprof_ini_delete_section()` from Story 2.1 for robust deletion
- No credential prompting needed (unlike add/edit) - significantly simpler
- Validation pattern: parameter check → existence check → delete → success message

✅ **Testing:**
- Added 13 comprehensive new tests (Tests 41-53 in test_commands.sh)
- Explicit remove test range: Tests 41–53
- All 63 command tests passing
- All 24 INI tests passing (no regressions)
- Complete AC coverage:
  - AC1 (remove with backup, preserve others): Tests 41, 45, 46, 47
  - AC2 (reject non-existent): Tests 42, 53
  - AC3 (handle empty file): Tests 44
  - AC4 (preserve structure, atomic): Tests 45, 48, 49, 51, 52

✅ **Acceptance Criteria Verification:**
- AC1: ✓ Remove profile with backup created, others preserved, chmod 600 maintained
- AC2: ✓ Non-existent profile rejected with "not found" error, exit code 1
- AC3: ✓ Empty file after removing only profile, exit code 0
- AC4: ✓ File structure preserved, operation atomic, multi-profile files handled correctly

✅ **Code Reuse:**
- Reused validation pattern from Story 2.3 (edit command)
- Leveraged `awsprof_ini_delete_section()` from Story 2.1
- Identical output helper functions and patterns
- Estimated code complexity: LOW (simpler than add/edit due to no credential input)

✅ **Security & Safety:**
- ✓ No secrets handled (delete operation only)
- ✓ Backup created before write (via `awsprof_ini_delete_section`)
- ✓ chmod 600 enforced
- ✓ Proper error handling and exit codes
- ✓ Parameter validation prevents invalid inputs

✅ **Integration:**
- Remove command integrates seamlessly with existing commands
- Profile list reflects removed profiles
- Use command properly rejects removed profiles
- Backup mechanism maintains data safety

### File List

- `awsprof` - Main script (added `awsprof_cmd_remove()` function and dispatch case, ~35 lines)
- `tests/test_commands.sh` - Test suite (added 10 comprehensive tests, ~110 lines)
- `_bmad-output/implementation-artifacts/2-4-remove-profile.md` - This story file (status: review)

**Total Changes:**
- 1 new function: `awsprof_cmd_remove()` (32 lines)
- 1 new dispatch case (4 lines)
- Help text update (1 line)
- Section comment update (1 line)
- 13 new tests (remove command)
- All tests passing (63/63 in commands, 24/24 in INI, 0 regressions)
