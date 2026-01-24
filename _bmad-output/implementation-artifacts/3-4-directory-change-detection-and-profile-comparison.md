# Story 3.4: Directory Change Detection and Profile Comparison

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want automatic detection when I enter a directory with a profile mismatch,
So that I'm immediately warned before running commands in the wrong account.

## Acceptance Criteria

### AC1: Directory Change Detection via PROMPT_COMMAND Hook

**Given** bash shell integration is loaded via PROMPT_COMMAND
**When** the user changes to any directory
**Then** the hook checks for a `.awsprofile` file (FR17)
**And** the check adds no perceptible delay to the prompt (NFR3)
**And** the check completes in under 10ms

### AC2: Profile Name Comparison Against Current AWS_PROFILE

**Given** a `.awsprofile` file exists in the directory
**When** the hook detects it
**Then** the expected profile name is read from the file
**And** it is compared against the current `AWS_PROFILE` environment variable (FR18)

### AC3: Silent on Profile Match

**Given** the current profile matches the project's expected profile
**When** the comparison is performed
**Then** no output is displayed (FR22)
**And** the prompt appears normally (silent success)

### AC4: Warning on Profile Mismatch

**Given** the current profile differs from the expected profile
**When** the comparison detects a mismatch
**Then** a warning is displayed to the user (FR19)
**And** the warning format is: `⚠️  Profile mismatch: current 'personal', project expects 'client-acme'`

### AC5: Handle Unset AWS_PROFILE

**Given** no AWS_PROFILE is set (using default)
**When** a project expects a specific profile
**Then** a mismatch is detected and reported
**And** the current profile is shown as 'default' or '(none)'

## Tasks / Subtasks

- [ ] Implement directory change detection hook (AC: 1, 2, 3, 4, 5)
  - [ ] Create `awsprof_hook_detect_profile()` function to run on each directory change
  - [ ] Call `awsprof_util_read_awsprofile()` helper from Story 3.3
  - [ ] Compare expected profile against `$AWS_PROFILE` environment variable
  - [ ] Display silent success when profiles match (no output)
  - [ ] Display warning message when profiles mismatch
  - [ ] Handle unset `AWS_PROFILE` (show as 'default' or '(none)')
  - [ ] Ensure hook completes in under 10ms (performance requirement)
  - [ ] Add error suppression so hook failures don't break shell

- [ ] Update PROMPT_COMMAND initialization code (AC: 1)
  - [ ] Ensure `awsprof_hook_detect_profile` is called on every prompt
  - [ ] Add hook to bash init code (update `awsprof_cmd_init()`)
  - [ ] Verify hook is registered in PROMPT_COMMAND
  - [ ] Test hook is called after every directory change

- [ ] Add tests for directory change detection (AC: 1, 2, 3, 4, 5)
  - [ ] Test: Hook runs on directory change and checks `.awsprofile`
  - [ ] Test: Silent when profile matches
  - [ ] Test: Warning displayed when profile mismatches
  - [ ] Test: Unset AWS_PROFILE shown as 'default' or '(none)'
  - [ ] Test: Hook handles missing `.awsprofile` gracefully
  - [ ] Test: Hook performance (completes under 10ms)
  - [ ] Test: Hook doesn't break shell on error

## Dev Notes

### Critical Context from Story 3.3 (Just Completed)

**What Story 3.3 Implemented:**
- ✅ `awsprof_util_read_awsprofile()` helper function
- ✅ Reads `.awsprofile` file from current directory
- ✅ Trims whitespace automatically
- ✅ Silent handling of missing/empty files (returns empty string)
- ✅ Added `awsprof check` command for manual verification
- ✅ All 101 tests passing

**Key Pattern from Stories 3.1-3.3 to Reuse:**
- Function naming: `awsprof_hook_*` for PROMPT_COMMAND hooks
- Silent error handling (no error messages on missing files)
- All messages to stderr, function output follows patterns
- Performance-critical code needs fast execution
- PROMPT_COMMAND must be non-blocking and fast

**Git Commits Reference:**
- `3123499` - Story 3.3 implementation (`.awsprofile` reader)
- `0cb01c8` - Story 3.3 creation
- `3db9850` - Story 3.1 wrapper bug fix (critical fix for eval pattern)

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Directory Change Detection Pattern:**
- PROMPT_COMMAND hook runs after every prompt
- Hook function: `awsprof_hook_detect_profile()`
- Called automatically by bash shell
- Must be non-blocking and fast (under 10ms)
- Silent on success, warning on mismatch

**Project-Profile Linking Workflow:**
1. Story 3.3: User creates `.awsprofile` file with profile name (DONE ✓)
2. Story 3.4: Hook detects mismatch on directory change (THIS STORY)
3. Story 3.5: Interactive prompt for automatic profile switch
4. Story 3.6: Error handling and robustness

**Performance Requirements (Critical):**
- Hook must complete in under 10ms (NFR3)
- No perceptible delay to prompt
- Non-blocking execution
- Suppress all errors to prevent shell slowdown

**Error Handling Standards:**
- Suppress all errors in hook (no stderr output from hook)
- Silent failure for missing `.awsprofile`
- Graceful handling of unset `AWS_PROFILE`
- Hook failures must not affect shell operation (NFR13)

**Exit Code Semantics:**
- Hook always exits 0 (informational, non-blocking)
- All output via messages to stderr (not exit codes)

### Implementation Strategy

