# Story 5.4: Show Profile Config Summary

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want to view the region and output configured for a profile,
So that I can quickly confirm defaults without opening the file.

## Acceptance Criteria

1. **Given** the user runs `awsprof config show client-acme`  
   **When** the command executes  
   **Then** the current `region` and `output` are displayed if set (FR42)  
   **And** missing values are displayed as "not set"  
   **And** the command exits with status code 0

2. **Given** the user requests the default profile  
   **When** the command executes  
   **Then** values are read from `[default]` (FR42)

3. **Given** the config file is malformed  
   **When** the command executes  
   **Then** a clear error is displayed to stderr  
   **And** the command exits with status code 1

## Tasks / Subtasks

- [x] Task 1: Add `awsprof config show` command (AC: 1, 2, 3)
- [x] Task 2: Read config section and render region/output with defaults (AC: 1, 2)
- [x] Task 3: Error handling for malformed config (AC: 3)
- [x] Task 4: Tests for config show command (AC: 1, 2, 3)

## Dev Notes

- Epic 5 Story 5.4 acceptance criteria [Source: _bmad-output/planning-artifacts/epics.md#Story 5.4]
- Use config INI reader and stderr/stdout separation [Source: _bmad-output/planning-artifacts/architecture.md#Output Patterns]
- Source files: `awsprof`, `tests/test_commands.sh`

## Dev Agent Record

### Agent Model Used

GPT-5 (Codex CLI)

### Completion Notes List

- Added `awsprof_cmd_config_show` and dispatch in `awsprof_cmd_config`.
- Reads `[profile <name>]` or `[default]` and prints `region`/`output`.
- Handles missing values as `not set`.
- Added tests for success and malformed config.
- Now errors when profile section is missing in config.
- Trims inline comments in config values before display.

### File List

- awsprof
- tests/test_commands.sh

## Change Log

- 2026-02-04: Story created after implementation; aligned with Epic 5.
- 2026-02-04: Hardened config show behavior for missing sections and inline comments.
