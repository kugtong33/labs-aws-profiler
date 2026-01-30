# Story 4.2: Global .awsprofile Fallback

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want a global `~/.aws/.awsprofile` to define my default profile when no project file exists,
so that I get automatic profile selection even outside project directories.

## Acceptance Criteria

1. **Given** no project `.awsprofile` exists in the current directory  
   **When** the shell hook runs and a global `~/.aws/.awsprofile` exists  
   **Then** `AWS_PROFILE` is set to the global profile  
   **And** no mismatch prompt is shown
2. **Given** both a project `.awsprofile` and a global `~/.aws/.awsprofile` exist  
   **When** the hook runs  
   **Then** the project file takes precedence  
   **And** the global profile is not applied
3. **Given** neither a project `.awsprofile` nor a global `~/.aws/.awsprofile` exists  
   **When** the hook runs  
   **Then** no profile is applied and no output is produced

## Tasks / Subtasks

- [x] Task 1: Global fallback resolution (AC: 1, 2, 3)
  - [x] Subtask 1.1: Add helper to resolve project `.awsprofile` first, then global `~/.aws/.awsprofile`
  - [x] Subtask 1.2: Ensure project file takes precedence over global
  - [x] Subtask 1.3: Keep missing files silent (no output)
- [x] Task 2: Hook behavior updates (AC: 1, 2, 3)
  - [x] Subtask 2.1: Update hook to use new resolution helper
  - [x] Subtask 2.2: Preserve eval-only stdout and stderr separation
- [x] Task 3: Tests for global fallback (AC: 1, 2, 3)
  - [x] Subtask 3.1: Add tests for global fallback when no project file exists
  - [x] Subtask 3.2: Add tests for project precedence over global
  - [x] Subtask 3.3: Add test for no files (silent)

## Dev Notes

- Architecture: single-file `awsprof` script, bash 4.0+, POSIX sh support for init; use `awsprof_<module>_<action>` naming [Source: _bmad-output/planning-artifacts/architecture.md#Script Organization]
- Output rules: user messages to stderr; eval-only export to stdout (for `use` and hook behavior) [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- INI parsing is awk-based; use `awsprof_ini_list_sections` to validate profile existence [Source: _bmad-output/planning-artifacts/architecture.md#File Handling]
- Hook entry: `awsprof_hook_detect_profile` and init output in `awsprof_cmd_init`; hook should be fast and safe [Source: _bmad-output/planning-artifacts/architecture.md#Shell Integration]
- Global fallback is new behavior; avoid any mismatch warning for valid profiles [Source: _bmad-output/planning-artifacts/epics.md#Story 4.2]
- Source files to touch: `awsprof` (profile resolution + hook), `tests/test_commands.sh` (new tests)
- Keep stdout eval-only: hook should emit export command to stdout and any warnings to stderr for eval safety

### Developer Context

- Resolution order: project `.awsprofile` (current dir) first, then global `~/.aws/.awsprofile`.
- When no `.awsprofile` exists, hook is silent.
- Reuse existing whitespace trimming helper for both project and global.

### Technical Requirements

- Add a helper to resolve expected profile based on project/global rules.
- If resolved profile is valid, output `export AWS_PROFILE=<name>` to stdout (no prompts).
- Do not implement invalid-profile warning/clearing here (Story 4.4).

### Architecture Compliance

- Maintain single-file layout in `awsprof`.
- Use existing INI helpers (`awsprof_ini_list_sections`) and utility (`awsprof_util_read_awsprofile`).
- Preserve stderr/stdout separation (stderr for user messages, stdout for eval-only).

### Library / Framework Requirements

- Bash 4.0+ only; no new dependencies.

### File Structure Requirements

- Update `awsprof` hook and helper functions only; avoid new files unless tests require fixtures.
- Tests should live in `tests/test_commands.sh` using existing fixture patterns.

### Testing Requirements

- Add tests for global fallback and precedence (project beats global).
- Add test confirming no output when both files missing.

### Project Structure Notes

- Single-file CLI: all changes go in `awsprof`, under utility/shell integration sections.
- Tests live in `tests/`; use `AWS_SHARED_CREDENTIALS_FILE` with fixtures in `tests/fixtures/`.

### References

- Epic 4 Story 4.2 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 4.2]
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

- Added global `.awsprofile` fallback with project precedence and silent no-file behavior.
- Added tests for global fallback and precedence; all command tests pass.
### File List

- awsprof
- tests/test_commands.sh

## Change Log

- 2026-01-30: Added global .awsprofile fallback and tests.
