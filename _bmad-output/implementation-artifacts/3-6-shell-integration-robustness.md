# Story 3.6: Shell Integration Robustness

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want shell integration to handle errors gracefully,
So that awsprof issues never break my terminal session.

## Acceptance Criteria

### AC1: Missing or Deleted awsprof Executable

**Given** the awsprof executable is deleted or moved
**When** the PROMPT_COMMAND hook runs
**Then** no error messages spam the terminal (NFR13)
**And** the shell continues to function normally
**And** the hook silently exits if awsprof is not available

### AC2: Corrupted Credentials File

**Given** the credentials file is corrupted or unreadable
**When** the detection hook attempts to read profiles
**Then** errors are suppressed in the hook
**And** the user's prompt appears normally
**And** error details are only shown when running awsprof commands directly

### AC3: Invalid Profile Name in .awsprofile

**Given** the `.awsprofile` file contains an invalid profile name
**When** the user is prompted to switch
**Then** the switch attempt displays an appropriate error message
**And** the shell remains functional
**And** the user can manually fix the issue

### AC4: Slow I/O or Network Mounts

**Given** disk I/O is slow or a network drive is mounted
**When** the PROMPT_COMMAND hook runs
**Then** timeouts or delays don't hang the shell
**And** the hook exits quickly even on I/O errors

### AC5: Multiple Terminal Sessions

**Given** multiple terminal tabs/windows are open
**When** profiles are switched in one window
**Then** each window maintains its own AWS_PROFILE
**And** `.awsprofile` detection works independently per session

## Tasks / Subtasks

- [ ] Add error handling to shell hook functions (AC: 1, 2, 3, 4, 5)
  - [ ] Ensure `awsprof_hook_detect_profile()` returns 0 always (non-blocking)
  - [ ] Suppress all stderr output from hook to /dev/null
  - [ ] Add defensive checks for command existence before calling
  - [ ] Add timeout protection for file reads on slow I/O
  - [ ] Verify hook doesn't block even on major errors
  - [ ] Add error suppression in all sub-function calls

- [ ] Test missing awsprof executable scenario (AC: 1)
  - [ ] Test hook behavior when awsprof is deleted
  - [ ] Verify no error messages appear
  - [ ] Verify shell remains functional
  - [ ] Verify hook returns 0 (non-blocking)

- [ ] Test corrupted credentials file scenario (AC: 2)
  - [ ] Create corrupted/invalid credentials file
  - [ ] Test hook runs without displaying errors
  - [ ] Test direct command shows proper error message
  - [ ] Verify shell remains functional

- [ ] Test invalid profile name handling (AC: 3)
  - [ ] Create .awsprofile with non-existent profile name
  - [ ] Test prompt response attempts switch
  - [ ] Verify error message shown when switch fails
  - [ ] Verify shell remains functional
  - [ ] Verify user can manually fix and retry

- [ ] Test slow I/O and timeout scenarios (AC: 4)
  - [ ] Test hook with slow file access
  - [ ] Verify timeout doesn't hang shell
  - [ ] Verify fast failure on I/O errors
  - [ ] Measure hook execution time (should stay <50ms)

- [ ] Test session independence (AC: 5)
  - [ ] Open multiple shell sessions
  - [ ] Switch profile in one session
  - [ ] Verify other sessions unaffected
  - [ ] Verify each maintains own AWS_PROFILE

## Dev Notes

### Critical Context from Stories 3.1-3.5

**What Stories 3.1-3.5 Implemented:**
- ✅ Story 3.1: PROMPT_COMMAND hook initialization for bash
- ✅ Story 3.2: POSIX sh initialization (without hooks)
- ✅ Story 3.3: `.awsprofile` file reading helper function
- ✅ Story 3.4: Directory change detection hook (`awsprof_hook_detect_profile()`)
- ✅ Story 3.5: Interactive prompt for profile switching (`awsprof_prompt_switch_profile()`)

**Current Hook Structure:**
```
awsprof_hook_detect_profile()
  ├─ Reads .awsprofile via awsprof_util_read_awsprofile()
  ├─ Compares with AWS_PROFILE environment variable
  ├─ Displays warning on mismatch
  └─ Calls awsprof_prompt_switch_profile() if mismatch
```

**Key Pattern from Stories 3.1-3.5 to Enhance:**
- Hook functions named `awsprof_hook_*()` for PROMPT_COMMAND
- Error suppression with `2>/dev/null`
- Non-blocking execution (always returns 0)
- Performance-critical (<10ms requirement = <50ms in tests)
- Silent failure on missing files/commands
- Messages to stderr only

### Error Handling Strategy

**Current Error Handling (Stories 3.1-3.5):**
- Suppress errors in hooks with `2>/dev/null`
- Return 0 always (non-blocking)
- Silent on missing files (empty string means no expectation)

**What Story 3.6 Adds:**
- Defensive checks before calling external commands
- Timeout protection for file operations
- Explicit error suppression at all levels
- Graceful degradation (continue without switching on any error)
- Shell always remains functional (NFR13 requirement)

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**NFR13 Requirement:**
- Shell integration failures do not break normal shell operation
- Hook must ALWAYS return 0 (non-blocking)
- No error messages visible to user (in hook context)
- Shell prompt appears normally even on complete failure

**Error Handling Standards:**
- Suppress all errors in PROMPT_COMMAND hooks
- Show errors only for direct awsprof command invocation
- Graceful failure paths (no hanging, timeouts)
- Fast execution even under error conditions

**Session Independence:**
- Each shell session has independent AWS_PROFILE
- `.awsprofile` detection per-session (directory context)
- No cross-session state sharing (environment variables isolated)

### Implementation Strategy

