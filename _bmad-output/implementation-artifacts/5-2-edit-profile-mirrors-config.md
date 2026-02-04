# Story 5.2: Edit Profile Mirrors Config

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want awsprof edit to update credentials and config defaults together,
So that profile changes stay in sync.

## Acceptance Criteria

1. **Given** the user runs `awsprof edit client-acme`  
   **When** prompts are completed for access key, secret key, region, and output  
   **Then** credentials are updated in `~/.aws/credentials` (FR2)  
   **And** `~/.aws/config` updates `[profile client-acme]` with provided region/output (FR40, FR41)  
   **And** existing config entries are preserved (FR43)

2. **Given** the user leaves region or output blank  
   **When** the edit command completes  
   **Then** the corresponding config key is removed or left unset for that profile

## Tasks / Subtasks

- [x] Task 1: Prompt for region/output on edit (AC: 1, 2)
- [x] Task 2: Mirror config defaults on edit (AC: 1)
- [x] Task 3: Preserve non-region/output config keys (AC: 1)
- [x] Task 4: Omit region/output when blank (AC: 2)
- [x] Task 5: Tests for edit + config mirroring (AC: 1, 2)

### Review Follow-ups (AI)

- [x] [AI-Review][Medium] Document non-story file changes (sprint status, epics) in a dedicated changelog entry for traceability.
- [x] [AI-Review][Low] Add explicit note about config backup behavior when the config file does not exist yet (backup only when present).

## Dev Notes

- Epic 5 Story 5.2 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 5.2]
- Config read/write uses awk-based INI helpers; preserve existing keys and use backups [Source: _bmad-output/planning-artifacts/architecture.md#File Handling]
- Use stderr for user messages; keep stdout clean (eval-only) [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- Source files: `awsprof`, `tests/test_commands.sh`
- Backups are only created when the config file already exists (no backup for a brand-new config file).

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex CLI)

### Completion Notes List

- Added region/output prompts in `awsprof_cmd_edit`.
- Mirrored config defaults via `awsprof_config_update_profile_section`.
- Preserved non-region/output keys; blank values remove keys.
- Tests updated for new inputs and config behavior.
- Added config rollback on credential-write failure for atomicity.
- Added config perms/backup assertions in tests.

### File List

- awsprof
- tests/test_commands.sh

## Change Log

- 2026-02-04: Story created after implementation; aligned with Epic 5.
- 2026-02-04: Documented non-story git changes and backup behavior note.
