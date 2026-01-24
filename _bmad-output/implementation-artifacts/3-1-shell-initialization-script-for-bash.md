# Story 3.1: Shell Initialization Script for Bash

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to source awsprof's shell integration in my bashrc,
So that profile detection and switching work seamlessly in my shell.

## Acceptance Criteria

### AC1: Output eval-able shell initialization code

**Given** the user runs `awsprof init`
**When** the command executes
**Then** shell code is output to stdout suitable for eval (FR26)
**And** the code defines an `awsprof` wrapper function that calls `eval "$(command awsprof "$@")"`
**And** the code adds a PROMPT_COMMAND hook for directory change detection (Architecture)
**And** the output is valid bash 4.0+ syntax (NFR17)

### AC2: Enable wrapper function and PROMPT_COMMAND integration

**Given** the user adds `eval "$(awsprof init)"` to their `~/.bashrc`
**When** they start a new bash shell
**Then** the awsprof wrapper function is available
**And** the PROMPT_COMMAND hook is active
**And** their shell starts normally without errors (NFR13)

### AC3: Allow profile switching through wrapper

**Given** the shell integration is loaded
**When** the user types `awsprof use profile-name`
**Then** the wrapper function executes and sets AWS_PROFILE in the current shell
**And** no subshell limitations prevent the environment variable export

### AC4: Handle missing awsprof executable gracefully

**Given** the awsprof executable is not in PATH
**When** the init code runs
**Then** the shell integration fails gracefully (NFR13)
**And** the shell remains functional

## Tasks / Subtasks

- [ ] Implement `awsprof_cmd_init()` function in main script (AC: 1, 2, 3, 4)
  - [ ] Create function that outputs bash shell initialization code
  - [ ] Output wrapper function definition that calls `eval "$(command awsprof "$@")"`
  - [ ] Output PROMPT_COMMAND hook setup (will call detection function)
  - [ ] Ensure bash 4.0+ syntax compatibility
  - [ ] Validate output is syntactically correct bash
  - [ ] Test output can be eval'd without errors

- [ ] Add `init` command to main dispatch (AC: 1)
  - [ ] Add case statement entry for `init`
  - [ ] Call `awsprof_cmd_init` with no parameters
  - [ ] Update help text to include `init` command

- [ ] Create shell detection hook function for PROMPT_COMMAND (AC: 2, 3)
  - [ ] Implement `awsprof_hook_detect_profile()` function
  - [ ] Function reads current `AWS_PROFILE` environment variable
  - [ ] Function checks if `.awsprofile` file exists in current directory
  - [ ] Function compares expected vs actual profile (story 3.4 integration)
  - [ ] Function will be called from PROMPT_COMMAND hook

- [ ] Write comprehensive tests (AC: 1, 2, 3, 4)
  - [ ] Test: init command outputs valid bash syntax
  - [ ] Test: Output can be eval'd without errors
  - [ ] Test: Wrapper function is defined after eval
  - [ ] Test: PROMPT_COMMAND is set after eval
  - [ ] Test: Wrapper function delegates to awsprof command
  - [ ] Test: awsprof command execution via wrapper succeeds
  - [ ] Test: init works when awsprof is in PATH
  - [ ] Test: init fails gracefully when awsprof not in PATH
  - [ ] Test: Multiple sourcing of init doesn't duplicate hooks
  - [ ] Test: Shell remains functional after failed init attempt

## Dev Notes

### Critical Context from Epic 2

**What Was Just Built (Stories 2-1 through 2-5):**
- ✅ Complete profile management system (add, edit, remove, list, import)
- ✅ INI file reading and writing infrastructure
- ✅ Credential validation and secure input
- ✅ All core awsprof commands implemented
- ✅ File operations with atomic writes and backups
- ✅ All 10 stories in Epics 1 and 2 complete with code review passed

**Git Commits:**
- `b99f19c` - Code review completion for stories 2-1 through 2-5
- `b8328a5` - Code review fixes (strict validation, exit codes, argument validation)
- `cf703ea` - Story 2.5 implementation (import profiles)
- `e061678` - Story 2.4 implementation (remove profile)
- `d6eabb2` - Story 2.3 implementation (edit profile)

**Files Created/Modified in Epic 2:**
- `awsprof` - Complete profile management commands (Stories 2.1-2.5)
- `tests/test_commands.sh` - 69 passing command tests
- `tests/test_ini.sh` - 24 passing INI tests

