---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics]
inputDocuments:
  - prd.md
  - architecture.md
---

# labs-aws-profiler - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for labs-aws-profiler, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

**Profile Management**
- FR1: User can add a new AWS profile by providing a name, access key ID, and secret access key
- FR2: User can edit an existing profile's credentials (access key ID and secret access key)
- FR3: User can remove an existing profile from the system
- FR4: User can view a list of all configured AWS profiles
- FR5: System stores profile credentials in standard `~/.aws/credentials` format
- FR6: System preserves existing profiles when adding or editing (no data loss)

**Profile Import**
- FR7: User can import all existing profiles from `~/.aws/credentials` file
- FR8: System detects and lists all profiles found during import
- FR9: System preserves original credential file structure during import

**Profile Switching**
- FR10: User can switch to any configured profile by name
- FR11: System sets `AWS_PROFILE` environment variable when switching profiles
- FR12: System confirms successful profile switch with feedback message
- FR13: System reports error when user attempts to switch to non-existent profile

**Current Profile Status**
- FR14: User can query the currently active profile
- FR15: System displays the current `AWS_PROFILE` value (or indicates none set)

**Project-Profile Linking**
- FR16: User can create a `.awsprofile` file in a project directory containing a profile name
- FR17: System detects `.awsprofile` file when user enters a directory
- FR18: System compares current profile against project's expected profile
- FR19: System displays warning when current profile differs from project's expected profile
- FR20: System prompts user to switch profiles when mismatch is detected
- FR21: User can accept or decline the profile switch prompt
- FR22: System remains silent when current profile matches project expectation

**Shell Integration**
- FR23: System provides shell initialization script for bash
- FR24: System provides shell initialization script for sh
- FR25: Shell integration enables automatic `.awsprofile` detection on directory change
- FR26: System outputs commands suitable for shell eval (enabling env var export)

**Error Handling**
- FR27: System exits with status code 0 on successful operations
- FR28: System exits with non-zero status code on failures
- FR29: System displays clear error messages for invalid operations
- FR30: System validates profile name exists before switching
- FR31: System validates credential format before saving

**Credential Security**
- FR32: System prompts for credentials with hidden input (no terminal echo)
- FR33: System never displays secret access keys in output
- FR34: System writes credentials directly to file (no intermediate storage)

### NonFunctional Requirements

**Performance**
- NFR1: All commands complete within 100ms under normal operation
- NFR2: Profile listing displays immediately regardless of number of profiles (up to 100+)
- NFR3: Shell hook detection adds no perceptible delay to directory changes
- NFR4: Credential file read/write operations complete atomically

**Security**
- NFR5: Credential input is hidden (no terminal echo during password/secret entry)
- NFR6: Secret access keys are never displayed in command output
- NFR7: Secret access keys are never written to log files or command history
- NFR8: Credential files maintain standard AWS permission model (user-only read/write)
- NFR9: No credentials transmitted over network (local file operations only)

**Reliability**
- NFR10: Credential file operations are atomic (no partial writes on failure)
- NFR11: System creates backup before modifying existing credential files
- NFR12: System gracefully handles malformed credential files without data loss
- NFR13: Shell integration failures do not break normal shell operation

**Integration**
- NFR14: Full compatibility with AWS CLI credential file format (INI)
- NFR15: Full compatibility with AWS CLI config file format
- NFR16: Profile switching works with all tools that respect `AWS_PROFILE` env var
- NFR17: Shell integration works with bash 4.0+ and POSIX sh

### Additional Requirements

**From Architecture - Technical Implementation:**
- Pure Bash implementation (bash 4.0+ required, POSIX sh for hooks)
- Single file distribution with embedded modules (no separate library files)
- awk-based INI file parsing and writing
- PROMPT_COMMAND mechanism for directory change detection
- Timestamped backup files before credential modifications (format: `credentials.bak.YYYYMMDD-HHMMSS`)
- chmod 600 on all credential file writes
- `curl | bash` installation pattern to `~/.local/bin/`
- Function naming convention: `awsprof_<module>_<action>`
- All user messages to stderr, eval-able code to stdout only
- Exit codes: 0 (success), 1 (any error)

