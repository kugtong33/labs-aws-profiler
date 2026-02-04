# Story 5.3: Remove Profile Mirrors Config

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want awsprof remove to delete config defaults for the same profile,
So that no stale config remains after profile removal.

## Acceptance Criteria

1. **Given** the user runs `awsprof remove client-acme`  
   **When** the command completes  
   **Then** the profile is removed from `~/.aws/credentials` (FR3)  
   **And** the corresponding `[profile client-acme]` section is removed from `~/.aws/config` (FR43)  
   **And** other config profiles remain unchanged (FR43)

## Tasks / Subtasks

- [x] Task 1: Remove config section on profile removal (AC: 1)
- [x] Task 2: Preserve other config entries (AC: 1)
- [x] Task 3: Tests for remove + config mirroring (AC: 1)

### Review Follow-ups (AI)

- [x] [AI-Review][High] Make remove flow atomic: delete config first, rollback if credentials delete fails.
- [x] [AI-Review][Medium] Add tests for config backup + chmod 600 on remove.
- [x] [AI-Review][Medium] Document non-story file changes in a dedicated changelog entry for traceability.

## Dev Notes

- Epic 5 Story 5.3 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 5.3]
- Config deletion uses awk-based INI helpers with backups [Source: _bmad-output/planning-artifacts/architecture.md#File Handling]
- Use stderr for user messages; keep stdout clean [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- Source files: `awsprof`, `tests/test_commands.sh`

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex CLI)

### Completion Notes List

- Added config section delete on `awsprof_cmd_remove`.
- Ensured config file uses backups and atomic writes.
- Tests updated for config section removal.
- Made remove flow atomic with config rollback on credential delete failure.
- Added config backup/perms assertions to remove tests.

### File List

- awsprof
- tests/test_commands.sh

## Change Log

- 2026-02-04: Story created after implementation; aligned with Epic 5.
- 2026-02-04: Hardened atomic remove and expanded config removal tests.
