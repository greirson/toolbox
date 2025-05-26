# Mac Setup - Homebrew App Installer

Automated Homebrew app installation script with parallel processing, automatic package type detection, and progress tracking.

## Features

- 🚀 Parallel installation (up to 4 apps simultaneously)
- 🔍 Automatic detection of cask vs formula packages
- 📝 Updates apps.txt with package types automatically
- ⏭️ Skips already installed packages
- 🔄 Retry logic for failed installations
- 📊 Progress tracking with [current/total] indicator
- 🧪 Dry-run mode for testing
- 🧹 Automatic cleanup after completion

## Quick Start (Remote Execution)

Run directly without cloning the repository:

```bash
curl -fsSL https://raw.githubusercontent.com/greirson/toolbox/main/process/mac_setup/install-apps.sh | bash -s -- && \
curl -fsSL https://raw.githubusercontent.com/greirson/toolbox/main/process/mac_setup/apps.txt -o apps.txt && \
bash install-apps.sh
```

## Local Usage

```bash
# Basic installation
./install-apps.sh

# Dry run (see what would be installed)
./install-apps.sh --dry-run

# Custom parallel installations
./install-apps.sh --parallel 8

# Show help
./install-apps.sh --help
```

## Apps List Format

The `apps.txt` file supports two formats:

```
# Simple format (type will be auto-detected)
firefox
node

# With type specified (faster)
firefox:cask
node:formula
```

The script automatically updates apps.txt with detected types for faster future runs.

## Options

- `--dry-run`: Show what would be installed without actually installing
- `--parallel N`: Set number of parallel installations (default: 4)
- `--help`: Display help message

## Requirements

- macOS
- Internet connection
- Admin privileges (for some casks)

## Logs

Installation logs are saved to `install.log` in the same directory, including:
- Timestamp for each operation
- Success/failure status for each app
- Detailed error messages

## How It Works

1. Checks/installs Homebrew
2. Updates Homebrew
3. Reads apps.txt and detects package types
4. Updates apps.txt with types (if not specified)
5. Installs apps in parallel batches
6. Runs cleanup after completion