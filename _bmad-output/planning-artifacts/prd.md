---
stepsCompleted: [step-01-init, step-02-discovery, step-03-success, step-04-journeys, step-05-domain, step-06-innovation, step-07-project-type, step-08-scoping, step-09-functional, step-10-nonfunctional, step-11-polish]
inputDocuments:
  - product-brief-labs-aws-profiler-2026-01-22.md
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 0
classification:
  projectType: cli_tool
  domain: developer_tools
  complexity: low
  projectContext: greenfield
workflowType: 'prd'
date: 2026-01-22
author: Ubuntu
---

# Product Requirements Document - labs-aws-profiler

**Author:** Ubuntu
**Date:** 2026-01-22

## Executive Summary

**labs-aws-profiler** is a CLI tool for managing and switching between AWS profiles. It solves the pain of manually editing `~/.aws/credentials`, forgetting which account is active, and accidentally running commands against the wrong AWS account.

**Core Value:** Fast profile switching with project-aware safety warnings.

**Target User:** Infrastructure developers managing multiple AWS accounts (personal, work, client).

**Key Capabilities:**
- Profile CRUD (add, edit, remove, list, import)
- Instant switching via `AWS_PROFILE` environment variable
- Project-profile linking with mismatch warnings
- AWS config defaults (region/output) per profile

**Technical Context:** Linux CLI tool, bash/sh compatible, uses standard AWS credential files.

## Success Criteria

### User Success

- **Immediate clarity:** User always knows which AWS profile is currently active
- **Effortless switching:** Profile changes happen in seconds, not minutes of file editing
- **Project-profile linking:** Walking into a project directory immediately surfaces the correct profile
- **"Aha!" moment:** The relief of not hunting through dozens of profiles to find the right one for a project
- **Safety net:** Mismatch warnings prevent accidental operations on wrong accounts

### Business Success

N/A - Personal open-source utility. Success is measured by personal utility, not commercial metrics.

### Technical Success

- 100% reliability on profile switching operations
- Full compatibility with `~/.aws/credentials` and `~/.aws/config` formats
- Works with existing AWS CLI and third-party tools (Terraform, CDK, etc.)
- Instantaneous command response (<100ms)
- Platform: Linux
- Shell compatibility: bash, sh

### Measurable Outcomes

| Outcome | Target |
|---------|--------|
| Profile switch success rate | 100% |
| Credential file compatibility | No corruption, full round-trip |
| Command latency | <100ms |
| Mismatch detection accuracy | 100% (no false negatives) |

## Product Scope

### MVP - Minimum Viable Product

**Profile Management:**
- `awsprof add <name>` - Add profile with access key, secret, region, and output (prompts for all)
- `awsprof edit <name>` - Edit existing profile credentials and config defaults (prompts for all)
- `awsprof remove <name>` - Delete a profile and its config defaults
- `awsprof list` - Show all available profiles
- `awsprof import` - Import existing profiles from `~/.aws/credentials`

**Profile Switching:**
- `awsprof use <name>` - Switch to profile (sets `AWS_PROFILE` env var)
- `awsprof whoami` - Show currently active profile

**Project-Profile Linking:**
- `.awsprofile` file in project directory
- Mismatch warning when current profile differs from project's linked profile
- Prompt to switch when mismatched

**AWS Config Support:**
- `awsprof config set-region <name> <region>` - Set default region for a profile
- `awsprof config set-output <name> <format>` - Set default output format for a profile
- `awsprof config show <name>` - Show region/output for a profile

### Growth Features (Post-MVP)

N/A - Future enhancements driven by actual usage needs, not speculative roadmaps.

### Vision (Future)

N/A - Focus on working utility first.

## User Journeys

### Journey 1: First-Time Setup

**Alex discovers awsprof and sets up their workflow**

**Opening Scene:**
Alex has just spent 20 minutes hunting through `~/.aws/credentials` trying to remember which profile belongs to which client. The file has grown to 15 profiles over the years - some named cryptically like `prod-east` or `client2-staging`. Alex thinks "there has to be a better way" and searches for AWS profile management tools.

**Rising Action:**
Alex finds `awsprof`, installs it, and runs `awsprof import`. The tool reads their existing `~/.aws/credentials` and `~/.aws/config` files, listing all 15 profiles it found. Alex sees the familiar names and realizes their existing setup is preserved - nothing was lost or changed.

