# Story 3.2: POSIX sh Initialization Script

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer using POSIX sh,
I want basic awsprof functionality in my sh environment,
So that I can switch profiles even in minimal shell environments.

## Acceptance Criteria

### AC1: Output POSIX sh compatible initialization code

**Given** the user runs `awsprof init --sh`
**When** the command executes
**Then** POSIX sh compatible code is output to stdout (FR24)
**And** the code defines an `awsprof` wrapper function using POSIX syntax
**And** a note is included that automatic detection is not available (no PROMPT_COMMAND equivalent)
**And** the output contains only POSIX sh compatible syntax (NFR17)

### AC2: Enable profile switching in POSIX sh environment

**Given** the user sources the sh init code in their shell
**When** they use `awsprof use profile-name`
**Then** the profile switch works correctly
**And** AWS_PROFILE is set in the current shell
**And** the wrapper function properly executes the awsprof command

### AC3: Document POSIX sh limitations

**Given** POSIX sh limitations without PROMPT_COMMAND
**When** the user enters a directory
**Then** automatic .awsprofile detection does not occur (by design)
**And** documentation clearly explains this limitation
**And** users know they can manually run `awsprof check` for verification

### AC4: Ensure graceful degradation with minimal shell

**Given** the user is in a minimal POSIX sh environment
**When** shell integration code is executed
**Then** the shell remains functional (NFR13)
**And** error handling prevents shell breakage
**And** wrapper function fails gracefully if awsprof not found

## Tasks / Subtasks

- [ ] Extend `awsprof_cmd_init()` to support `--sh` flag (AC: 1, 2, 3, 4)
  - [ ] Add `--sh` parameter handling to init command
  - [ ] Detect and differentiate between bash and sh modes
  - [ ] Output POSIX sh compatible code for sh mode
  - [ ] Use POSIX syntax only (no bash arrays, PROMPT_COMMAND, etc.)
  - [ ] Include clear documentation about POSIX limitations
  - [ ] Validate output is POSIX sh compatible

- [ ] Implement POSIX sh wrapper function (AC: 2)
  - [ ] Define `awsprof()` wrapper function using POSIX syntax
  - [ ] Handle parameter passing without bash arrays
  - [ ] Use proper variable expansion (no $() if possible, use backticks)
  - [ ] Ensure profile switching works via eval pattern
  - [ ] Test wrapper works in minimal sh environments

- [ ] Add documentation about POSIX sh limitations (AC: 3)
  - [ ] Document that automatic detection is not available
  - [ ] Explain why PROMPT_COMMAND equivalent doesn't exist in POSIX sh
  - [ ] Reference manual `awsprof check` command (for Story 3.4)
  - [ ] Provide usage examples for POSIX sh

- [ ] Write comprehensive tests for POSIX sh initialization (AC: 1, 2, 3, 4)
  - [ ] Test: init --sh outputs valid POSIX sh syntax
  - [ ] Test: Output can be eval'd without errors in sh
  - [ ] Test: Wrapper function is defined after eval in sh
  - [ ] Test: Profile switching works through wrapper in sh
  - [ ] Test: init defaults to bash (no flag)
  - [ ] Test: init --sh produces different output than init
  - [ ] Test: POSIX sh environment variables work correctly
  - [ ] Test: Wrapper handles missing awsprof gracefully in sh
  - [ ] Test: Documentation note about limitations is present
  - [ ] Test: Shell remains functional with sh initialization

## Dev Notes

### Critical Context from Story 3.1 (Just Completed)

**What Story 3.1 Implemented:**
- ✅ `awsprof init` command for bash shell initialization
- ✅ Wrapper function: `awsprof() { eval "$(command awsprof "$@")" }`
- ✅ PROMPT_COMMAND hook setup for directory change detection
- ✅ Dynamic path resolution for awsprof executable
- ✅ All 10 tests passing, full test suite: 103/103

**Key Pattern from Story 3.1 to Reuse:**
- Init command outputs code suitable for: `eval "$(awsprof init [options])"`
- Wrapper function uses `eval` pattern to overcome shell subprocess limitations
- All code to stdout, no stderr (except errors)
- Dynamic path resolution via `command -v awsprof`
- Exit code: 0 (always success, informational command)

**Git Commits Reference:**
- `86ae24e` - Story 3.1 implementation (bash init)
- `e174eb8` - Story 3.1 creation (story file)

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Shell Integration Patterns:**
- Bash 4.0+ required for PROMPT_COMMAND (NFR17)
- POSIX sh: No equivalent to PROMPT_COMMAND - limitation by design
- Both environments require eval wrapper pattern for environment variables
- Manual check command needed for POSIX sh instead of automatic detection

