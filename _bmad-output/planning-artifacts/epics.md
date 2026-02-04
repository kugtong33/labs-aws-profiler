---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - prd.md
  - architecture.md
completedDate: 2026-01-23
---

# labs-aws-profiler - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for labs-aws-profiler, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

**Profile Management**
- FR1: User can add a new AWS profile by providing a name, access key ID, secret access key, region, and output format
- FR2: User can edit an existing profile's credentials and config defaults (access key ID, secret access key, region, output)
- FR3: User can remove an existing profile from the system (credentials and config)
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

- FR35: System detects a project ".awsprofile" file and immediately switches to the specified profile when it is valid
- FR36: System supports a global ".awsprofile" file located at "~/.aws/.awsprofile"
- FR37: If no project ".awsprofile" exists, system uses the global ".awsprofile" by default
- FR38: System uses the profile specified in ".awsprofile" directly without mismatch checks or prompts
- FR39: If the profile in ".awsprofile" does not exist, system warns and clears AWS_PROFILE

**AWS Config Support**
- FR40: User can set a default AWS region for a profile (writes to `~/.aws/config`)
- FR41: User can set a default AWS output format for a profile (writes to `~/.aws/config`)
- FR42: User can view the current region/output for a profile (reads from `~/.aws/config`)
- FR43: System preserves existing config entries when adding or editing config settings

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
| FR35 | Epic 4 | Project .awsprofile auto-switch |
| FR36 | Epic 4 | Global .awsprofile support in ~/.aws |
| FR37 | Epic 4 | Use global .awsprofile when project file missing |
| FR38 | Epic 4 | Direct use of .awsprofile without mismatch prompts |
| FR39 | Epic 4 | Warn and clear AWS_PROFILE if profile missing |
| FR40 | Epic 5 | Mirror config region on add/edit |
| FR41 | Epic 5 | Mirror config output on add/edit |
| FR42 | Epic 5 | Show profile config summary |
| FR43 | Epic 5 | Preserve existing config entries when editing |

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
### Epic 4: AWS Profile File Improvements
Users can rely on project and global .awsprofile files to set the correct profile automatically without mismatch prompts.
**FRs covered:** FR35, FR36, FR37, FR38, FR39

### Epic 5: Unified Profile + Config Management
Users manage credentials and config together so add/edit/remove mirrors config defaults per profile.
**FRs covered:** FR1, FR2, FR3, FR40, FR41, FR42, FR43

---

## Epic 1: Profile Switching & Status

Users can switch between AWS profiles and always know which profile is active. This epic establishes the script foundation, INI file reading, and the eval output pattern required for shell integration.

### Story 1.1: Script Foundation & INI Reading

As an infrastructure developer,
I want a basic awsprof script that can read AWS credential files,
So that I have the foundation for all profile management operations.

**Acceptance Criteria:**

**Given** the user has a `~/.aws/credentials` file with one or more profiles
**When** the script's INI parsing functions are called
**Then** the script correctly extracts profile names and their key-value pairs
**And** the script handles both profile sections and key-value pairs within sections
**And** the script uses awk-based parsing for reliability

**Given** the credentials file does not exist
**When** the script attempts to read profiles
**Then** the script handles the missing file gracefully without crashing
**And** returns appropriate error messaging

**Given** the credentials file has malformed INI syntax
**When** the script attempts to parse it
**Then** the script handles parsing errors without data loss
**And** provides clear error messages to stderr

**Technical Requirements:**
- Function naming follows `awsprof_<module>_<action>` convention (FR, Architecture)
- All user messages output to stderr (FR26, Architecture)
- Exit code 0 on success, 1 on failure (FR27, FR28)
- Single file structure with embedded modules (Architecture)

---

### Story 1.2: List Available Profiles

As an infrastructure developer,
I want to see all available AWS profiles in a readable list,
So that I know which profiles are configured and can choose one to use.

**Acceptance Criteria:**

**Given** the user has multiple profiles in `~/.aws/credentials`
**When** the user runs `awsprof list`
**Then** all profile names are displayed, one per line
**And** the command completes in under 100ms (NFR1)
**And** the output is clean and parseable