**Climax:**
Alex runs `awsprof list` and sees all profiles displayed cleanly. They run `awsprof use client-acme` and see confirmation that `AWS_PROFILE` is now set. A quick `awsprof whoami` confirms: `client-acme`. The cognitive load of "which account am I in?" vanishes.

**Resolution:**
Alex creates `.awsprofile` files in their three active project directories, each containing the correct profile name. The next time they `cd` into a project, they'll know immediately if they're on the wrong profile. Setup took 5 minutes instead of the hours it would take to build custom bash scripts.

---

### Journey 2: Daily Workflow - Profile Switching

**Alex switches contexts during active development**

**Opening Scene:**
It's Tuesday morning. Alex is debugging a Lambda function in the `client-acme` AWS account. A Slack message comes in: urgent issue in the `work-prod` account - CloudWatch alarms firing.

**Rising Action:**
Alex needs to switch contexts immediately. Instead of opening `~/.aws/credentials` in vim, searching for `work-prod`, copying values, or trying to remember which bash script to source, Alex simply types:

```
awsprof use work-prod
```

Terminal confirms: `Switched to profile: work-prod`

**Climax:**
Alex runs `aws cloudwatch describe-alarms --state-value ALARM` and immediately sees the production alarms. No hesitation, no "wait, am I in the right account?" moment. The AWS CLI just works because `AWS_PROFILE` is set correctly.

**Resolution:**
Alex fixes the production issue in 10 minutes. Switches back to `client-acme` with another `awsprof use` command and continues Lambda debugging. Context switches that used to break flow now take 2 seconds.

---

### Journey 3: Project Context Switch - Mismatch Warning

**Alex enters a project directory with the wrong profile active**

**Opening Scene:**
Alex has been working in the `personal` AWS account, experimenting with a side project. They get a calendar reminder: client meeting in 30 minutes, need to prep the `client-acme` infrastructure changes.

**Rising Action:**
Alex runs `cd ~/projects/client-acme-infra` - a directory with a `.awsprofile` file containing `client-acme`. The terminal displays:

```
⚠️  Profile mismatch: current 'personal', project expects 'client-acme'
    Switch profile? [y/N]
```

**Climax:**
Alex realizes they almost ran Terraform against the wrong account. This is the exact mistake they've made before - once accidentally creating resources in a personal account that should have gone to a client. They press `y`.

**Resolution:**
Profile switches to `client-acme`. Alex proceeds with confidence, knowing every `terraform apply` and `aws` command will hit the correct account. The warning system just prevented a potentially embarrassing (or costly) mistake.

---

### Journey 4: Profile Management - Adding New Client

**Alex onboards a new client and adds their AWS profile**

**Opening Scene:**
Alex signs a new client contract. The client sends over AWS access keys for their staging environment. Time to add this to the workflow.

**Rising Action:**
Alex runs:
```
awsprof add newclient-staging
```

The tool prompts for AWS Access Key ID and Secret Access Key. Alex pastes them in. The tool confirms the profile was added to `~/.aws/credentials`.

**Climax:**
Alex creates the project directory `~/projects/newclient/`, adds a `.awsprofile` file with `newclient-staging`, and runs `awsprof use newclient-staging`. Everything works. The new client is fully integrated into the workflow in under a minute.

**Resolution:**
When the client later provides production keys, Alex runs `awsprof add newclient-prod`. The workflow scales effortlessly from 15 profiles to 17. No file editing, no syntax errors, no forgetting where credentials go.

---

### Journey Requirements Summary

| Journey | Capabilities Revealed |
|---------|----------------------|
| First-Time Setup | `import` command, `list` command, `.awsprofile` file creation |
| Daily Workflow | `use` command, `whoami` command, instant profile switching |
| Project Context Switch | `.awsprofile` detection, mismatch warning, switch prompt |
| Profile Management | `add` command, secure credential input, credential file writing |

## CLI Tool Specific Requirements

### Project-Type Overview

labs-aws-profiler is a command-line interface tool designed for terminal-native workflows. It operates in both interactive mode (prompts for credentials, switch confirmations) and scriptable mode (direct commands for automation).

### Command Structure

