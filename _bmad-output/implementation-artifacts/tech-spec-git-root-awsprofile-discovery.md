---
title: 'Git-root .awsprofile discovery'
slug: 'git-root-awsprofile-discovery'
created: '2026-02-04T16:14:24+08:00'
status: 'ready-for-dev'
stepsCompleted: [1, 2, 3, 4]
tech_stack: ['bash']
files_to_modify: ['awsprof', 'tests/test_commands.sh']
code_patterns: ['awsprof_util_read_awsprofile_path', 'awsprof_util_read_awsprofile', 'awsprof_util_read_global_awsprofile', 'awsprof_hook_detect_profile', 'awsprof_cmd_check', 'tests/test_commands.sh assertions']
test_patterns: ['bash tests/test_commands.sh', 'AWS_SHARED_CREDENTIALS_FILE for isolation', 'temp dirs via mktemp; cwd changes via cd']
---

# Tech-Spec: Git-root .awsprofile discovery

**Created:** 2026-02-04T16:14:24+08:00

## Overview

### Problem Statement

The tool only reads `./.awsprofile` from the current directory. When invoked from subdirectories, it fails to discover the project profile and silently falls back to the global profile, risking wrong AWS account usage.

### Solution

If inside a git repo, search upward from `$PWD` to the repo root for the nearest `.awsprofile` and use the first match. If no project `.awsprofile` is found in the repo, fall back to `~/.aws/.awsprofile`. If not in a git repo, use only the global `~/.aws/.awsprofile`.

### Scope

**In Scope:**
- Update `.awsprofile` discovery to search upward within git repo boundaries.
- Preserve global fallback when no project `.awsprofile` is found.
- Update tests to cover new discovery semantics.

**Out of Scope:**
- Environment variable overrides for profile file.
- Searching beyond git root or into parent directories outside repo.
- Changes to profile file format or credential parsing.

## Context for Development

### Codebase Patterns

- `.awsprofile` parsing is centralized in `awsprof_util_read_awsprofile_path` and its wrappers.
- `awsprof_util_read_awsprofile()` reads only `./.awsprofile` (current working directory).
- `awsprof_hook_detect_profile()` uses `awsprof_util_read_awsprofile()` then falls back to `awsprof_util_read_global_awsprofile()` if empty.
- `awsprof_cmd_check()` prints the current-directory `.awsprofile` value to stdout (used by tests and shell integration).
- Tests are bash scripts with inline assertions; temp dirs and `cd` are used to simulate contexts.

### Files to Reference

| File | Purpose |
| ---- | ------- |
| awsprof | Utility functions and command handlers. |
| tests/test_commands.sh | Behavioral tests for .awsprofile and hook detection. |

### Technical Decisions

- Use git root as the upper search boundary when in a git repo.
- When not in a git repo, skip upward search and use global `.awsprofile` only.
- Update tests that currently assert “current directory only” behavior.

## Implementation Plan

### Tasks

- [ ] Task 1: Add git-root discovery helper for `.awsprofile`
  - File: `awsprof`
  - Action: Introduce a utility to resolve git root (e.g., `git rev-parse --show-toplevel`), and walk upward from `$PWD` to that root to find the nearest `.awsprofile`.
  - Notes: If git root cannot be determined or git is unavailable, skip upward search and treat as non-git.

- [ ] Task 2: Update `.awsprofile` resolution to use git-root search
  - File: `awsprof`
  - Action: Update `awsprof_util_read_awsprofile()` to return the nearest `.awsprofile` within repo boundary when in git; otherwise return empty (so global fallback can apply).
  - Notes: Keep `awsprof_util_read_awsprofile_path` behavior unchanged; preserve stdout/stderr conventions.

- [ ] Task 3: Update tests to reflect new discovery behavior
  - File: `tests/test_commands.sh`
  - Action: Replace Test 101 (“current directory only”) with tests that verify:
    - In a git repo, `.awsprofile` in repo root is discovered from a subdir.
    - In a git repo, nearest `.awsprofile` wins when multiple exist.
    - In a non-git directory, no upward search occurs (global fallback used only when set).
  - Notes: Use temp dirs + `git init` to create minimal repos; clean up after.

### Acceptance Criteria

- [ ] AC1: Given a git repo with `.awsprofile` in the repo root, when `awsprof check` is run from a nested subdirectory, then it returns the root `.awsprofile` value.
- [ ] AC2: Given a git repo with `.awsprofile` in both root and a closer parent directory, when `awsprof check` is run from a deeper subdirectory, then it returns the nearest `.awsprofile` up the tree.
- [ ] AC3: Given a non-git directory with no `.awsprofile`, when `--hook-detect-profile` runs and a global `~/.aws/.awsprofile` exists, then it uses the global profile; otherwise it is silent.
- [ ] AC4: Given a non-git directory with a `.awsprofile` in a parent directory outside any git repo, when `awsprof check` is run, then it does not discover that parent `.awsprofile`.

## Additional Context

### Dependencies

- `git` must be available for git-root detection (fallback behavior if not).

### Testing Strategy

- Update `tests/test_commands.sh` with git repo setup via `git init` and multiple `.awsprofile` placements.
- Use `AWS_SHARED_CREDENTIALS_FILE` mock in hook tests to avoid touching real creds.
- Run `bash tests/test_commands.sh` after changes.

### Notes

- Risk: assuming `git` availability; handle failure gracefully by treating as non-git.
- Keep stdout clean and parseable; warnings (if any) must go to stderr.