**Given** the credentials file contains 100+ profiles
**When** the user runs `awsprof list`
**Then** all profiles display immediately without noticeable delay (NFR2)

**Given** no credentials file exists
**When** the user runs `awsprof list`
**Then** the command displays a clear error message to stderr (FR29)
**And** exits with status code 1 (FR28)

**Given** the credentials file is empty
**When** the user runs `awsprof list`
**Then** the command displays "No profiles found" or similar message
**And** exits with status code 0 (FR27)

**Technical Requirements:**
- Implements FR4 (view list of all configured profiles)
- Uses INI parsing from Story 1.1
- Messages to stderr, profile list to stdout

---

### Story 1.3: Switch to Profile

As an infrastructure developer,
I want to switch to a specific AWS profile by name,
So that my AWS CLI commands target the correct account.

**Acceptance Criteria:**

**Given** the user has a profile named "client-acme" in their credentials
**When** the user runs `eval "$(awsprof use client-acme)"`
**Then** the `AWS_PROFILE` environment variable is set to "client-acme" (FR11)
**And** stdout contains `export AWS_PROFILE=client-acme` for eval (FR26)
**And** stderr displays "Switched to profile: client-acme" (FR12)
**And** the command exits with status code 0 (FR27)

**Given** the user attempts to switch to a non-existent profile "foo"
**When** the user runs `awsprof use foo`
**Then** the command validates the profile exists first (FR30)
**And** displays "Error: Profile 'foo' not found" to stderr (FR13, FR29)
**And** does not output any eval code to stdout
**And** exits with status code 1 (FR28)

**Given** the user runs `awsprof use` without providing a profile name
**When** the command is executed
**Then** a clear usage error is displayed to stderr (FR29)
**And** exits with status code 1 (FR28)

**Given** the credentials file is accessible and valid
**When** the user switches profiles
**Then** the operation completes in under 100ms (NFR1)

**Technical Requirements:**
- Implements FR10, FR11, FR12, FR13, FR26, FR27, FR28, FR29, FR30
- Stdout for eval, stderr for user messages (Architecture)
- Uses INI reading from Story 1.1

---

### Story 1.4: Show Current Profile

As an infrastructure developer,
I want to see which AWS profile is currently active,
So that I always know which account my commands will affect.

**Acceptance Criteria:**

**Given** the `AWS_PROFILE` environment variable is set to "client-acme"
**When** the user runs `awsprof whoami`
**Then** the command displays "client-acme" (FR15)
**And** exits with status code 0 (FR27)

**Given** the `AWS_PROFILE` environment variable is not set
**When** the user runs `awsprof whoami`
**Then** the command displays "No profile set (using default)" or similar (FR15)
**And** exits with status code 0 (FR27)

**Given** any state of the AWS_PROFILE variable
**When** the user queries the current profile
**Then** the operation completes in under 100ms (NFR1)

**Technical Requirements:**
- Implements FR14, FR15, FR27
- Simple environment variable check
- Clear, concise output

## Epic 2: Profile Management

Users can add, edit, remove, list, and import AWS profiles without manually editing credential files. Includes secure credential input, INI file writing, and backup-before-modify safety.

### Story 2.1: INI File Writing & Backup Safety

As an infrastructure developer,
I want the script to safely write to credential files with automatic backups,
So that I never lose data when modifying profiles.

**Acceptance Criteria:**

**Given** the user has an existing `~/.aws/credentials` file
**When** any write operation is about to modify the file
**Then** a timestamped backup is created first (NFR11)
**And** the backup follows format `credentials.bak.YYYYMMDD-HHMMSS` (Architecture)
**And** the backup is in the same directory (`~/.aws/`)

**Given** a write operation creates a new credentials file
**When** the file is written to disk
**Then** permissions are set to 600 (user read/write only) (NFR8, Architecture)
**And** the write operation is atomic using temp file + mv pattern (NFR4, NFR10)

**Given** a write operation fails midway (disk full, permissions error)
**When** the failure occurs
**Then** the original credentials file remains unchanged (NFR10)
**And** no partial writes are left on disk
**And** a clear error message is displayed to stderr

**Given** the credentials file contains malformed data
**When** a write operation is attempted
**Then** the existing file is preserved via backup (NFR12)
**And** the operation proceeds if possible or fails gracefully

