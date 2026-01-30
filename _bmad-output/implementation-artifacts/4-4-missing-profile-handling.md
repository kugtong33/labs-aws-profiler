# Story 4.4: Missing Profile Handling

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want a warning and a cleared `AWS_PROFILE` when `.awsprofile` references a non-existent profile,
so that I avoid accidentally running commands against the wrong account.

## Acceptance Criteria

1. **Given** a `.awsprofile` specifies a profile that does not exist in credentials  
   **When** the hook evaluates the file  
   **Then** a warning is written to stderr indicating the profile does not exist  
   **And** `AWS_PROFILE` is cleared (unset or set to empty)
2. **Given** the profile is later added to credentials  
   **When** the hook runs again in the same directory  
   **Then** the profile is applied normally

## Tasks / Subtasks

- [x] Task 1: Missing profile handling in hook (AC: 1, 2)
  - [x] Subtask 1.1: Detect missing profile after resolving `.awsprofile`
  - [x] Subtask 1.2: Emit warning to stderr and clear `AWS_PROFILE`
  - [x] Subtask 1.3: Apply profile normally once credentials exist
- [x] Task 2: Tests for missing profile handling (AC: 1, 2)
  - [x] Subtask 2.1: Add test for warning + cleared `AWS_PROFILE`
  - [x] Subtask 2.2: Add test for normal behavior after profile is added

## Dev Notes

- Architecture: single-file `awsprof` script, bash 4.0+, POSIX sh support for init; use `awsprof_<module>_<action>` naming [Source: _bmad-output/planning-artifacts/architecture.md#Script Organization]
- Output rules: user messages to stderr; eval-only export to stdout (for `use` and hook behavior) [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- INI parsing is awk-based; use `awsprof_ini_list_sections` to validate profile existence [Source: _bmad-output/planning-artifacts/architecture.md#File Handling]
- Hook entry: `awsprof_hook_detect_profile` and init output in `awsprof_cmd_init`; hook should be fast and safe [Source: _bmad-output/planning-artifacts/architecture.md#Shell Integration]
- Missing profile behavior must warn and clear AWS_PROFILE for `.awsprofile` paths [Source: _bmad-output/planning-artifacts/epics.md#Story 4.4]
- Source files to touch: `awsprof` (hook logic), `tests/test_commands.sh` (tests)
- Keep stdout eval-only: hook should emit export command to stdout and warnings to stderr for eval safety

### Developer Context

- Missing profile handling applies to both project and global `.awsprofile`.
- Clearing AWS_PROFILE should not emit any export to stdout for missing profiles.
- Preserve silent behavior when no `.awsprofile` exists.

### Technical Requirements

- If profile is missing, warn on stderr and clear AWS_PROFILE (unset or empty) in the current shell.
- If profile is later added, the hook should switch normally.

### Architecture Compliance

- Maintain single-file layout in `awsprof`.
- Preserve stderr/stdout separation (stderr for user messages, stdout for eval-only).

### Library / Framework Requirements

- Bash 4.0+ only; no new dependencies.

### File Structure Requirements

- Update `awsprof` hook logic only; avoid new files unless tests require fixtures.
- Tests should live in `tests/test_commands.sh`.

### Testing Requirements

- Add tests for warning + cleared AWS_PROFILE when profile missing.
- Add tests for normal behavior after adding the profile.

### Project Structure Notes

- Single-file CLI: all changes go in `awsprof`, under utility/shell integration sections.
- Tests live in `tests/`; use `AWS_SHARED_CREDENTIALS_FILE` with fixtures in `tests/fixtures/`.

### References

- Epic 4 Story 4.4 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 4.4]
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
- `bash tests/test_ini.sh`
### Completion Notes List

- Added missing-profile warning + clear behavior in hook.
- Added tests for missing-profile warning/clear and normal behavior after adding profile.
### File List

- awsprof
- tests/test_commands.sh

## Change Log

- 2026-01-30: Added missing profile handling and tests.
