---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - prd.md
  - product-brief-labs-aws-profiler-2026-01-22.md
workflowType: 'architecture'
project_name: 'labs-aws-profiler'
user_name: 'Ubuntu'
date: '2026-01-22'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
34 FRs across 8 capability areas:
- **Profile Management (FR1-6):** CRUD operations for AWS profiles in `~/.aws/credentials`
- **Profile Import (FR7-9):** Parse and import existing credential files
- **Profile Switching (FR10-13):** Set `AWS_PROFILE` environment variable
- **Current Profile Status (FR14-15):** Query and display active profile
- **Project-Profile Linking (FR16-22):** Detect `.awsprofile` files, warn on mismatch, prompt to switch
- **Shell Integration (FR23-26):** Provide shell scripts for bash/sh, enable directory change detection
- **Error Handling (FR27-31):** Exit codes, validation, clear error messages
- **Credential Security (FR32-34):** Hidden input, no secret display, direct file writes

**Non-Functional Requirements:**
17 NFRs driving architectural decisions:
- **Performance:** <100ms command response, no perceptible shell hook delay
- **Security:** Hidden credential input, no secret logging, proper file permissions (600)
- **Reliability:** Atomic file operations, backup before modify, graceful error handling
- **Integration:** Full AWS CLI credential file compatibility, bash 4.0+ and POSIX sh

### Scale & Complexity

- **Primary domain:** CLI/Shell tooling
- **Complexity level:** Low
- **Estimated architectural components:** 4-5 modules

| Complexity Factor | Assessment |
|-------------------|------------|
| Data persistence | File-based only (INI format) |
| Network | None |
| Concurrency | Single-user, single-process |
| UI | Terminal text output only |
| External dependencies | Minimal (standard library) |

### Technical Constraints & Dependencies

**Hard Constraints:**
- Cannot export environment variables from subprocess (shell limitation)
- Must use eval wrapper pattern: `eval "$(awsprof use profile)"`
- Must maintain exact AWS credential file format compatibility
- Must work with bash 4.0+ and POSIX sh

**File Dependencies:**
- `~/.aws/credentials` - INI format, contains access keys
- `~/.aws/config` - INI format, contains region/output settings
- `.awsprofile` - Single-line text file in project directories

### Cross-Cutting Concerns Identified

1. **INI File Handling:** Parsing and writing AWS credential format (used by multiple commands)
2. **Shell Integration:** Hook mechanism for directory change detection (affects `use` and linking features)
3. **Credential Security:** Hidden input and no-logging policy (affects `add`, `edit`, and all output)
4. **Atomic File Operations:** Backup-before-write pattern (affects all credential file modifications)
5. **Error Handling:** Consistent exit codes and messages (affects all commands)

## Starter Template Evaluation

### Primary Technology Domain

**CLI Tool / Shell Scripting** - Pure bash implementation

### Starter Options Considered

| Option | Pros | Cons |
|--------|------|------|
| Pure Bash | Native shell integration, no dependencies, fast startup, users have it | Limited ecosystem, manual argument parsing |
| bashly (bash CLI framework) | Generates argument parsing, help text | Added complexity, dependency |
| Python + Click/Typer | Rich CLI features, easy testing | Runtime dependency, slower startup |
| Go + Cobra | Single binary, fast, mature CLI tooling | Compilation step, different skill set |

### Selected Approach: Pure Bash

**Rationale:**
- **Native shell integration:** The eval wrapper pattern (`eval "$(awsprof use profile)"`) works naturally
- **Zero dependencies:** Works on any Linux system with bash 4.0+
- **Fast startup:** No interpreter initialization overhead, easily meets <100ms requirement
- **Target user alignment:** Infrastructure developers are comfortable with bash
- **Simplicity:** Single-purpose tool doesn't need framework overhead

### Project Structure

```
labs-aws-profiler/
├── awsprof                    # Main executable script
├── lib/
│   ├── credentials.sh         # INI file parsing/writing
│   ├── commands.sh            # Command implementations
│   └── utils.sh               # Shared utilities
├── shell/
│   ├── awsprof.bash           # Bash shell integration (eval wrapper + cd hook)
│   └── awsprof.sh             # POSIX sh shell integration
├── install.sh                 # Installation script
├── tests/
│   └── test_*.sh              # Test scripts
└── README.md
```