**Technical Requirements:**
- Implements awk-based INI writing (Architecture)
- Function for adding/updating profile sections
- Function for deleting profile sections
- Atomic write pattern: write to temp → backup original → move temp to target

---

### Story 2.2: Add New Profile

As an infrastructure developer,
I want to add a new AWS profile with credentials and config defaults,
So that I can configure access to a new AWS account without manual file editing.

**Acceptance Criteria:**

**Given** the user runs `awsprof add newclient-staging`
**When** the command prompts for inputs
**Then** the Access Key ID prompt is displayed
**And** the Secret Access Key prompt is displayed with hidden input (no terminal echo) (FR32, NFR5)
**And** the Region prompt is displayed
**And** the Output format prompt is displayed
**And** all values are captured securely
**And** blank region or output inputs result in those config keys being omitted (leave unset)

**Given** the user provides valid credentials
**When** the profile is saved
**Then** the profile is written to `~/.aws/credentials` in standard INI format (FR5)
**And** the format is `[newclient-staging]` section with `aws_access_key_id` and `aws_secret_access_key` keys
**And** the profile config is written to `~/.aws/config` in standard INI format with `[profile newclient-staging]` (FR40, FR41)
**And** the config includes `region` and `output` keys
**And** a timestamped backup is created before writing (NFR11)
**And** the file permissions are set to 600 (NFR8)
**And** the secret key is never displayed in output (FR33, NFR6)
**And** credentials are written directly to file without intermediate storage (FR34)
**And** config entries are written directly to file without intermediate storage

**Given** existing profiles already exist in the credentials file
**When** a new profile is added
**Then** all existing profiles are preserved (FR6)
**And** the new profile is appended correctly
**And** existing config entries are preserved (FR43)

**Given** a profile with the same name already exists
**When** the user attempts to add it
**Then** an error message is displayed: "Error: Profile 'name' already exists. Use 'awsprof edit' to modify." (FR29)
**And** the command exits with status code 1 (FR28)

**Given** the user provides invalid credential format
**When** validation is performed
**Then** the invalid credentials are rejected (FR31)
**And** a clear error message explains the issue
**And** the command exits with status code 1

**Given** the user provides an unsupported output format
**When** validation is performed
**Then** the output format is rejected
**And** a clear error message explains the issue
**And** the command exits with status code 1

**Technical Requirements:**
- Implements FR1, FR5, FR6, FR31, FR32, FR33, FR34
- Uses INI writing and backup from Story 2.1
- Never logs or echoes secrets (NFR7)

---

### Story 2.3: Edit Existing Profile

As an infrastructure developer,
I want to update credentials and config defaults for an existing profile,
So that I can rotate keys without losing the profile configuration.

**Acceptance Criteria:**

**Given** a profile named "client-acme" exists
**When** the user runs `awsprof edit client-acme`
**Then** the command prompts for new Access Key ID
**And** prompts for new Secret Access Key with hidden input (FR32, NFR5)
**And** prompts for Region
**And** prompts for Output format
**And** updates the profile in `~/.aws/credentials` (FR2)
**And** updates the profile in `~/.aws/config` (FR40, FR41)
**And** blank region or output inputs result in those config keys being omitted (leave unset)

**Given** the user provides new credentials
**When** the profile is updated
**Then** a timestamped backup is created first (NFR11)
**And** only the specified profile's credentials are changed (FR6)
**And** all other profiles remain unchanged
**And** only the specified profile's config entries are changed
**And** all other config entries remain unchanged
**And** file permissions are set to 600 (NFR8)
**And** the secret key is never displayed (FR33, NFR6)

**Given** the user attempts to edit a non-existent profile "foo"
**When** the command is executed
**Then** an error is displayed: "Error: Profile 'foo' not found" (FR29)
**And** the command exits with status code 1 (FR28)

**Given** the user provides invalid credential format
**When** validation occurs
**Then** the credentials are rejected (FR31)
**And** the original profile remains unchanged
**And** a clear error message is shown

**Given** the user provides an unsupported output format
**When** validation occurs
**Then** the output format is rejected
**And** the original profile remains unchanged
**And** a clear error message is shown

