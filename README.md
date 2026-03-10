# awsprof

A CLI for managing and switching AWS profiles.

## Overview

`awsprof` provides a simple terminal workflow for switching between AWS profiles. It keeps credentials in standard AWS locations and adds project-aware profile checks.

## Problem Statement

Developers often switch between personal, team, and client AWS accounts in the same shell session. Manual profile handling is error-prone and can lead to running commands in the wrong account. `awsprof` standardizes profile management and switching in one consistent CLI flow.

## Concepts Used with the Implementation

- **Native AWS conventions**: Uses `~/.aws/credentials`, `~/.aws/config`, and `AWS_PROFILE`.
- **Shell integration**: `eval "$(awsprof init)"` applies profile changes to the current shell.
- **Project-aware checks**: `.awsprofile` sets expected profiles per directory.
- **Safe updates**: Creates backups before changing credential files.
- **Script-friendly output**: Keeps output parseable for shell usage.

## Installation

Install the latest version:

```bash
curl -fsSL https://raw.githubusercontent.com/kugtong33/labs-aws-profiler/refs/heads/main/install.sh | bash
```

If your terminal does not support ANSI colors:

```bash
curl -fsSL https://raw.githubusercontent.com/kugtong33/labs-aws-profiler/refs/heads/main/install.sh | bash -s -- --no-color
```

Then initialize shell integration:

```bash
eval "$(awsprof init)"
```

## Basic Usage

```bash
# Import existing profiles from ~/.aws/credentials
awsprof import

# List available profiles
awsprof list

# Switch to a profile
awsprof use my-profile

# Show active profile
awsprof whoami

# Check expected project profile (if .awsprofile exists)
awsprof check
```