**KEY LEARNINGS from Previous Stories:**
- Single file structure (`awsprof`) working well for code organization
- Function naming pattern `awsprof_<module>_<action>` is established
- All messages to stderr via `awsprof_msg()`, `awsprof_error()`, `awsprof_success()`
- Exit codes: 0 for success, 1 for error
- Eval pattern for stdout: `echo "export AWS_PROFILE=..."`
- Test pattern: mock files, isolation with setup/teardown, clear assertions

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Shell Integration Patterns:**
- PROMPT_COMMAND mechanism for directory change detection (Architecture)
- Wrapper function pattern to overcome subprocess environment variable limitation
- Eval wrapper pattern: `eval "$(command awsprof use profile)"`
- Bash 4.0+ required for PROMPT_COMMAND, NFR17 specifies this
- Messages to stderr, eval-able code to stdout only

**Function Naming Convention:**
```bash
Pattern: awsprof_<module>_<action>
Applied: awsprof_cmd_init() [command module, init action]
        awsprof_hook_detect_profile() [hook module, detect_profile action]
Locals: Use `local` keyword for all function-local variables
```

**Output Pattern - CRITICAL FOR SHELL INTEGRATION:**
```bash
# Init command outputs shell code suitable for: eval "$(awsprof init)"
# Must contain:
# 1. awsprof wrapper function definition
# 2. PROMPT_COMMAND hook setup
# All output to stdout (not stderr)
# Syntax must be bash 4.0+ compatible
```

**Bash Version Compatibility:**
- Minimum version: bash 4.0 (NFR17)
- Feature needed: PROMPT_COMMAND (available since bash 2.0, but bash 4.0 baseline)
- Avoid bashisms for hook (use POSIX where possible for maintainability)
- Array syntax available in bash 4.0+ for wrapper function parameters

### Implementation Sequence & Key Decisions

**Core Logic Flow - Init Command:**
1. Function `awsprof_cmd_init()` produces shell initialization code
2. Code defines wrapper function: `awsprof() { eval "$(command awsprof "$@")" }`
3. Code sets up PROMPT_COMMAND with detection hook
4. All output goes to stdout (suitable for `eval "$(awsprof init)"`)
5. Messages (if any) go to stderr

**Wrapper Function Pattern (CRITICAL):**
```bash
# Why this pattern works:
# - `command awsprof` finds the actual awsprof script (not the function)
# - `eval "$(command awsprof "$@")"` executes output in current shell
# - Environment variables (AWS_PROFILE) set in parent shell, not subprocess
# - Parameters ($@) passed through to actual awsprof command
# - This is THE standard pattern for shell tools (aws-vault, rbenv, etc.)
```

**PROMPT_COMMAND Hook Integration:**
- Detection hook will be called on every prompt (after each command)
- Hook should be fast (<10ms) per NFR3
- Hook will eventually check for `.awsprofile` file (story 3.4)
- Hook will compare profiles and potentially prompt user (story 3.5)
- For now (Story 3.1): Just define hook, shell code framework

**Key Design Notes:**
- Story 3.1 provides shell initialization OUTPUT, not the detection logic
- Detection logic (checking .awsprofile, comparing profiles) will be in Stories 3.4-3.6
- This story just scaffolds the hook and outputs proper bash code
- Hook function itself (`awsprof_hook_detect_profile`) will be stubbed/simple for now

### Testing Requirements

**Based on Stories 2.2-2.5 pattern (bash unit tests in tests/test_commands.sh):**

**Unit Tests:**
1. Test: Init command outputs valid bash syntax
   - Run `awsprof init` and validate output is syntactically correct
   - Try to `bash -n` on the output (syntax check)

2. Test: Output can be eval'd without errors
   - Capture `awsprof init` output
   - Run `eval "$output"` in a subshell
   - Verify no errors occur

3. Test: Wrapper function is defined after eval
   - After eval, run `type awsprof` or `declare -f awsprof`
   - Verify function exists and is callable

4. Test: PROMPT_COMMAND is set after eval
   - After eval, check `echo $PROMPT_COMMAND`
   - Verify it contains reference to detection hook