**Technical Requirements:**
- Implements FR2, FR6, FR31, FR32, FR33
- Uses INI writing and backup from Story 2.1
- Atomic file operations (NFR4, NFR10)

---

### Story 2.4: Remove Profile

As an infrastructure developer,
I want to delete a profile I no longer use along with its config defaults,
So that my credentials file stays clean and manageable.

**Acceptance Criteria:**

**Given** a profile named "old-client" exists
**When** the user runs `awsprof remove old-client`
**Then** a timestamped backup is created (NFR11)
**And** the `[old-client]` section and its credentials are removed from the credentials file (FR3)
**And** the `[profile old-client]` section is removed from the config file
**And** all other profiles are preserved (FR6)
**And** all other config entries are preserved (FR43)
**And** file permissions remain 600 (NFR8)

**Given** the user attempts to remove a non-existent profile "foo"
**When** the command is executed
**Then** an error is displayed: "Error: Profile 'foo' not found" (FR29)
**And** the command exits with status code 1 (FR28)

**Given** the user removes the only profile in the credentials file
**When** the removal completes
**Then** the credentials file exists but is empty (or has only comments)
**And** the operation completes successfully with exit code 0 (FR27)

**Given** multiple profiles exist
**When** one is removed
**Then** the file structure is preserved (FR6)
**And** the operation is atomic (NFR10)

**Technical Requirements:**
- Implements FR3, FR6
- Uses INI writing and backup from Story 2.1
- Clean section removal with awk

---

### Story 2.5: Import Existing Profiles

As an infrastructure developer,
I want to import profiles from my existing AWS credentials file,
So that I can verify awsprof recognizes all my configured accounts.

**Acceptance Criteria:**

**Given** the user has existing profiles in `~/.aws/credentials`
**When** the user runs `awsprof import`
**Then** the command reads and lists all profiles found (FR7, FR8)
**And** displays a count: "Found X profiles: profile1, profile2, profile3..."
**And** confirms "All profiles are accessible to awsprof"

**Given** the credentials file has complex formatting (comments, blank lines, spacing)
**When** import is executed
**Then** the original file structure is preserved (FR9)
**And** the import is read-only (no modifications made)
**And** all valid profile sections are detected (FR8)

**Given** no credentials file exists
**When** the user runs `awsprof import`
**Then** a clear message is displayed: "No credentials file found at ~/.aws/credentials"
**And** the command exits with status code 0 (informational, not an error)

**Given** the credentials file is malformed
**When** import is attempted
**Then** the command handles errors gracefully (NFR12)
**And** reports which profiles were successfully detected vs. errors encountered

**Technical Requirements:**
- Implements FR7, FR8, FR9
- Uses INI reading from Story 1.1
- Read-only operation, no file modifications
- Informational output only

## Epic 3: Project-Aware Profile Safety

Users get automatic warnings when their active profile doesn't match the project's expected profile. Implements PROMPT_COMMAND shell hook and .awsprofile detection.

### Story 3.1: Shell Initialization Script for Bash

As an infrastructure developer,
I want to source awsprof's shell integration in my bashrc,
So that profile detection and switching work seamlessly in my shell.

**Acceptance Criteria:**

**Given** the user runs `awsprof init`
**When** the command executes
**Then** shell code is output to stdout suitable for eval (FR26)
**And** the code defines an `awsprof` wrapper function that calls `eval "$(command awsprof "$@")"`
**And** the code adds a PROMPT_COMMAND hook for directory change detection (Architecture)
**And** the output is valid bash 4.0+ syntax (NFR17)

**Given** the user adds `eval "$(awsprof init)"` to their `~/.bashrc`
**When** they start a new bash shell
**Then** the awsprof wrapper function is available
**And** the PROMPT_COMMAND hook is active
**And** their shell starts normally without errors (NFR13)

**Given** the shell integration is loaded
**When** the user types `awsprof use profile-name`
**Then** the wrapper function executes and sets AWS_PROFILE in the current shell
**And** no subshell limitations prevent the environment variable export

**Given** the awsprof executable is not in PATH
**When** the init code runs
**Then** the shell integration fails gracefully (NFR13)
**And** the shell remains functional

