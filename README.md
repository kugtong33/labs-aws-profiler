# awsprof

A lightweight, standalone CLI tool for managing and switching between AWS profiles.

## Overview

`awsprof` simplifies working with multiple AWS accounts by providing fast profile switching with project-aware safety warnings. It's designed for developers who work across multiple AWS environments (personal, work, client projects) and need a simple, reliable way to manage their credentials.

### Why awsprof?

- **Simplicity first** - No unnecessary features, just profile management and switching
- **Ecosystem compliance** - Uses native `~/.aws/credentials` storage and `AWS_PROFILE` environment variable
- **Safety without friction** - Warns about profile mismatches but respects user autonomy
- **CLI-native** - Pure terminal workflow, no GUI or browser dependencies
- **Fast** - Instantaneous command response (<100ms)

### Key Features

- **Profile Management**: Add, edit, remove, list, and import AWS profiles
- **Quick Switching**: Switch profiles instantly by setting the `AWS_PROFILE` environment variable
- **Project-Profile Linking**: Link projects to specific profiles with automatic mismatch warnings
- **Standard Storage**: Uses native `~/.aws/credentials` and `~/.aws/config` formats
- **Shell Integration**: Works seamlessly with bash and POSIX sh shells
- **Safe Operations**: Automatic backups before modifying credential files

## Installation

### Quick Install (Recommended)

Install via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/kugtong33/labs-aws-profiler/refs/tags/0.1.0/install.sh | bash
```

This will:
1. Download `awsprof` to `~/.local/bin/`
2. Make it executable
3. Add shell integration to `~/.bashrc`
4. Verify the installation

### Manual Installation

1. Download the `awsprof` script:
```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/kugtong33/labs-aws-profiler/refs/tags/0.1.0/awsprof -o ~/.local/bin/awsprof
chmod +x ~/.local/bin/awsprof
```

2. Add shell integration to your `~/.bashrc`:
```bash
eval "$(awsprof init)"
```

3. Reload your shell:
```bash
source ~/.bashrc
```

### POSIX sh Support

For POSIX sh shells, use the `--sh` flag:
```sh
eval "`awsprof init --sh`"
```

Note: Automatic profile detection is not available in POSIX sh (no shell hooks available). Use `awsprof check` to manually verify profiles.

## Quick Start

1. **Import existing profiles**:
```bash
awsprof import
```

2. **List available profiles**:
```bash
awsprof list
```

3. **Switch to a profile**:
```bash
awsprof use my-profile
```

4. **Check current profile**:
```bash
awsprof whoami
```

## Usage

### Profile Management

#### Add a new profile
```bash
awsprof add work-production
```
You'll be prompted for your AWS Access Key ID and Secret Access Key.

#### Edit an existing profile
```bash
awsprof edit work-production
```

#### Remove a profile
```bash
awsprof remove old-client
```

#### List all profiles
```bash
awsprof list
```

#### Import existing profiles
```bash
awsprof import
```
This scans your `~/.aws/credentials` file and makes all profiles available to `awsprof`.

### Profile Switching

#### Switch to a profile
```bash
awsprof use personal
```
This sets the `AWS_PROFILE` environment variable for your current terminal session.

#### Check current profile
```bash
awsprof whoami
```
Shows which profile is currently active (or "No profile set (using default)").

### Project-Profile Linking

Link a project directory to a specific AWS profile by creating a `.awsprofile` file:

1. **Create a `.awsprofile` file** in your project directory:
```bash
echo "client-acme" > .awsprofile
```

2. **Automatic detection**: When you `cd` into this directory, `awsprof` will:
   - Detect if you're using a different profile
   - Warn you about the mismatch
   - Prompt you to switch (optional)

Example:
```bash
$ cd ~/projects/client-acme
⚠️  Profile mismatch: current 'personal', project expects 'client-acme'
```

The `.awsprofile` file is safe to commit to version control since it only contains the profile name, not credentials.

## Commands Reference

| Command | Description |
|---------|-------------|
| `awsprof list` | List all available AWS profiles |
| `awsprof use <profile>` | Switch to a specific profile |
| `awsprof whoami` | Show currently active profile |
| `awsprof add <profile>` | Add a new AWS profile |
| `awsprof edit <profile>` | Edit an existing AWS profile |
| `awsprof remove <profile>` | Remove an AWS profile |
| `awsprof import` | Import profiles from credentials file |
| `awsprof check` | Check `.awsprofile` file in current directory |
| `awsprof init` | Initialize shell integration (use with eval) |
| `awsprof help` | Show help message |

## How It Works

### Shell Integration

When you run `eval "$(awsprof init)"`, awsprof adds:

1. **A wrapper function** that intercepts `awsprof use` commands and evaluates their output to set environment variables
2. **A PROMPT_COMMAND hook** that checks for `.awsprofile` files when you change directories
3. **Profile detection** that warns you when there's a mismatch

### Environment Variables

`awsprof` uses the standard `AWS_PROFILE` environment variable that's recognized by:
- AWS CLI
- AWS SDKs (boto3, aws-sdk-js, etc.)
- Infrastructure as Code tools (Terraform, Pulumi, CDK, CloudFormation)
- Other AWS tools and third-party applications

### File Storage

Credentials are stored in `~/.aws/credentials` using the standard INI format:
```ini
[profile-name]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