**POSIX Compliance (Critical for Story 3.2):**
- No bash-specific features: arrays, PROMPT_COMMAND, ${parameter//pattern/string}
- No ANSI-C quoting $'...'
- Avoid: `[[...]]` conditional (use `[...]` instead)
- Avoid: `((...))` arithmetic (use `expr` or `test` instead)
- Parameter expansion: Use portable forms only
- Function definitions: `name() { commands; }` is POSIX
- Command substitution: Backticks `` `...` `` more portable than `$(...)`

**Exit Code Semantics (Established Pattern):**
- Init command: Always exit 0 (informational, non-fatal)
- Wrapper failures: Shell remains functional, no error break
- Following Story 3.1 and Epic 2 patterns

### Implementation Sequence & Key Decisions

**Core Logic Flow:**
1. Detect `--sh` flag parameter to `awsprof init`
2. If `--sh` flag: output POSIX sh code
3. If no flag or default: output bash code (backward compat with Story 3.1)
4. POSIX sh code: Wrapper function only (no PROMPT_COMMAND)
5. Include documentation about limitations

**POSIX vs Bash Key Differences:**
```bash
# Bash (Story 3.1):
awsprof() {
    eval "$(command awsprof "$@")"
}
export PROMPT_COMMAND='awsprof_hook_detect_profile'

# POSIX sh (Story 3.2):
awsprof() {
    eval "`command awsprof \"$@\"`"
}
# No PROMPT_COMMAND equivalent - no auto-detection
```

**Parameter Handling:**
- Bash: Can use `"$@"` in functions naturally
- POSIX sh: Same `"$@"` works (POSIX standard), but fewer array features overall
- No destructuring or parameter expansion variants in POSIX

**Key Design Notes:**
- Story 3.2 shares same `awsprof_cmd_init()` function as Story 3.1, just with flag
- Conditional output based on `--sh` parameter
- No new hook functions needed (manual check handled by future stories)
- Keep code minimal and portable - POSIX sh is minimal environment
- Documentation must clearly explain no auto-detection in POSIX sh

### Testing Strategy & Coverage

**Based on Stories 2.2-3.1 pattern (bash unit tests in tests/test_commands.sh):**

**Critical Test Scenarios:**
1. **Happy path** - Init --sh outputs valid POSIX syntax, can be sourced
2. **Parameter handling** - Both `init` and `init --sh` work, produce different output
3. **Wrapper function** - Works in actual sh (not just bash)
4. **Profile switching** - Use command through wrapper in sh environment
5. **Error handling** - Missing awsprof, shell remains functional
6. **Documentation** - Note about limitations is present in output
7. **Backward compatibility** - Default init still bash code (no flag)

**Test Patterns from Story 3.1:**
- Use `bash -n` and `sh -n` for syntax checking
- Create subshells that source output and test functionality
- Verify function definitions with `type` or `declare -f`
- Test that actual command execution works through wrapper

**Edge Cases for POSIX sh:**
- Test in actual sh environment (not just syntax check)
- Verify no bash-specific syntax in sh mode output
- Check parameter expansion works correctly
- Validate backticks work vs $(...)
- Test in minimal sh without bash extensions

### Project Structure & Code Navigation

**Files to Modify:**
- `/awsprof` - Main script
  - Section: `#=== SHELL INTEGRATION ===`
  - Function: `awsprof_cmd_init()` - Extend to handle `--sh` flag
  - Update dispatch if needed (probably reuse existing `init` case)

- `/tests/test_commands.sh` - Test suite
  - Add 10 new tests for init --sh functionality

**Existing Dependencies (From Story 3.1):**
- `awsprof_cmd_init()` - Already exists, extend with flag handling
- Output helpers: `awsprof_msg()`, etc. (not needed for init)
- Pattern: `eval` wrapper with dynamic path resolution (reuse)

**Script Organization:**
```
Current sections:
  #=== SHELL INTEGRATION ===
    - awsprof_cmd_init()       [MODIFY: add --sh flag support]
    - awsprof_hook_detect_profile() [no change needed]
```

### Learnings & Patterns from Stories 2.1-3.1

**Code Reuse Strategy:**
- Extend existing `awsprof_cmd_init()` rather than create new function
- Reuse wrapper pattern and dynamic path resolution
- Keep test patterns consistent (use `sh` for tests instead of bash)

**POSIX Portability Lessons:**
- Backticks `` `...` `` vs `$(...)` - use backticks for maximum compatibility
- Test in actual sh, not just syntax validation
- Avoid [[...]] tests, use [...] single brackets
- Check manual pages for POSIX sh vs bash differences

**Testing Pattern Differences:**
- Story 3.1 tested `bash "$script"` for bash code
- Story 3.2 should test `sh "$script"` for sh code
- Both test in subshell with `eval` pattern

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-3.2-POSIX-sh-Initialization-Script, lines 549-579]
- [Source: _bmad-output/planning-artifacts/architecture.md#Shell-Integration, NFR17]
- [Source: _bmad-output/planning-artifacts/prd.md#FR24]
- [Source: _bmad-output/implementation-artifacts/3-1-shell-initialization-script-for-bash.md] - Reference for pattern and structure
- POSIX sh standard: https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html

---

## Dev Agent Record

### Agent Model Used

Claude Haiku 4.5 (claude-haiku-4-5-20251001)

### Debug Log References

### Completion Notes List

### File List

- (To be completed during implementation)