**Starter Template:**
- Architecture specifies: **Greenfield pure bash** (no starter template needed)
- Single `awsprof` executable script

### FR Coverage Map

| FR | Epic | Description |
|----|------|-------------|
| FR1 | Epic 2 | Add new profile with credentials |
| FR2 | Epic 2 | Edit existing profile credentials |
| FR3 | Epic 2 | Remove profile from system |
| FR4 | Epic 2 | List all configured profiles |
| FR5 | Epic 2 | Store in ~/.aws/credentials format |
| FR6 | Epic 2 | Preserve existing profiles |
| FR7 | Epic 2 | Import from existing credentials |
| FR8 | Epic 2 | Detect and list profiles during import |
| FR9 | Epic 2 | Preserve original file structure |
| FR10 | Epic 1 | Switch to profile by name |
| FR11 | Epic 1 | Set AWS_PROFILE environment variable |
| FR12 | Epic 1 | Confirm successful switch |
| FR13 | Epic 1 | Error on non-existent profile |
| FR14 | Epic 1 | Query currently active profile |
| FR15 | Epic 1 | Display current AWS_PROFILE value |
| FR16 | Epic 3 | Create .awsprofile file |
| FR17 | Epic 3 | Detect .awsprofile on directory entry |
| FR18 | Epic 3 | Compare current vs expected profile |
| FR19 | Epic 3 | Display mismatch warning |
| FR20 | Epic 3 | Prompt to switch on mismatch |
| FR21 | Epic 3 | Accept or decline switch prompt |
| FR22 | Epic 3 | Silent when profile matches |
| FR23 | Epic 3 | Shell init script for bash |
| FR24 | Epic 3 | Shell init script for sh |
| FR25 | Epic 3 | Automatic detection on cd |
| FR26 | Epic 1 | Output eval-able shell commands |
| FR27 | Epic 1 | Exit code 0 on success |
| FR28 | Epic 1 | Non-zero exit on failure |
| FR29 | Epic 1 | Clear error messages |
| FR30 | Epic 1 | Validate profile exists before switch |
| FR31 | Epic 2 | Validate credential format |
| FR32 | Epic 2 | Hidden credential input |
| FR33 | Epic 2 | Never display secrets |
| FR34 | Epic 2 | Direct file writes only |

## Epic List

### Epic 1: Profile Switching & Status
Users can switch between AWS profiles and always know which profile is active.
**FRs covered:** FR10, FR11, FR12, FR13, FR14, FR15, FR26, FR27, FR28, FR29, FR30

### Epic 2: Profile Management
Users can add, edit, remove, list, and import AWS profiles without manually editing credential files.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR6, FR7, FR8, FR9, FR31, FR32, FR33, FR34

### Epic 3: Project-Aware Profile Safety
Users get automatic warnings when their active profile doesn't match the project's expected profile.
**FRs covered:** FR16, FR17, FR18, FR19, FR20, FR21, FR22, FR23, FR24, FR25

---

## Epic 1: Profile Switching & Status

Users can switch between AWS profiles and always know which profile is active. This epic establishes the script foundation, INI file reading, and the eval output pattern required for shell integration.

<!-- Stories to be created in Step 3 -->

## Epic 2: Profile Management

Users can add, edit, remove, list, and import AWS profiles without manually editing credential files. Includes secure credential input, INI file writing, and backup-before-modify safety.

<!-- Stories to be created in Step 3 -->

## Epic 3: Project-Aware Profile Safety

Users get automatic warnings when their active profile doesn't match the project's expected profile. Implements PROMPT_COMMAND shell hook and .awsprofile detection.

<!-- Stories to be created in Step 3 -->