### Architectural Decisions Established

**Language & Runtime:**
- Bash 4.0+ (for associative arrays, better string handling)
- POSIX sh compatibility for shell hooks
- Shebang: `#!/usr/bin/env bash`

**Code Organization:**
- Main script sources library files
- Each command in separate function
- Shared utilities for common operations

**INI File Handling:**
- Pure bash parsing (no awk/sed dependency for portability)
- Or minimal awk for complex parsing if needed

**Argument Parsing:**
- Manual case/getopts pattern (simple enough for 7 commands)
- No framework needed

**Testing:**
- Shell-based tests using bats-core or simple assertions
- Test against mock credential files

**Installation:**
- Copy script to PATH
- Source shell integration in `.bashrc`/`.zshrc`

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- INI parsing strategy (awk-based)
- Script organization (embedded modules)
- Shell integration mechanism (PROMPT_COMMAND)

**Important Decisions (Shape Architecture):**
- Exit code strategy (simple 0/1)
- Installation method (curl | bash)

**Deferred Decisions (Post-MVP):**
- Shell completion
- JSON output format
- Multi-shell support beyond bash/sh

### File Handling

| Decision | Choice | Rationale |
|----------|--------|-----------|
| INI Parsing | awk-based | Fast, reliable, available everywhere, handles sections cleanly |
| INI Writing | awk for transforms | Preserve formatting, atomic updates |
| Backup Strategy | Copy before modify | Simple `.bak` file before any credential file changes |

**Implementation Pattern:**
```bash
# Read profile from credentials file
get_profile_credentials() {
    awk -F' *= *' -v profile="[$1]" '
        $0 == profile { found=1; next }
        /^\[/ { found=0 }
        found && /aws_access_key_id/ { print "KEY=" $2 }
        found && /aws_secret_access_key/ { print "SECRET=" $2 }
    ' ~/.aws/credentials
}
```

### Script Organization

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Structure | Single file, embedded modules | Easy distribution, one file to install |
| Section markers | Comment blocks | Clear separation: `#=== SECTION ===` |
| Function naming | `awsprof_<module>_<action>` | Namespace to avoid conflicts |

**Script Layout:**
```bash
#!/usr/bin/env bash
#=== CONFIGURATION ===
#=== INI HANDLING ===
#=== PROFILE COMMANDS ===
#=== SHELL INTEGRATION ===
#=== MAIN DISPATCH ===
```

### Shell Integration

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Hook mechanism | PROMPT_COMMAND | Catches all directory changes, standard bash pattern |
| POSIX sh fallback | Manual check only | No PROMPT_COMMAND equivalent, user runs `awsprof check` |
| Hook behavior | Warn only, prompt to switch | Non-intrusive per requirements |

**Implementation Pattern:**
```bash
_awsprof_check() {
    [[ -f .awsprofile ]] || return
    local expected=$(<.awsprofile)
    local current=${AWS_PROFILE:-default}
    [[ "$expected" == "$current" ]] && return
    echo "⚠️  Profile mismatch: current '$current', project expects '$expected'"
    read -p "    Switch profile? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && eval "$(awsprof use "$expected")"
}
PROMPT_COMMAND="_awsprof_check${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
```

### Error Handling

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Exit codes | Simple (0/1) | 0 = success, 1 = any error |
| Error output | stderr | Keep stdout clean for eval |
| Message format | `Error: <message>` | Clear, consistent prefix |

### Installation & Distribution

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Distribution | curl \| bash one-liner | Simple, standard for dev tools |
| Install location | ~/.local/bin/awsprof | User-local, no sudo required |
| Shell setup | Append to ~/.bashrc | Add source line for shell integration |

**Installation Command:**
```bash
curl -fsSL https://raw.githubusercontent.com/kugtong33/labs-aws-profiler/refs/tags/0.1.1/install.sh | bash
```

### Decision Impact Analysis

