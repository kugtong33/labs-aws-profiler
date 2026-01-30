# Story 4.3: Direct Use Without Mismatch Checks

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want the hook to use the profile specified in `.awsprofile` directly without mismatch warnings or prompts,
so that profile switching is automatic and silent.

## Acceptance Criteria

1. **Given** a `.awsprofile` file specifies a profile name  
   **When** the hook evaluates the directory  
   **Then** no mismatch warning or prompt is shown  
   **And** the specified profile is applied immediately
2. **Given** the current `AWS_PROFILE` already matches the `.awsprofile` value  
   **When** the hook runs  
   **Then** no output is produced

## Tasks / Subtasks

- [x] Task 1: Remove mismatch warning/prompt paths for `.awsprofile` (AC: 1, 2)
  - [x] Subtask 1.1: Ensure hook does not emit mismatch warnings in any `.awsprofile` path
  - [x] Subtask 1.2: Remove reliance on `awsprof_prompt_switch_profile` for `.awsprofile` handling
- [x] Task 2: Tests for silent direct use (AC: 1, 2)
  - [x] Subtask 2.1: Add test asserting no mismatch warning when `.awsprofile` is used
  - [x] Subtask 2.2: Add test asserting silent output when profile already matches

## Dev Notes

- Architecture: single-file `awsprof` script, bash 4.0+, POSIX sh support for init; use `awsprof_<module>_<action>` naming [Source: _bmad-output/planning-artifacts/architecture.md#Script Organization]
- Output rules: user messages to stderr; eval-only export to stdout (for `use` and hook behavior) [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- Hook entry: `awsprof_hook_detect_profile` and init output in `awsprof_cmd_init`; hook should be fast and safe [Source: _bmad-output/planning-artifacts/architecture.md#Shell Integration]
- Mismatch warning/prompt behavior must not be used for `.awsprofile` flows [Source: _bmad-output/planning-artifacts/epics.md#Story 4.3]
- Source files to touch: `awsprof` (hook logic), `tests/test_commands.sh` (tests)
- Keep stdout eval-only: hook should emit export command to stdout and any warnings to stderr for eval safety

### Developer Context

- `.awsprofile` should always drive profile selection directly with no prompt.
- If the current profile already matches, the hook stays silent.
- `awsprof_prompt_switch_profile` should not be used in any `.awsprofile` path.

### Technical Requirements

- Ensure no mismatch warning output remains for `.awsprofile` paths.
- Preserve silent behavior when profiles match.

### Architecture Compliance

- Maintain single-file layout in `awsprof`.
- Preserve stderr/stdout separation (stderr for user messages, stdout for eval-only).

### Library / Framework Requirements

- Bash 4.0+ only; no new dependencies.

### File Structure Requirements

- Update `awsprof` hook logic only; avoid new files unless tests require fixtures.
- Tests should live in `tests/test_commands.sh`.

### Testing Requirements

- Add tests verifying no mismatch warning for `.awsprofile` usage.
- Add tests verifying silent output when profile already matches.

### Project Structure Notes

- Single-file CLI: all changes go in `awsprof`, under utility/shell integration sections.
- Tests live in `tests/`; use `AWS_SHARED_CREDENTIALS_FILE` with fixtures in `tests/fixtures/`.

### References

- Epic 4 Story 4.3 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 4.3]
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

- Direct `.awsprofile` auto-switch is already implemented with no mismatch warnings/prompts.
- Existing tests cover silent behavior when profiles match and auto-switch behavior on mismatch.
### File List

- None (no code changes required for this story)

## Change Log

- 2026-01-30: Verified direct `.awsprofile` behavior and test coverage.