**Core Design:**
1. **Defensive Programming** - Check file/command existence before use
2. **Error Suppression** - Redirect all stderr to /dev/null in hook calls
3. **Timeout Protection** - Quick exit on slow I/O (already have read timeout)
4. **Graceful Degradation** - Skip switching attempt on any error, continue normally
5. **Return Code Consistency** - Always return 0 from hook (never fail)

**Key Code Patterns:**
```bash
# Pattern 1: Check command exists before calling
if ! command -v awsprof &>/dev/null; then
    return 0  # Graceful exit if command missing
fi

# Pattern 2: Suppress errors at all levels
hook_function_call 2>/dev/null || true

# Pattern 3: Error-safe file read with builtin only
[[ -f file_path ]] && read_content=$(cat file_path 2>/dev/null) || read_content=""

# Pattern 4: Always return 0 from hook
return 0  # Hook must never fail
```

**File Operations Safety:**
- Use `[[ -f file ]]` to check before read (shell builtin, no error)
- Use `cat` with stderr suppression for reads
- No complex operations in hot path (hook runs on every prompt)

**Command Availability Checking:**
- Check `awsprof` executable exists at hook startup (Story 3.1)
- Verify functions are defined before calling (bash-specific)
- Handle case where awsprof binary was deleted during session

### Testing Strategy & Coverage

**Error Scenario Tests:**

1. **Missing awsprof Executable (AC1)**
   - Temporarily move/delete awsprof executable
   - Run hook
   - Verify: no error output, hook returns 0, shell functional
   - Restore awsprof

2. **Corrupted Credentials File (AC2)**
   - Create invalid AWS credentials file format
   - Try to read profile with `awsprof use` (should error with message)
   - Run hook with same credentials file (should suppress error)
   - Verify: hook silent, direct command shows error

3. **Invalid Profile Name (AC3)**
   - Create `.awsprofile` with non-existent profile name
   - Run hook with mismatch and 'y' response
   - Verify: error shown when attempting switch
   - Verify: shell remains functional

4. **Slow I/O Scenario (AC4)**
   - Test with slow file access (network mount simulation)
   - Verify hook completes quickly
   - Check hook execution time stays <50ms

5. **Session Independence (AC5)**
   - Open multiple bash sessions in parallel
   - Switch profile in one
   - Verify others unaffected
   - Verify own AWS_PROFILE values different per session

**Test Patterns from Stories 3.1-3.5:**
- Use temporary directories for `.awsprofile` files
- Set AWS_PROFILE environment variable in test
- Call `awsprof --hook-detect-profile` to test hook
- Measure execution time with `time` command
- Verify output and exit codes
- Clean up test files after each test

### Project Structure & Code Navigation

**Files to Modify:**
- `/awsprof` - Main script
  - Function: `awsprof_hook_detect_profile()` - Already has error suppression, enhance with defensive checks
  - Function: `awsprof_prompt_switch_profile()` - Already handles errors, verify robustness
  - Function: `awsprof_cmd_init()` - Verify hook is properly registered
  - Execution: Add defensive checks before calling hooks

- `/tests/test_commands.sh` - Test suite
  - Add 5-6 new tests for error handling scenarios

**Existing Dependencies (From Stories 3.1-3.5):**
- `awsprof_hook_detect_profile()` - Story 3.4 (enhance with error handling)
- `awsprof_prompt_switch_profile()` - Story 3.5 (verify robustness)
- `awsprof_util_read_awsprofile()` - Story 3.3 (already error-safe)
- `awsprof_cmd_use()` - Story 1.3 (called by prompt, handles errors)
- PROMPT_COMMAND integration - Story 3.1

**Script Organization:**
```
Current sections:
  #=== SHELL INTEGRATION ===
    - awsprof_hook_detect_profile()       [Story 3.4 - enhance error handling]
    - awsprof_prompt_switch_profile()     [Story 3.5 - verify robustness]
    - awsprof_cmd_init()                  [Story 3.1 - verify hook registration]

No new functions needed - enhance existing functions with error handling
```

### Learnings & Patterns from Stories 2.1-3.5

**Error Handling Patterns Established:**
- Suppress errors in interactive/hook code with `2>/dev/null`
- Check file existence with `[[ -f file ]]` (shell builtin)
- Provide graceful exit on missing prerequisites
- Different error handling for direct commands vs hooks:
  - Hooks: silent (errors suppressed)
  - Commands: show errors to user

**Testing Pattern Consistency:**
- Create test scenarios in temporary directories
- Use environment variable setup for test context
- Call functions/commands and verify behavior
- Check both output and exit codes
- Clean up test files after each test

**Performance Optimization Lessons:**
- Hook must complete quickly (<10ms in practice, <50ms in test)
- Minimize file operations in PROMPT_COMMAND
- Use shell builtins when possible (faster than external commands)
- Fail fast on errors (don't continue if unnecessary)

**Robustness Patterns:**
- Always return 0 from hook (never fail)
- Suppress all errors in hook
- Show errors only in direct command context
- Check prerequisites before operations
- Timeout protection for file operations

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-3.6-Shell-Integration-Robustness, lines 700-741]
- [Source: _bmad-output/planning-artifacts/prd.md#NFR13-Shell-never-breaks]
- [Source: _bmad-output/planning-artifacts/architecture.md#Error-Handling]
- [Source: _bmad-output/implementation-artifacts/3-1-shell-initialization-script-for-bash.md] - Hook initialization pattern
- [Source: _bmad-output/implementation-artifacts/3-4-directory-change-detection-and-profile-comparison.md] - Hook error suppression
- [Source: _bmad-output/implementation-artifacts/3-5-interactive-profile-switch-prompt.md] - Prompt function robustness

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