`awsprof` automatically creates timestamped backups (`.bak.YYYYMMDD-HHMMSS`) before modifying this file.

## Requirements

- **Operating System**: Linux
- **Shell**: bash or POSIX sh
- **Dependencies**:
  - `bash` (v4.0+)
  - `curl` (for installation)
  - `awk` (for INI file parsing)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_SHARED_CREDENTIALS_FILE` | `~/.aws/credentials` | Path to AWS credentials file |
| `AWS_CONFIG_FILE` | `~/.aws/config` | Path to AWS config file |
| `AWSPROF_EMOJI` | `0` | Enable/disable emoji in output |

## Security

- Credentials are stored in `~/.aws/credentials` with `600` permissions (user read/write only)
- `awsprof` validates AWS Access Key ID and Secret Access Key formats before accepting them
- Backup files are created with the same restrictive permissions
- The `.awsprofile` file only contains profile names, never credentials

## Troubleshooting

### awsprof command not found

Ensure `~/.local/bin` is in your PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Profile switching doesn't persist

Make sure you've initialized shell integration:
```bash
eval "$(awsprof init)"
```

Add this to your `~/.bashrc` to make it permanent.

### Shell integration not working

Verify the integration is loaded:
```bash
type awsprof
```

Should show: `awsprof is a function`

If not, reload your shell:
```bash
source ~/.bashrc
```

### Mismatch warnings not appearing

The PROMPT_COMMAND hook is only available in bash. For POSIX sh, manually check:
```bash
awsprof check
```

## Comparison with Other Tools

| Feature | awsprof | aws-vault | granted |
|---------|---------|-----------|---------|
| Simple profile switching | ✅ | ✅ | ✅ |
| Native AWS credentials format | ✅ | ❌ | ❌ |
| MFA/TOTP support | ❌ | ✅ | ✅ |
| SSO support | ❌ | ❌ | ✅ |
| Project-profile linking | ✅ | ❌ | ❌ |
| CLI-only (no browser) | ✅ | ✅ | ❌ |
| Complexity | Low | Medium | Medium |

**Use awsprof if**: You need simple profile management with project linking and want to stick with native AWS credential files.

**Use aws-vault if**: You need MFA/TOTP support and credential encryption.

**Use granted if**: You primarily use AWS SSO/IAM Identity Center.

## Contributing

Contributions are welcome! This is a personal utility that's been open-sourced. Feel free to:
- Report bugs via GitHub Issues
- Submit pull requests for bug fixes or improvements
- Suggest new features (though the focus is on simplicity)

## License

MIT License - See LICENSE file for details

## Credits

Created by Ubuntu for managing multiple AWS profiles across infrastructure projects.

## Version

Current version: 1.0.0

## Links

- GitHub Repository: https://github.com/ubuntu/labs-aws-profiler
- Installation Script: https://raw.githubusercontent.com/kugtong33/labs-aws-profiler/refs/tags/0.1.0/install.sh
- Report Issues: https://github.com/ubuntu/labs-aws-profiler/issues