**Implementation Sequence:**
1. Core INI handling (awk functions)
2. Profile CRUD commands
3. Shell integration script generation
4. Main dispatch and argument parsing
5. Installation script

**Cross-Component Dependencies:**
- All commands depend on INI handling module
- `use` command must output eval-able shell code
- Shell integration depends on `use` command format

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Conflict Points Addressed:**
5 areas where implementation could vary without clear patterns

### Naming Patterns

**Function Naming:**
- Pattern: Prefixed snake_case
- Format: `awsprof_<module>_<action>`
- Examples:
  - `awsprof_profile_add`
  - `awsprof_profile_list`
  - `awsprof_ini_read_section`
  - `awsprof_shell_check_directory`

**Variable Naming:**
- User-configurable globals: `AWSPROF_*` (e.g., `AWSPROF_EMOJI`)
- Internal globals: `_awsprof_*` (e.g., `_awsprof_credentials_path`)
- Function locals: Always use `local` keyword, snake_case
- Examples:
  ```bash
  AWSPROF_EMOJI="${AWSPROF_EMOJI:-0}"      # User config
  _awsprof_version="1.0.0"                  # Internal
  local profile_name="$1"                   # Local
  ```

### Output Patterns

**Message Formatting:**
- Default: Plain text (no emojis)
- Optional: `--emoji` flag or `AWSPROF_EMOJI=1` enables symbols
- All user messages to stderr (keeps stdout clean for eval)

| Type | Plain (default) | With Emoji |
|------|-----------------|------------|
| Success | `Switched to profile: foo` | `✓ Switched to profile: foo` |
| Warning | `Warning: Profile mismatch` | `⚠️ Profile mismatch` |
| Error | `Error: Profile not found` | `✗ Profile not found` |
| Info | `Found 5 profiles` | `→ Found 5 profiles` |

**Output Functions:**
```bash
awsprof_msg() { echo "$*" >&2; }
awsprof_warn() { awsprof_msg "Warning: $*"; }
awsprof_error() { awsprof_msg "Error: $*"; }
awsprof_success() { awsprof_msg "$*"; }
```

### Eval Output Pattern

**Stdout (for eval):**
- Only executable shell code
- No messages, no comments
- Single export statement

**Stderr (for user):**
- Success/error messages
- Warnings and prompts

**Example:**
```bash
# awsprof use foo
# stdout: export AWS_PROFILE=foo
# stderr: Switched to profile: foo

awsprof_cmd_use() {
    local profile="$1"
    # Validate profile exists...
    echo "export AWS_PROFILE=$profile"      # stdout for eval
    awsprof_success "Switched to profile: $profile"  # stderr for user
}
```

### File Handling Patterns

**Backup Strategy:**
- Pattern: Timestamped backups
- Format: `credentials.bak.YYYYMMDD-HHMMSS`
- Location: Same directory as original
- Example: `~/.aws/credentials.bak.20260122-143052`

**Backup Function:**
```bash
awsprof_backup_credentials() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cp ~/.aws/credentials ~/.aws/credentials.bak.$timestamp
}
```

**Atomic Write Pattern:**
```bash
awsprof_write_credentials() {
    local temp_file=$(mktemp)
    # Write to temp file...
    awsprof_backup_credentials
    mv "$temp_file" ~/.aws/credentials
    chmod 600 ~/.aws/credentials
}
```

### Enforcement Guidelines

**All Implementation MUST:**
- Use `awsprof_` prefix for all functions
- Use `local` for all function variables
- Send user messages to stderr
- Send eval code to stdout only
- Create timestamped backup before any credential file modification
- Use `chmod 600` on credential files after writing

**Anti-Patterns to Avoid:**
- `echo "Switched"` (stdout pollutes eval)
- `profile_name=foo` (missing local)
- `add_profile()` (missing prefix)
- Modifying credentials without backup

## Project Structure & Boundaries

### Complete Project Directory Structure

