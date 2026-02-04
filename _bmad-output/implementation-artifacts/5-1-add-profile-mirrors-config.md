# Story 5.1: Add Profile Mirrors Config

Status: done

**Code Review Status:** ✅ REVIEWED - Fixes applied for atomicity/dir creation; follow-ups logged

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want awsprof add to write both credentials and config defaults together,
So that profile creation is complete and consistent.

## Acceptance Criteria

### AC1: Add writes credentials and config defaults

**Given** the user runs `awsprof add client-acme`
**When** prompts are completed for access key, secret key, region, and output
**Then** `~/.aws/credentials` contains the new profile (FR1)
**And** `~/.aws/config` contains `[profile client-acme]` with `region`/`output` if provided (FR40, FR41)
**And** existing config entries are preserved (FR43)

### AC2: Blank region/output omitted

**Given** the user leaves region or output blank
**When** the add command completes
**Then** the corresponding config key is omitted (FR40, FR41)

### AC3: File safety and permissions

**Given** the add command writes credentials/config
**When** files are written
**Then** backups are created for both files
**And** chmod 600 is enforced (NFR8)
**And** writes are atomic

## Tasks / Subtasks

- [x] Extend `awsprof_cmd_add()` to prompt for region/output (AC: #1, #2)
- [x] Write region/output to `~/.aws/config` under `[profile <name>]` (AC: #1)
- [x] Preserve existing config entries and non-region/output keys (AC: #1)
- [x] Omit region/output keys when blank (AC: #2)
- [x] Ensure config writes use backups + chmod 600 (AC: #3)
- [x] Add/adjust tests for config writes and blank behavior (AC: #1, #2, #3)

### Review Follow-ups (AI)

- [x] [AI-Review][Medium] Document git discrepancies for non-story files changed during Epic 5 implementation (sprint status, epics) in a dedicated changelog section for traceability.
- [x] [AI-Review][Low] Add explicit note in story about config backup behavior when config file does not exist (backup only created if file exists).

## Implementation Notes (Double-Check)

- `awsprof_cmd_add` now prompts for `region` and `output` and validates output format.
- `awsprof_config_update_profile_section`:
  - Preserves existing config keys except `region`/`output`.
  - Writes `[profile <name>]` (or `default`) with provided values.
  - Removes `region`/`output` when blank, leaving other keys intact.
  - Uses same atomic write + backup path as credentials.
- New tests validate:
  - Config section creation with region/output.
  - Preservation of unrelated config keys.
  - Blank region/output omission.
  - Backups and chmod 600 behavior.

## Dev Notes

- Output validation allows: `json`, `text`, `table`, `yaml`, `yaml-stream`.
- Config writes are optional when values are blank; if no section existed, no config file is created.
- Backups are only created when the config file already exists (no backup for a brand-new config file).
- Tests: `bash tests/test_commands.sh` includes Epic 5 config cases.

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex CLI)

### Completion Notes List

- Ensured config directory exists before temp file creation.
- Reordered add flow to write config first; rollback config on credentials write failure.
- Added config file permission assertion in tests.

### File List

- awsprof
- tests/test_commands.sh

### Tests

- `bash tests/test_commands.sh`

## Change Log

- 2026-02-04: Documented non-story git changes and backup behavior note.
