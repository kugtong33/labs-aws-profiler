---
stepsCompleted: [1, 2, 3, 4, 5]
inputDocuments: []
date: 2026-01-22
author: Ubuntu
---

# Product Brief: labs-aws-profiler

## Executive Summary

labs-aws-profiler is a lightweight, standalone CLI tool for managing and switching between AWS profiles. It provides simple CRUD operations for AWS credentials while leveraging the native AWS configuration format and environment variables, ensuring compatibility with the broader AWS ecosystem and third-party tools.

---

## Core Vision

### Problem Statement

Developers and engineers working across multiple AWS accounts (personal, work, client projects) struggle with context-switching between profiles. The current workflow involves manually editing `~/.aws/credentials` and `~/.aws/config` files, running `aws configure` repeatedly, or maintaining project-specific bash scripts to load the correct credentials.

### Problem Impact

- **Operational risk:** Forgetting to load the correct profile leads to commands executing against the wrong AWS account
- **Time waste:** Manual credential file editing and script maintenance adds friction to daily workflows
- **Cognitive load:** Remembering which profile belongs to which project across multiple clients and contexts

### Why Existing Solutions Fall Short

- **aws-vault:** Focused on credential security and MFA, adds complexity beyond simple profile switching
- **granted:** Browser-based SSO focus, overkill for straightforward access key management
- **Manual scripts:** Error-prone, easy to forget, no warnings or safety nets

### Proposed Solution

A CLI tool that provides:
- **Add/Edit/Remove** AWS profiles with their access keys and secrets
- **Switch** profiles by setting the `AWS_PROFILE` environment variable for the current terminal session
- **List** all configured profiles and show the currently active one
- **Project-profile linking** with warnings when working in a directory linked to a different profile than currently active
- **Standard storage** using native `~/.aws/credentials` and `~/.aws/config` formats

### Key Differentiators

1. **Simplicity first** - No unnecessary features, just profile CRUD and switching
2. **Ecosystem compliance** - Uses native AWS credential storage and `AWS_PROFILE` for third-party compatibility
3. **Safety without friction** - Warns about profile mismatches but respects user autonomy (no forced auto-switching)
4. **CLI-native** - Pure terminal workflow, no GUI or browser dependencies

---

## Target Users

### Primary Users

**Infrastructure Developer ("Alex")**

- **Role:** Solo developer or team lead working on AWS cloud infrastructure
- **Environment:** Terminal-heavy workflow, frequently using IaC tools (Terraform, Pulumi, AWS CDK, CloudFormation) alongside ad-hoc AWS CLI commands
- **Context:** Manages multiple AWS accounts - personal projects, work environments, client sandboxes - and needs to switch between them during active development sessions

**Problem Experience:**
- Juggles 3-10+ AWS profiles across different projects and clients
- Currently relies on manual credential file editing or project-specific bash scripts
- Frequently forgets to switch profiles, risking commands against wrong accounts
- Debugging sessions often require rapid switching between accounts (e.g., comparing staging vs production, or client A vs client B)

**Success Vision:**
- Seamless profile switching without leaving the terminal flow
- Clear visibility into which profile is currently active
- Warnings when working in a project directory linked to a different profile
- Zero friction added to existing IaC and AWS CLI workflows

### Secondary Users

N/A - This is a single-user tool with no team or sharing dimensions.

### User Journey

1. **Discovery:** Developer finds tool while searching for AWS profile management solutions, or via recommendation from another infrastructure developer
2. **Onboarding:** Installs CLI, runs `awsprof add` to register existing profiles with their keys
3. **Core Usage:** Uses `awsprof use <profile>` to switch contexts, `awsprof list` to see available profiles, `awsprof current` to confirm active profile
4. **Success Moment:** First time they catch themselves about to run a command against the wrong account - the profile mismatch warning saves them
5. **Long-term:** Tool becomes invisible infrastructure - profile switching is now muscle memory, project-profile links provide safety net

---

## Success Metrics

### User Success Metrics

**Core Functionality:**
- Profile switching works correctly and reliably sets `AWS_PROFILE` environment variable
- Current profile is always visible and queryable
- Profile CRUD operations (add/edit/remove) work without data loss or corruption
- Standard AWS credential files remain compatible with other AWS tools

**Workflow Integration:**
- Project-profile linking via config file in project directories
- Profile mismatch warnings trigger when in a tagged project with a different active profile
- Prompted to switch profiles when entering a tagged project directory

**Personal Success Criteria:**
- Replaces manual credential file editing and per-project bash scripts
- Prevents wrong-account mistakes through mismatch warnings
- Zero friction added to existing terminal workflow

### Business Objectives

N/A - Personal open-source utility. No commercial or adoption goals.

### Key Performance Indicators

| Indicator | Target |
|-----------|--------|
| Profile switch reliability | 100% |
| Credential file compatibility | Full AWS standard compatibility |
| Command response time | Instantaneous |

---

## MVP Scope

### Core Features

**Profile Management:**
- `awsprof add <name>` - Add a new profile with access key and secret
- `awsprof edit <name>` - Edit an existing profile's credentials
- `awsprof remove <name>` - Delete a profile
- `awsprof list` - Show all available profiles
- `awsprof import` - Import existing profiles from `~/.aws/credentials`

**Profile Switching:**
- `awsprof use <name>` - Switch to a profile (sets `AWS_PROFILE` env var)
- `awsprof whoami` - Show currently active profile

**Project-Profile Linking:**
- `.awsprofile` file in project directory containing profile name
- Mismatch warning when current profile differs from project's linked profile
- Prompt to switch when entering a linked project directory

**Storage:**
- Read/write to standard `~/.aws/credentials` and `~/.aws/config` files
- Full compatibility with AWS CLI and other AWS tools

### Out of Scope for MVP

- MFA/TOTP support
- SSO/IAM Identity Center integration
- Shell prompt integration (PS1 modifications)
- Credential rotation or expiry management
- GUI or TUI interfaces

### MVP Success Criteria

- All CRUD operations work reliably without data corruption
- Profile switching correctly sets `AWS_PROFILE` for current terminal session
- Project-profile warnings trigger correctly when mismatched
- Existing `~/.aws/credentials` files import without issues

### Future Vision

N/A - Focus is on building a working personal utility. Future enhancements will be driven by actual usage needs, not speculative roadmaps.