**Technical Requirements:**
- Implements FR23, FR26
- Outputs eval-able shell code to stdout
- PROMPT_COMMAND integration (Architecture)
- Bash 4.0+ compatible (NFR17)

---

### Story 3.2: POSIX sh Initialization Script

As an infrastructure developer using POSIX sh,
I want basic awsprof functionality in my sh environment,
So that I can switch profiles even in minimal shell environments.

**Acceptance Criteria:**

**Given** the user runs `awsprof init --sh`
**When** the command executes
**Then** POSIX sh compatible code is output to stdout (FR24)
**And** the code defines an `awsprof` wrapper function using POSIX syntax
**And** a note is included that automatic detection is not available (no PROMPT_COMMAND equivalent)
**And** the output contains only POSIX sh compatible syntax (NFR17)

**Given** the user sources the sh init code in their shell
**When** they use `awsprof use profile-name`
**Then** the profile switch works correctly
**And** AWS_PROFILE is set in the current shell

**Given** POSIX sh limitations
**When** the user enters a directory
**Then** automatic .awsprofile detection does not occur (by design)
**And** the user can manually run `awsprof check` to verify profile match

**Technical Requirements:**
- Implements FR24
- POSIX sh syntax only (NFR17)
- No bash-specific features (no PROMPT_COMMAND, no arrays)
- Manual check command for directory validation

---

### Story 3.3: Project Profile File Creation

As an infrastructure developer,
I want to create a `.awsprofile` file in my project directory,
So that the correct profile is associated with this project.

**Acceptance Criteria:**

**Given** the user is in a project directory
**When** they create a file named `.awsprofile` containing "client-acme"
**Then** the file contains a single line with the profile name (FR16)
**And** no special formatting is required
**And** the file can be committed to version control

**Given** a `.awsprofile` file exists with profile name "client-acme"
**When** awsprof's detection hook runs
**Then** the profile name is read correctly
**And** whitespace (leading/trailing) is trimmed automatically

**Given** the `.awsprofile` file is empty or malformed
**When** the detection hook runs
**Then** the file is ignored gracefully
**And** no error messages are displayed

**Technical Requirements:**
- Implements FR16
- Simple text file format (single line with profile name)
- Documentation on usage pattern

---

### Story 3.4: Directory Change Detection and Profile Comparison

As an infrastructure developer,
I want automatic detection when I enter a directory with a profile mismatch,
So that I'm immediately warned before running commands in the wrong account.

**Acceptance Criteria:**

**Given** bash shell integration is loaded via PROMPT_COMMAND
**When** the user changes to any directory
**Then** the hook checks for a `.awsprofile` file (FR17)
**And** the check adds no perceptible delay to the prompt (NFR3)
**And** the check completes in under 10ms

**Given** a `.awsprofile` file exists in the directory
**When** the hook detects it
**Then** the expected profile name is read from the file
**And** it is compared against the current `AWS_PROFILE` environment variable (FR18)

**Given** the current profile matches the project's expected profile
**When** the comparison is performed
**Then** no output is displayed (FR22)
**And** the prompt appears normally (silent success)

**Given** the current profile differs from the expected profile
**When** the comparison detects a mismatch
**Then** a warning is displayed to the user (FR19)
**And** the warning format is: `⚠️  Profile mismatch: current 'personal', project expects 'client-acme'`

**Given** no AWS_PROFILE is set (using default)
**When** a project expects a specific profile
**Then** a mismatch is detected and reported
**And** the current profile is shown as 'default' or '(none)'

**Technical Requirements:**
- Implements FR17, FR18, FR19, FR22
- PROMPT_COMMAND hook (Architecture)
- Fast execution (NFR3)
- Non-blocking detection

---

### Story 3.5: Interactive Profile Switch Prompt

As an infrastructure developer,
I want to be prompted to switch profiles when a mismatch is detected,
So that I can quickly fix the mismatch without typing the full command.

**Acceptance Criteria:**

**Given** a profile mismatch has been detected
**When** the warning is displayed
**Then** an interactive prompt appears: "Switch profile? [y/N]" (FR20)
**And** the prompt waits for user input (FR21)

