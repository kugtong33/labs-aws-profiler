# Repository Guidelines

## Project Structure & Module Organization
- `awsprof` is the main Bash CLI script (single-file tool).
- `tests/` holds shell tests. Current files:
  - `tests/test_ini.sh` for INI parsing functions.
  - `tests/test_commands.sh` for command dispatch and end-to-end checks.
- `tests/fixtures/` contains mock credential files used by tests.
- `_bmad/` contains BMAD workflow definitions and agent templates.
- `_bmad-output/` stores planning and implementation artifacts (story docs, status files).

## Build, Test, and Development Commands
- `bash tests/test_ini.sh` — run unit tests for INI parsing helpers.
- `bash tests/test_commands.sh` — run command-level and perf checks (<100ms target).
- `./awsprof list` — run the CLI directly (reads `~/.aws/credentials` or `AWS_SHARED_CREDENTIALS_FILE`).

## Coding Style & Naming Conventions
- Language: Bash (bash 4.0+). Use `#!/usr/bin/env bash` and `set -euo pipefail` only for script execution (not when sourced).
- Functions follow the project namespace pattern: `awsprof_<module>_<action>`.
  - Command handlers use `awsprof_cmd_<command>` (e.g., `awsprof_cmd_list`).
- Output rules (per architecture):
  - User-facing messages/errors go to **stderr** via `awsprof_msg`/`awsprof_error`.
  - **stdout** must remain clean and parseable for eval-able output.

## Testing Guidelines
- Tests are plain Bash with simple assertions (no external framework).
- Name test scripts `test_*.sh` and keep fixtures in `tests/fixtures/`.
- Prefer using `AWS_SHARED_CREDENTIALS_FILE` in tests to avoid touching real credentials.

## Commit & Pull Request Guidelines
- Commit history uses conventional prefixes when applicable (`feat:`, `docs:`, `chore:`) and concise summaries.
  - Example: `feat: implement Story 1.1 - Script Foundation & INI Reading`.
- If opening a PR, include:
  - A short description of behavior changes.
  - Test commands run and their results.
  - Link to the story/epic doc in `_bmad-output/` when relevant.

## Security & Configuration Tips
- Do not print secrets. Credential input/output must never expose access keys.
- Prefer `AWS_SHARED_CREDENTIALS_FILE` and `AWS_CONFIG_FILE` for test isolation.