```
labs-aws-profiler/
├── awsprof                     # Main executable (single file, embedded modules)
├── install.sh                  # curl | bash installer
├── tests/
│   ├── test_runner.sh          # Test harness
│   ├── test_ini.sh             # INI parsing tests
│   ├── test_commands.sh        # Command tests
│   ├── test_integration.sh     # End-to-end tests
│   └── fixtures/
│       ├── credentials.mock    # Mock credentials file
│       └── config.mock         # Mock config file
├── .github/
│   └── workflows/
│       └── test.yml            # CI pipeline
├── LICENSE
└── README.md
```

### Main Script Structure (awsprof)

The single `awsprof` file contains embedded modules:

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
# awsprof_ini_write_section
# awsprof_ini_delete_section

#=== FILE OPERATIONS ===
# awsprof_backup_credentials
# awsprof_write_credentials

#=== PROFILE COMMANDS ===
# awsprof_cmd_add
# awsprof_cmd_edit
# awsprof_cmd_remove
# awsprof_cmd_list
# awsprof_cmd_import
# awsprof_cmd_use
# awsprof_cmd_whoami

#=== SHELL INTEGRATION ===
# awsprof_cmd_init (outputs shell code for sourcing)

#=== MAIN DISPATCH ===
# case "$1" in add|edit|remove|list|import|use|whoami|init|help) ...
```

### Architectural Boundaries

**Command Boundary:**
Each command is a self-contained function that:
- Receives arguments from main dispatch
- Uses shared INI and output utilities
- Returns exit code 0 or 1
- Outputs eval code to stdout (for `use` only)
- Outputs messages to stderr

**File Boundary:**
```
User's System                    awsprof
─────────────────────────────────────────────────
~/.aws/credentials    <──────>  awsprof_ini_* functions
~/.aws/config         <──────>  awsprof_ini_* functions
.awsprofile           <──────>  _awsprof_check (PROMPT_COMMAND)
~/.bashrc             <──────>  install.sh (adds source line)
```

**Eval Boundary:**
```
┌─────────────────────────────────────────────────┐
│ User's Shell                                     │
│   ┌───────────────────────────────────────────┐ │
│   │ eval "$(awsprof use profile)"             │ │
│   │                                           │ │
│   │   stdout: export AWS_PROFILE=profile      │ │
│   │   stderr: Switched to profile: profile    │ │
│   └───────────────────────────────────────────┘ │
│   AWS_PROFILE is now set in current shell       │
└─────────────────────────────────────────────────┘
```

### Requirements to Structure Mapping

| FR Category | Location in awsprof |
|-------------|---------------------|
| Profile Management (FR1-6) | `#=== PROFILE COMMANDS ===` |
| Profile Import (FR7-9) | `awsprof_cmd_import` |
| Profile Switching (FR10-13) | `awsprof_cmd_use` |
| Current Profile (FR14-15) | `awsprof_cmd_whoami` |
| Project Linking (FR16-22) | `#=== SHELL INTEGRATION ===` |
| Shell Integration (FR23-26) | `awsprof_cmd_init` + PROMPT_COMMAND |
| Error Handling (FR27-31) | `#=== OUTPUT UTILITIES ===` |
| Credential Security (FR32-34) | `awsprof_cmd_add`, `awsprof_cmd_edit` |

### Installation Structure

**install.sh responsibilities:**
1. Download `awsprof` to `~/.local/bin/`
2. Make executable (`chmod +x`)
3. Add shell integration to `~/.bashrc`:
   ```bash
   # awsprof shell integration
   eval "$(awsprof init)"
   ```
4. Verify installation

**Installed files:**
```
~/.local/bin/awsprof           # Main script
~/.bashrc                       # Modified (adds eval line)
```

### Test Organization

| Test File | Coverage |
|-----------|----------|
| test_ini.sh | INI parsing: read, write, delete sections |
| test_commands.sh | Each command in isolation |
| test_integration.sh | Full workflows with mock files |
| fixtures/*.mock | Sample credentials/config for testing |

### Development Workflow

**Local development:**
```bash
# Make changes to awsprof
./tests/test_runner.sh          # Run all tests
source awsprof init             # Test shell integration
```

**CI pipeline (.github/workflows/test.yml):**
1. Checkout code
2. Run shellcheck on awsprof
3. Run test suite
4. Test installation script