**Given** the user responds with 'y' or 'Y'
**When** the input is processed
**Then** the profile is switched automatically to the expected profile (FR21)
**And** `eval "$(awsprof use expected-profile)"` is executed
**And** a confirmation message is shown: "Switched to profile: expected-profile"
**And** the user's command prompt is ready for the next command

**Given** the user responds with 'n', 'N', or just presses Enter
**When** the input is processed
**Then** the profile switch is declined (FR21)
**And** no profile change occurs
**And** the current profile remains active
**And** the user's command prompt appears normally

**Given** the user enters any other input
**When** the response is processed
**Then** it is treated as 'No' (default behavior)
**And** no profile switch occurs

**Given** the switch prompt appears
**When** the user interaction completes
**Then** the shell remains fully functional regardless of response (NFR13)
**And** no errors break the user's workflow

**Technical Requirements:**
- Implements FR20, FR21
- Uses bash `read` with prompt
- Executes eval wrapper for actual switch
- Non-intrusive (FR22 - silent when matched)

---

### Story 3.6: Shell Integration Robustness

As an infrastructure developer,
I want shell integration to handle errors gracefully,
So that awsprof issues never break my terminal session.

**Acceptance Criteria:**

**Given** the awsprof executable is deleted or moved
**When** the PROMPT_COMMAND hook runs
**Then** no error messages spam the terminal
**And** the shell continues to function normally (NFR13)
**And** the hook silently exits if awsprof is not available

**Given** the credentials file is corrupted
**When** the detection hook attempts to read profiles
**Then** errors are suppressed in the hook
**And** the user's prompt appears normally
**And** error details are only shown when running awsprof commands directly

**Given** the `.awsprofile` file contains an invalid profile name
**When** the user is prompted to switch
**Then** the switch attempt displays an appropriate error
**And** the shell remains functional
**And** the user can manually fix the issue

**Given** disk I/O is slow or a network drive is mounted
**When** the PROMPT_COMMAND hook runs
**Then** timeouts or delays don't hang the shell
**And** the hook exits quickly even on I/O errors

**Given** multiple terminal tabs/windows are open
**When** profiles are switched in one window
**Then** each window maintains its own AWS_PROFILE
**And** .awsprofile detection works independently per session

**Technical Requirements:**
- Implements NFR13 (shell integration never breaks shell)
- Error handling in all hook code
- Defensive programming (check file exists, command exists, etc.)
- Fast failure paths (NFR3)

## Epic 4: AWS Profile File Improvements

Users can rely on project and global .awsprofile files to set the correct profile automatically without mismatch prompts.
**FRs covered:** FR35, FR36, FR37, FR38, FR39


### Story 4.1: Project .awsprofile Auto-Switch

As an infrastructure developer,
I want the tool to read a project .awsprofile and immediately switch to that profile when it is valid,
So that I enter the project already targeting the correct AWS account.

**Acceptance Criteria:**

**Given** the user enters a directory containing a `.awsprofile` file with a valid profile name
**When** the shell integration hook runs
**Then** `AWS_PROFILE` is set to that profile without any mismatch prompt

**Given** the `.awsprofile` file contains whitespace around the profile name
**When** the file is read
**Then** leading and trailing whitespace are trimmed before use

### Story 4.2: Global .awsprofile Fallback

As an infrastructure developer,
I want a global `~/.aws/.awsprofile` to define my default profile,
So that it is used automatically when a project-specific file is absent.

**Acceptance Criteria:**

**Given** there is no project `.awsprofile` in the current directory
**When** the shell hook runs and a global `~/.aws/.awsprofile` exists
**Then** the profile in the global file is applied automatically
**And** `AWS_PROFILE` is set to the global profile without a mismatch prompt

**Given** a project `.awsprofile` exists
**When** both project and global `.awsprofile` files are present
**Then** the project file takes precedence over the global file

**Given** neither a project `.awsprofile` nor a global `~/.aws/.awsprofile` exists
**When** the hook runs
**Then** no profile is applied and no output is produced

### Story 4.3: Direct Use Without Mismatch Checks

As an infrastructure developer,
I want the tool to use the profile specified in `.awsprofile` directly,
So that I no longer see mismatch warnings or switch prompts.

**Acceptance Criteria:**