| Command | Arguments | Description |
|---------|-----------|-------------|
| `awsprof add <name>` | Profile name | Add new profile (prompts for credentials, region, output) |
| `awsprof edit <name>` | Profile name | Edit existing profile credentials and config defaults |
| `awsprof remove <name>` | Profile name | Delete a profile and its config defaults |
| `awsprof list` | None | Display all available profiles |
| `awsprof import` | None | Import profiles from existing `~/.aws/credentials` |
| `awsprof use <name>` | Profile name | Switch to profile (sets `AWS_PROFILE`) |
| `awsprof whoami` | None | Display currently active profile |
| `awsprof config set-region <name> <region>` | Profile name, region | Set default AWS region for a profile |
| `awsprof config set-output <name> <format>` | Profile name, output format | Set default AWS output format for a profile |
| `awsprof config show <name>` | Profile name | Show region/output for a profile |

### Output Formats

- **Plain text only** - Human-readable terminal output
- No JSON or structured output in MVP
- Clear, concise feedback messages:
  - Success: `Switched to profile: client-acme`
  - Warning: `⚠️ Profile mismatch: current 'personal', project expects 'client-acme'`
  - Error: `Error: Profile 'foo' not found`

### Config Schema

**Per-Project Configuration:**
- `.awsprofile` file in project root directory
- Contains single line: profile name (e.g., `client-acme`)
- Detected when user enters directory (via shell hook)

**Standard AWS Files (read/write):**
- `~/.aws/credentials` - Profile credentials storage
- `~/.aws/config` - Profile configuration (region, output format)

**No Global Tool Config:**
- No `~/.awsprofrc` or similar in MVP
- Tool behavior is consistent across all usage

**Config Defaults Behavior:**
- `awsprof add` and `awsprof edit` always prompt for region and output
- If the user submits a blank value, the corresponding config key is omitted (leave unset)
- Output format is validated to supported values (json, text, table)

### Scripting Support

- All commands exit with appropriate status codes (0 = success, non-zero = error)
- Commands work non-interactively when all required arguments provided
- `awsprof use <name>` can be called from scripts to set profile
- Output is parseable (single-line confirmations, no decorative elements)

### Implementation Considerations

**Shell Integration:**
- Profile switching requires shell function/alias (cannot export env vars from subprocess)
- Suggest wrapper: `awsprof() { eval "$(command awsprof "$@")"; }`
- Or shell-specific initialization in `.bashrc`/`.zshrc`

**Credential Handling:**
- Prompt for credentials with hidden input (no echo)
- Never log or display secret access keys
- Write directly to `~/.aws/credentials` in INI format

### Future Considerations (v2)

- Shell completion for profile names
- JSON output format option (`--json` flag)
- Global configuration file if needed

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**MVP Approach:** Problem-Solving MVP
- Minimum feature set that eliminates the core pain point
- Focus on reliability over features
- Ship when it works, not when it's complete

**Resource Requirements:** Solo developer project
- Single developer can build and maintain
- No external dependencies beyond standard libraries
- No infrastructure required (local CLI tool)

### MVP Feature Set (Phase 1)

**Core User Journeys Supported:**
- First-Time Setup (import existing profiles)
- Daily Workflow (profile switching)
- Project Context Switch (mismatch warnings)
- Profile Management (add new profiles)

**Must-Have Capabilities:**

| Capability | Rationale |
|------------|-----------|
| `awsprof add` | Create new profiles (credentials + config defaults) |
| `awsprof edit` | Modify existing credentials and config defaults |
| `awsprof remove` | Clean up unused profiles and config defaults |
| `awsprof list` | See all available profiles |
| `awsprof import` | Onboard existing AWS users |
| `awsprof use` | Core switching functionality |
| `awsprof whoami` | Visibility into current state |
| `.awsprofile` detection | Project-profile linking |
| Mismatch warning | Safety net (non-intrusive) |
| `awsprof config set-region` | Set default region per profile |
| `awsprof config set-output` | Set default output per profile |
| `awsprof config show` | View region/output defaults |

**Shell Integration Philosophy:**
- Warn on mismatch, don't block
- Prompt to switch, don't auto-switch
- Silent when profile matches (no noise)
- User remains in control at all times

### Post-MVP Features

**Phase 2 (v2):**
- Shell completion for profile names
- JSON output format (`--json` flag)
- Global configuration file (if usage patterns reveal need)

