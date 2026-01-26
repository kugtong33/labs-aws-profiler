# Story 1.1: Script Foundation & INI Reading

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As an infrastructure developer,
I want a basic awsprof script that can read AWS credential files,
So that I have the foundation for all profile management operations.

## Acceptance Criteria

### AC1: Read profiles from valid credentials file

**Given** the user has a `~/.aws/credentials` file with one or more profiles
**When** the script's INI parsing functions are called
**Then** the script correctly extracts profile names and their key-value pairs
**And** the script handles both profile sections and key-value pairs within sections
**And** the script uses awk-based parsing for reliability

### AC2: Handle missing credentials file gracefully

**Given** the credentials file does not exist
**When** the script attempts to read profiles
**Then** the script handles the missing file gracefully without crashing
**And** returns appropriate error messaging

### AC3: Handle malformed INI syntax

**Given** the credentials file has malformed INI syntax
**When** the script attempts to parse it
**Then** the script handles parsing errors without data loss
**And** provides clear error messages to stderr

## Tasks / Subtasks

- [x] Create main `awsprof` executable script structure (AC: #1, #2, #3)
  - [x] Add shebang: `#!/usr/bin/env bash`
  - [x] Add version and configuration section
  - [x] Add embedded module comment sections
  - [x] Create main dispatch case statement skeleton

- [x] Implement output utility functions (AC: #2, #3)
  - [x] `awsprof_msg()` - stderr output helper
  - [x] `awsprof_error()` - error message formatter
  - [x] `awsprof_warn()` - warning message formatter
  - [x] `awsprof_success()` - success message formatter

- [x] Implement INI reading functions (AC: #1, #2, #3)
  - [x] `awsprof_ini_list_sections()` - list all [profile] sections using awk
  - [x] `awsprof_ini_read_section()` - read key-value pairs from a section using awk
  - [x] Add file existence check before reading
  - [x] Add error handling for malformed INI syntax

- [x] Create test fixtures for INI parsing (AC: #1, #2, #3)
  - [x] Create `tests/fixtures/credentials.mock` with valid multi-profile data
  - [x] Create `tests/fixtures/credentials_malformed.mock` with syntax errors
  - [x] Create test runner script structure

- [x] Write unit tests for INI functions (AC: #1, #2, #3)
  - [x] Test `awsprof_ini_list_sections()` with valid file
  - [x] Test `awsprof_ini_read_section()` with valid profile
  - [x] Test error handling for missing file
  - [x] Test error handling for malformed syntax

## Dev Notes

### Architecture Requirements

**From Architecture Document** [Source: _bmad-output/planning-artifacts/architecture.md]

**Critical Implementation Rules:**

1. **Single File Structure** (#=== SECTION === markers)
   - All code in single `awsprof` executable
   - Embedded modules with comment section headers
   - No separate library files - everything embedded

2. **INI Parsing Strategy** (awk-based)
   - Use awk for reliable, fast parsing
   - Pattern from architecture:
     ```bash
     get_profile_credentials() {
         awk -F' *= *' -v profile="[$1]" '
             $0 == profile { found=1; next }
             /^\[/ { found=0 }
             found && /aws_access_key_id/ { print "KEY=" $2 }
             found && /aws_secret_access_key/ { print "SECRET=" $2 }
         ' ~/.aws/credentials
     }
     ```

3. **Function Naming Convention**
   - **MANDATORY:** `awsprof_<module>_<action>` format
   - Examples: `awsprof_ini_list_sections`, `awsprof_msg`
   - ALL functions MUST use `awsprof_` prefix

4. **Variable Naming**
   - User-configurable globals: `AWSPROF_*` (e.g., `AWSPROF_EMOJI`)
   - Internal globals: `_awsprof_*` (e.g., `_awsprof_version`)
   - Function locals: ALWAYS use `local` keyword, snake_case

5. **Output Separation** (CRITICAL for eval pattern)
   - **stdout:** ONLY for eval-able shell code (not used in Story 1.1)
   - **stderr:** ALL user messages, errors, warnings
   - Use utility functions: `awsprof_msg()`, `awsprof_error()`, etc.

6. **Exit Codes**
   - 0: Success (FR27)
   - 1: Any error (FR28)

### Technical Requirements

**File Paths:**
- Credentials: `~/.aws/credentials` (or `$AWS_SHARED_CREDENTIALS_FILE`)
- Config: `~/.aws/config` (or `$AWS_CONFIG_FILE`)

**Bash Version:**
- Require bash 4.0+ for associative arrays (NFR17)
- Shebang: `#!/usr/bin/env bash`

**INI Format (AWS Standard):**
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[profile-name]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE2
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY2
```

### Script Structure Template

**Expected Layout:**
```bash
#!/usr/bin/env bash
#
# awsprof - AWS Profile Manager
# https://github.com/kugtong33/labs-aws-profiler
#

#=== CONFIGURATION ===
_awsprof_version="1.0.0"
_awsprof_credentials="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"
_awsprof_config="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
AWSPROF_EMOJI="${AWSPROF_EMOJI:-0}"

#=== OUTPUT UTILITIES ===
# awsprof_msg, awsprof_error, awsprof_warn, awsprof_success

#=== INI HANDLING ===
# awsprof_ini_list_sections
# awsprof_ini_read_section

#=== MAIN DISPATCH ===
# case "$1" in ...)
```

### File Structure to Create

```
labs-aws-profiler/
├── awsprof                     # THIS STORY: Main executable (foundation)
└── tests/
    ├── test_ini.sh             # THIS STORY: INI parsing tests
    └── fixtures/
        ├── credentials.mock    # THIS STORY: Valid test data
        └── credentials_malformed.mock  # THIS STORY: Error test data
```

### Testing Standards

**Test Framework:** Simple bash assertions (no external framework for Story 1.1)

**Test Pattern:**
```bash
#!/usr/bin/env bash
# tests/test_ini.sh

source ./awsprof

test_list_sections() {
    local result=$(awsprof_ini_list_sections tests/fixtures/credentials.mock)
    [[ "$result" == *"default"* ]] || { echo "FAIL: Missing default"; exit 1; }
    echo "PASS: test_list_sections"
}

test_list_sections
```

### Implementation Sequence

1. **Start with script skeleton**
   - Shebang, version, configuration section
   - Comment section markers

2. **Add output utilities**
   - Simple stderr output helpers
   - These are needed by all other functions

3. **Implement INI reading**
   - `awsprof_ini_list_sections` first (simpler)
   - Then `awsprof_ini_read_section`
   - Add file existence checks
   - Add error handling

4. **Create test infrastructure**
   - Mock credential files
   - Simple test script

5. **Run tests to verify**
   - Test each function in isolation
   - Verify error handling

### Project Context Notes

**Project Status:** Greenfield - no code exists yet
- This is the first story being implemented
- Creates the foundation for all future stories
- No previous code patterns to follow - establishing them here

**Dependencies:** None - this story has no dependencies on other stories

**Blockers:** None - greenfield start

### References

- [Source: _bmad-output/planning-artifacts/architecture.md#Script Organization]
- [Source: _bmad-output/planning-artifacts/architecture.md#INI File Handling]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation Patterns & Consistency Rules]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 1: Profile Switching & Status]
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.1: Script Foundation & INI Reading]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 4.5 (claude-sonnet-4-5-20250929)

### Debug Log References

No issues encountered during implementation.

### Completion Notes List

✅ Created foundational `awsprof` script with embedded module structure
✅ Implemented output utility functions (awsprof_msg, awsprof_error, awsprof_warn, awsprof_success)
✅ Implemented awk-based INI parsing functions (awsprof_ini_list_sections, awsprof_ini_read_section)
✅ Added file existence checking and error handling for missing/malformed files
✅ Created test fixtures with valid and malformed credential files
✅ Implemented comprehensive test suite with 8 unit tests
✅ All tests pass (8/8) - verified AC1, AC2, AC3
✅ Code review fixes: added malformed INI detection + stderr errors, updated tests, added test runner

**Technical Decisions:**
- Used conditional `set -euo pipefail` to allow script sourcing for tests
- Implemented robust awk parsing with field separator handling and multi-value support
- Added graceful error handling for missing files and malformed syntax
- Followed architecture patterns: function naming convention, output separation, exit codes

### File List

- awsprof (modified) - INI parsing now validates malformed headers/lines
- tests/test_ini.sh (modified) - Added malformed INI error assertions
- tests/test_runner.sh (created) - Simple test harness
- tests/fixtures/credentials.mock (created) - Valid multi-profile test data
- tests/fixtures/credentials_malformed.mock (created) - Malformed INI test data