**Given** a `.awsprofile` file specifies a profile name
**When** the shell hook evaluates the directory
**Then** no mismatch warning or prompt is shown
**And** the specified profile is applied immediately

**Given** the current `AWS_PROFILE` already matches the `.awsprofile` value
**When** the hook runs
**Then** no output is produced

### Story 4.4: Missing Profile Handling

As an infrastructure developer,
I want a clear warning and the active profile cleared when `.awsprofile` points to a non-existent profile,
So that I do not accidentally run commands against the wrong account.

**Acceptance Criteria:**

**Given** a `.awsprofile` specifies a profile that does not exist in credentials
**When** the hook evaluates the file
**Then** a warning is written to stderr indicating the profile does not exist
**And** `AWS_PROFILE` is cleared (unset or set to empty)

**Given** the profile is later added to credentials
**When** the hook runs again in the same directory
**Then** the profile is applied normally

---

## Epic 5: Unified Profile + Config Management

Users manage credentials and config together so add/edit/remove mirrors config defaults per profile.

**Proposed FR coverage (new):**
- FR1, FR2, FR3: Add/edit/remove profiles
- FR40: Set default AWS region for a profile
- FR41: Set default AWS output format for a profile
- FR42: View current region/output for a profile
- FR43: Preserve existing config entries when adding or editing config settings

### Story 5.1: Add Profile Mirrors Config

As an infrastructure developer,
I want awsprof add to write both credentials and config defaults together,
So that profile creation is complete and consistent.

**Acceptance Criteria:**

**Given** the user runs `awsprof add client-acme`
**When** prompts are completed for access key, secret key, region, and output
**Then** `~/.aws/credentials` contains the new profile (FR1)
**And** `~/.aws/config` contains `[profile client-acme]` with `region`/`output` if provided (FR40, FR41)
**And** existing config entries are preserved (FR43)

**Given** the user leaves region or output blank
**When** the add command completes
**Then** the corresponding config key is omitted (FR40, FR41)

**Technical Requirements:**
- Atomic writes + timestamped backups for both files
- `chmod 600` on both files after write

---

### Story 5.2: Edit Profile Mirrors Config

As an infrastructure developer,
I want awsprof edit to update credentials and config defaults together,
So that profile changes stay in sync.

**Acceptance Criteria:**

**Given** the user runs `awsprof edit client-acme`
**When** prompts are completed for access key, secret key, region, and output
**Then** credentials are updated in `~/.aws/credentials` (FR2)
**And** `~/.aws/config` updates `[profile client-acme]` with provided region/output (FR40, FR41)
**And** existing config entries are preserved (FR43)

**Given** the user leaves region or output blank
**When** the edit command completes
**Then** the corresponding config key is removed or left unset for that profile

**Technical Requirements:**
- Atomic writes + timestamped backups for both files
- `chmod 600` on both files after write

---

### Story 5.3: Remove Profile Mirrors Config

As an infrastructure developer,
I want awsprof remove to delete config defaults for the same profile,
So that no stale config remains after profile removal.

**Acceptance Criteria:**

**Given** the user runs `awsprof remove client-acme`
**When** the command completes
**Then** the profile is removed from `~/.aws/credentials` (FR3)
**And** the corresponding `[profile client-acme]` section is removed from `~/.aws/config` (FR43)
**And** other config profiles remain unchanged (FR43)

**Technical Requirements:**
- Atomic writes + timestamped backups for both files
- `chmod 600` on both files after write

---

### Story 5.4: Show Profile Config Summary

As an infrastructure developer,
I want to view the region and output configured for a profile,
So that I can quickly confirm defaults without opening the file.

**Acceptance Criteria:**

**Given** the user runs `awsprof config show client-acme`
**When** the command executes
**Then** the current `region` and `output` are displayed if set (FR42)
**And** missing values are displayed as "not set" (or similar)
**And** the command exits with status code 0

**Given** the user requests the default profile
**When** the command executes
**Then** values are read from `[default]` (FR42)

**Given** the config file is malformed
**When** the command executes
**Then** a clear error is displayed to stderr
**And** the command exits with status code 1

**Technical Requirements:**
- Read-only operation
- Data to stdout, messages to stderr
- Fast execution (<100ms)