**Phase 3 (Future):**
- Driven by actual usage needs
- No speculative roadmap

### Risk Mitigation Strategy

**Technical Risks:** Low
- AWS credential file format is stable and well-documented
- Shell integration patterns are established (similar to nvm, rbenv)
- No external API dependencies

**Market Risks:** N/A
- Personal utility, no market validation needed
- Success = works for the author

**Resource Risks:** Minimal
- Solo project with clear scope
- Can ship incrementally (commands can be added one at a time)
- No deadline pressure

## Functional Requirements

### Profile Management

- FR1: User can add a new AWS profile by providing a name, access key ID, secret access key, region, and output format
- FR2: User can edit an existing profile's credentials and config defaults (access key ID, secret access key, region, output)
- FR3: User can remove an existing profile from the system (credentials and config)
- FR4: User can view a list of all configured AWS profiles
- FR5: System stores profile credentials in standard `~/.aws/credentials` format
- FR6: System preserves existing profiles when adding or editing (no data loss)

### Profile Import

- FR7: User can import all existing profiles from `~/.aws/credentials` file
- FR8: System detects and lists all profiles found during import
- FR9: System preserves original credential file structure during import

### Profile Switching

- FR10: User can switch to any configured profile by name
- FR11: System sets `AWS_PROFILE` environment variable when switching profiles
- FR12: System confirms successful profile switch with feedback message
- FR13: System reports error when user attempts to switch to non-existent profile

### Current Profile Status

- FR14: User can query the currently active profile
- FR15: System displays the current `AWS_PROFILE` value (or indicates none set)

### Project-Profile Linking

- FR16: User can create a `.awsprofile` file in a project directory containing a profile name
- FR17: System detects `.awsprofile` file when user enters a directory
- FR18: System compares current profile against project's expected profile
- FR19: System displays warning when current profile differs from project's expected profile
- FR20: System prompts user to switch profiles when mismatch is detected
- FR21: User can accept or decline the profile switch prompt
- FR22: System remains silent when current profile matches project expectation

### Shell Integration

- FR23: System provides shell initialization script for bash
- FR24: System provides shell initialization script for sh
- FR25: Shell integration enables automatic `.awsprofile` detection on directory change
- FR26: System outputs commands suitable for shell eval (enabling env var export)

### Error Handling

- FR27: System exits with status code 0 on successful operations
- FR28: System exits with non-zero status code on failures
- FR29: System displays clear error messages for invalid operations
- FR30: System validates profile name exists before switching
- FR31: System validates credential format before saving

### Credential Security

- FR32: System prompts for credentials with hidden input (no terminal echo)
- FR33: System never displays secret access keys in output
- FR34: System writes credentials directly to file (no intermediate storage)

### AWS Config Support

- FR40: User can set a default AWS region for a profile (writes to `~/.aws/config`)
- FR41: User can set a default AWS output format for a profile (writes to `~/.aws/config`)
- FR42: User can view the current region/output for a profile (reads from `~/.aws/config`)
- FR43: System preserves existing config entries when adding or editing config settings

## Non-Functional Requirements

### Performance

- NFR1: All commands complete within 100ms under normal operation
- NFR2: Profile listing displays immediately regardless of number of profiles (up to 100+)
- NFR3: Shell hook detection adds no perceptible delay to directory changes
- NFR4: Credential file read/write operations complete atomically

### Security

- NFR5: Credential input is hidden (no terminal echo during password/secret entry)
- NFR6: Secret access keys are never displayed in command output
- NFR7: Secret access keys are never written to log files or command history
- NFR8: Credential files maintain standard AWS permission model (user-only read/write)
- NFR9: No credentials transmitted over network (local file operations only)

### Reliability

- NFR10: Credential file operations are atomic (no partial writes on failure)
- NFR11: System creates backup before modifying existing credential files
- NFR12: System gracefully handles malformed credential files without data loss
- NFR13: Shell integration failures do not break normal shell operation

### Integration

- NFR14: Full compatibility with AWS CLI credential file format (INI)
- NFR15: Full compatibility with AWS CLI config file format
- NFR16: Profile switching works with all tools that respect `AWS_PROFILE` env var
- NFR17: Shell integration works with bash 4.0+ and POSIX sh
