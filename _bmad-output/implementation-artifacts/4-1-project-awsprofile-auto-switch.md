# Story 4.1: Project .awsprofile Auto-Switch

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want the shell hook to read a project `.awsprofile` and immediately switch to that profile when it is valid,
so that I enter the project already targeting the correct AWS account.

## Acceptance Criteria

1. **Given** a directory contains a `.awsprofile` file with a valid profile name and the credentials file includes that profile  
   **When** the shell integration hook runs  
   **Then** `AWS_PROFILE` is set to that profile  
   **And** no mismatch prompt is shown
2. **Given** the `.awsprofile` file contains leading or trailing whitespace around the profile name  
   **When** the file is read  
   **Then** the whitespace is trimmed before validation and switch

## Tasks / Subtasks

- [x] Task 1: Auto-switch when project `.awsprofile` is present (AC: 1, 2)
  - [x] Subtask 1.1: Read the project `.awsprofile` using `awsprof_util_read_awsprofile` and keep missing file silent
  - [x] Subtask 1.2: Validate the profile exists via `awsprof_ini_list_sections` before switching
  - [x] Subtask 1.3: Ensure no mismatch warning/prompt is shown for valid project profile
- [x] Task 2: Hook evaluation path updates (AC: 1)
  - [x] Subtask 2.1: Update the bash init hook to eval export output from `--hook-detect-profile`
  - [x] Subtask 2.2: Keep stdout eval-only and send any user messages to stderr
- [x] Task 3: Tests for hook behavior (AC: 1, 2)
  - [x] Subtask 3.1: Add tests for `--hook-detect-profile` output with valid project `.awsprofile`
  - [x] Subtask 3.2: Add a test for whitespace-trimming behavior

## Dev Notes

- Architecture: single-file `awsprof` script, bash 4.0+, POSIX sh support for init; use `awsprof_<module>_<action>` naming [Source: _bmad-output/planning-artifacts/architecture.md#Script Organization]
- Output rules: user messages to stderr; eval-only export to stdout (for `use` and hook behavior) [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- INI parsing is awk-based; use `awsprof_ini_list_sections` to validate profile existence [Source: _bmad-output/planning-artifacts/architecture.md#File Handling]
- Hook entry: `awsprof_hook_detect_profile` and init output in `awsprof_cmd_init`; hook should be fast and safe [Source: _bmad-output/planning-artifacts/architecture.md#Shell Integration]
- Current behavior shows mismatch warning and optional prompt; this story removes mismatch warnings for valid project profile [Source: awsprof#awsprof_hook_detect_profile]
- Source files to touch: `awsprof` (hook behavior + init output), `tests/test_commands.sh` (new tests)
- Keep stdout eval-only: hook should emit export command to stdout and any warnings to stderr for eval safety

### Developer Context

- The hook should apply a valid project `.awsprofile` immediately, not prompt or warn on mismatch.
- Use `awsprof_util_read_awsprofile` for trimming/empty handling.
- For switching, reuse `awsprof_cmd_use` (ensures profile validation + export format), but ensure stdout remains eval-only and stderr handles messages.

### Technical Requirements

- If `.awsprofile` exists and profile is valid, output `export AWS_PROFILE=<name>` to stdout and avoid any mismatch warnings.
- Trim whitespace before validation.
- If profile is invalid, defer to follow-up story behavior (warn/clear happens in Story 4.4); do not implement that here.
- Hook must remain fast and safe (no slow I/O beyond reading `.awsprofile` + credentials list).

### Architecture Compliance

- Maintain single-file layout in `awsprof`.
- Use existing INI helpers (`awsprof_ini_list_sections`) and utility (`awsprof_util_read_awsprofile`).
- Preserve stderr/stdout separation (stderr for user messages, stdout for eval-only).

### Library / Framework Requirements

- Bash 4.0+ only; no new dependencies.

### File Structure Requirements

- Update `awsprof` hook and init output only; avoid new files unless tests require fixtures.
- Tests should live in `tests/test_commands.sh` using existing fixture patterns.

### Testing Requirements

- Add test(s) for `--hook-detect-profile` to confirm eval output for valid project `.awsprofile`.
- Add whitespace-trimming test for `.awsprofile` content.
- Keep test output parsing consistent with existing tests (stderr vs stdout).

### Project Structure Notes

- Single-file CLI: all changes go in `awsprof`, under utility/shell integration sections.
- Tests live in `tests/`; use `AWS_SHARED_CREDENTIALS_FILE` with fixtures in `tests/fixtures/`.

### References

- Epic 4 Story 4.1 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 4.1]
- Hook behavior and init script [Source: awsprof#awsprof_hook_detect_profile]
- Architecture constraints and output rules [Source: _bmad-output/planning-artifacts/architecture.md]

### Project Context Reference

- No project-context.md found.

### Story Completion Status

- Status set to `ready-for-dev`

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex CLI)

### Debug Log References

- `bash tests/test_commands.sh`
### Completion Notes List

- Implemented auto-switch for valid project `.awsprofile` via hook export output.
- Updated bash init hook to eval hook output.
- Added tests for hook auto-switch and whitespace trimming; all command tests pass.
- Ultimate context engine analysis completed - comprehensive developer guide created
### File List

- awsprof
- tests/test_commands.sh

## Change Log

- 2026-01-30: Implemented project `.awsprofile` auto-switch and updated hook/init tests.