**Core Logic Flow:**
1. `awsprof_hook_detect_profile()` runs on every PROMPT_COMMAND
2. Call `awsprof_util_read_awsprofile()` to get expected profile from `.awsprofile` file
3. If no `.awsprofile`, do nothing (silent success)
4. If `.awsprofile` exists:
   - Get expected profile name
   - Get current `$AWS_PROFILE` (default to "(none)" if unset)
   - Compare expected vs current
   - If match: silent success (no output)
   - If mismatch: display warning message
5. Always return 0 (hook must not affect shell)

**Key Design Decisions:**
- Hook is called automatically by PROMPT_COMMAND (no manual invocation)
- Hook must be fast - no heavy operations
- Silent on success (no message when profiles match)
- Warning on mismatch (informational, not error)
- Unset AWS_PROFILE shows as "(none)" or "default"
- All errors suppressed (redirected to /dev/null)

**Integration with Story 3.3:**
- Call `awsprof_util_read_awsprofile()` to get expected profile
- Function returns empty string if `.awsprofile` missing
- Empty string = no project profile expectation = silent

**Performance Optimization:**
- Minimize system calls (use shell builtins)
- Avoid spawning subshells if possible
- Use `[ -f ]` for file existence check
- Use string comparison (not external commands)

**Message Format:**
- Warning: `⚠️  Profile mismatch: current 'personal', project expects 'client-acme'`
- Include both current and expected profile names
- Use emoji for visibility (⚠️)
- Output to stderr (user messages)

### Testing Strategy & Coverage

**Based on Stories 3.1-3.3 pattern (bash unit tests in tests/test_commands.sh):**

**Test Scenarios:**
1. **Happy path** - Hook runs on directory change, no mismatch
2. **Profile match** - Current profile matches `.awsprofile`, silent
3. **Profile mismatch** - Different profiles, warning displayed
4. **Unset AWS_PROFILE** - Environment variable not set, shown as "(none)"
5. **No `.awsprofile`** - Hook handles gracefully
6. **Performance** - Hook completes under 10ms

**Test Patterns from Story 3.1-3.3:**
- Create temporary directories with/without `.awsprofile` files
- Set AWS_PROFILE environment variable in test
- Call hook function and verify output
- Measure execution time
- Clean up test files

**Edge Cases for Directory Change Detection:**
- Test with AWS_PROFILE unset vs set
- Test with special characters in profile name
- Test with empty `.awsprofile` file
- Test with very long profile names
- Test rapid directory changes (stress test)
- Test in nested directories

### Project Structure & Code Navigation

**Files to Create/Modify:**
- `/awsprof` - Main script
  - Function: `awsprof_hook_detect_profile()` - Already exists as stub (Story 3.1)
  - Update stub to implement actual detection logic
  - Update `awsprof_cmd_init()` to ensure hook is in PROMPT_COMMAND
  - Update help text if needed

- `/tests/test_commands.sh` - Test suite
  - Add 6-7 new tests for directory change detection

**Existing Dependencies (From Stories 3.1-3.3):**
- `awsprof_util_read_awsprofile()` - From Story 3.3
- `awsprof_hook_detect_profile()` - Stub from Story 3.1 (update implementation)
- PROMPT_COMMAND integration - From Story 3.1
- Function naming: `awsprof_hook_<action>()` for hooks
- Error suppression pattern: redirect to /dev/null

**Script Organization:**
```
Current sections:
  #=== SHELL INTEGRATION ===
    - awsprof_hook_detect_profile()   [Story 3.1 - stub, update for Story 3.4]
    - awsprof_cmd_init()              [Story 3.1 - updated for Story 3.2]

Update:
  - Replace stub implementation with real detection logic
  - Call awsprof_util_read_awsprofile() from Story 3.3
  - Add profile comparison logic
  - Add warning message display
```

### Learnings & Patterns from Stories 2.1-3.3

**Established Patterns to Reuse:**
- Hook functions named `awsprof_hook_*()` for PROMPT_COMMAND
- Error suppression: redirect output to /dev/null
- File reading via helper functions
- Silent failure on missing files
- Messages to stderr only
- Performance-critical code optimization

**PROMPT_COMMAND Hook Lessons (from Story 3.1):**
- Hook runs after every command prompt
- Hook must return 0 (always success)
- Hook output to stderr for messages
- Hook called automatically by bash
- Errors in hook can affect prompt display

**Testing Pattern Consistency:**
- Story 3.1: Tested shell integration code
- Story 3.3: Tested helper function behavior
- Story 3.4: Test hook behavior with directory changes
- Same test structure: setup → execute → verify → cleanup

**Performance Patterns:**
- Minimize external command calls
- Use shell builtins where possible
- Avoid spawning subshells
- Fast path for common cases (no mismatch)

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-3.4-Directory-Change-Detection, lines 613-651]
- [Source: _bmad-output/planning-artifacts/architecture.md#PROMPT_COMMAND-Hook, NFR3]
- [Source: _bmad-output/planning-artifacts/prd.md#FR17, FR18, FR19, FR22]
- [Source: _bmad-output/implementation-artifacts/3-3-project-profile-file-creation.md] - Reference for `.awsprofile` reader
- [Source: _bmad-output/implementation-artifacts/3-1-shell-initialization-script-for-bash.md] - Reference for PROMPT_COMMAND pattern

---

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5 (claude-haiku-4-5-20251001)

### Debug Log References

### Completion Notes List

---

## File List

(To be updated after implementation)

## Change Log

(To be updated after implementation)