5. Test: Wrapper function delegates to awsprof command
   - After eval, call `awsprof help`
   - Verify help output is from actual awsprof command
   - Test with `awsprof use` to verify eval pattern works

6. Test: Init works when awsprof is in PATH
   - Add current directory to PATH
   - Run init command
   - Verify output contains valid wrapper function

7. Test: Init fails gracefully when awsprof not in PATH
   - Temporarily remove from PATH
   - Run init command
   - Verify graceful error message (if applicable)
   - Or verify it still outputs code but with comment about awsprof not in PATH

8. Test: Multiple sourcing doesn't duplicate hooks
   - Source init code twice in same shell
   - Verify PROMPT_COMMAND doesn't have duplicate hooks
   - Use `PROMPT_COMMAND_COUNT` or similar to validate

**Integration Tests (with story 3.4 once available):**
9. Test: Shell remains functional after successful init
   - After eval, verify shell commands work (cd, ls, etc.)
   - Verify prompt displays normally

10. Test: Shell remains functional if init fails
    - Test with broken output or missing command
    - Verify user can still use shell

### Project Structure & Code Navigation

**Files to Modify:**
- `/awsprof` - Main script
  - Section: `#=== CONFIGURATION ===` - May need HOOK_DETECT_PROFILE definition
  - Section: `#=== PROFILE COMMANDS ===` - Add `awsprof_cmd_init()` function
  - Section: `#=== SHELL INTEGRATION ===` (NEW) - Add `awsprof_hook_detect_profile()` function
  - Section: `#=== MAIN DISPATCH ===` - Add `init` case statement
  - Update help text with `init` command

- `/tests/test_commands.sh` - Test suite
  - Add 10 new tests for init command

**Dependencies (Already Implemented):**
- `awsprof_msg()`, `awsprof_error()`, `awsprof_success()` - Output helpers (Story 1.1)
- `awsprof_ini_list_sections()` - Will use in hook for future stories
- Main script infrastructure - Single file pattern established

**Script Organization:**
```
Current sections:
  #=== CONFIGURATION ===         (paths, constants)
  #=== OUTPUT UTILITIES ===       (messages)
  #=== INI HANDLING ===          (parsing, reading, writing - Stories 1.1, 2.1)
  #=== FILE OPERATIONS ===       (backup, atomic write - Story 2.1)
  #=== PROFILE COMMANDS ===      (list, use, whoami, add, edit, remove, import - Stories 1-2)
  #=== MAIN DISPATCH ===         (command routing - ALL stories)

NEW for Story 3.1:
  #=== SHELL INTEGRATION ===     (init, hooks - Story 3.1+)
    - awsprof_hook_detect_profile() [defined but simple for now]
```

### Learnings from Stories 2.1-2.5

**Code Patterns Established:**
- Single file structure with clear section comments
- Function naming: `awsprof_cmd_<command>()` for user-facing commands
- Function naming: `awsprof_hook_<function>()` for shell hooks
- All output to stderr: `awsprof_msg()`, `awsprof_error()`, `awsprof_success()`
- Code to stdout: Plain `echo` statements (no prefix)
- Exit codes: 0 on success, 1 on error
- Tests follow simple setup → execute → assert → cleanup pattern

**Architecture Decisions:**
- Avoid complex bash features when possible (readability)
- Use awk for complex parsing (proven pattern from Story 1.1)
- Error checking required: Always check command returns before proceeding
- Messages must clearly distinguish errors from info

**What to Avoid (from code review):**
- Extra arguments not validated → Validate positional arguments
- Inconsistent exit codes → Maintain exit code semantics
- Silent failures → Always check critical operations fail explicitly

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-3.1-Shell-Initialization-Script-for-Bash]
- [Source: _bmad-output/planning-artifacts/architecture.md#Technical-Stack, #Shell-Integration]
- [Source: _bmad-output/planning-artifacts/prd.md#FR23, FR26, NFR13, NFR17]
- [Source: _bmad-output/implementation-artifacts/2-2-add-new-profile.md#Dev-Notes] - Command pattern reference
- [Source: _bmad-output/implementation-artifacts/2-4-remove-profile.md#Dev-Notes] - Function structure reference
- [Source: Recent commits] - Git patterns from Epic 2 implementation

---

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5 (claude-haiku-4-5-20251001)

### Debug Log References

### Completion Notes List

### File List

- (To be completed during implementation)
