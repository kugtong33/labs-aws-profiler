#!/bin/bash
#
# awsprof - AWS Profile Management Tool
# Installation script for curl | bash distribution
#
# Version: 0.1.0 (First Release)
#
# Installation command:
#   curl -fsSL https://raw.githubusercontent.com/ubuntu/labs-aws-profiler/0.1.0/install.sh | bash
#
# This script:
# 1. Downloads awsprof to ~/.local/bin/
# 2. Makes it executable
# 3. Adds shell integration to ~/.bashrc
# 4. Verifies installation

set -euo pipefail

# Version information
readonly VERSION="0.1.0"
readonly RELEASE_TAG="0.1.0"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Installation paths
readonly INSTALL_DIR="${HOME}/.local/bin"
readonly INSTALL_FILE="${INSTALL_DIR}/awsprof"
readonly BASHRC="${HOME}/.bashrc"
readonly BASHRC_BACKUP="${HOME}/.bashrc.backup.$(date +%s)"

# GitHub URLs
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/ubuntu/labs-aws-profiler/${RELEASE_TAG}"
readonly AWSPROF_URL="${GITHUB_RAW_URL}/awsprof"

# Helper functions
print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    if ! command_exists curl; then
        print_error "curl is required but not installed"
        exit 1
    fi
    print_success "curl is available"

    if ! command_exists bash; then
        print_error "bash is required but not installed"
        exit 1
    fi
    print_success "bash is available"
}

# Create installation directory
create_install_dir() {
    print_header "Preparing Installation Directory"

    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Created $INSTALL_DIR"
    else
        print_success "$INSTALL_DIR already exists"
    fi

    # Verify directory is writable
    if [[ ! -w "$INSTALL_DIR" ]]; then
        print_error "$INSTALL_DIR is not writable"
        exit 1
    fi
}

# Download awsprof
download_awsprof() {
    print_header "Downloading awsprof"

    # Check if we're in a local git repo first (for local development/testing)
    if [[ -f "$(dirname "$0")/awsprof" ]]; then
        print_info "Found local awsprof, using local version for installation"
        cp "$(dirname "$0")/awsprof" "$INSTALL_FILE"
        print_success "Copied awsprof to $INSTALL_FILE"
    else
        # Download from GitHub
        print_info "Downloading from $AWSPROF_URL"
        if curl -fsSL "$AWSPROF_URL" -o "$INSTALL_FILE"; then
            print_success "Downloaded awsprof"
        else
            print_error "Failed to download awsprof"
            exit 1
        fi
    fi
}

# Make awsprof executable
make_executable() {
    print_header "Setting Permissions"

    if chmod +x "$INSTALL_FILE"; then
        print_success "Made awsprof executable"
    else
        print_error "Failed to make awsprof executable"
        exit 1
    fi

    # Verify it's executable
    if [[ -x "$INSTALL_FILE" ]]; then
        print_success "Verified awsprof is executable"
    else
        print_error "Failed to verify executable permission"
        exit 1
    fi
}

# Add shell integration
add_shell_integration() {
    print_header "Adding Shell Integration"

    # Check if already added
    if grep -q "eval \"\$(awsprof init)\"" "$BASHRC" 2>/dev/null; then
        print_info "Shell integration already present in $BASHRC"
        return 0
    fi

    # Backup bashrc
    if [[ -f "$BASHRC" ]]; then
        cp "$BASHRC" "$BASHRC_BACKUP"
        print_success "Created backup: $BASHRC_BACKUP"
    fi

    # Add shell integration
    {
        echo ""
        echo "# awsprof shell integration"
        echo "eval \"\$(awsprof init)\""
    } >> "$BASHRC"

    print_success "Added shell integration to $BASHRC"
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    # Check if file exists
    if [[ ! -f "$INSTALL_FILE" ]]; then
        print_error "Installation file not found: $INSTALL_FILE"
        exit 1
    fi
    print_success "Installation file exists"

    # Check if executable
    if [[ ! -x "$INSTALL_FILE" ]]; then
        print_error "Installation file is not executable"
        exit 1
    fi
    print_success "Installation file is executable"

    # Try to run awsprof help
    if "$INSTALL_FILE" help >/dev/null 2>&1; then
        print_success "awsprof help command works"
    else
        print_warning "awsprof help command returned an error (this might be normal)"
    fi

    # Check if shell integration was added
    if grep -q "eval \"\$(awsprof init)\"" "$BASHRC" 2>/dev/null; then
        print_success "Shell integration verified in $BASHRC"
    else
        print_warning "Shell integration not found in $BASHRC"
    fi
}

# Main installation flow
main() {
    print_header "awsprof Installation v${VERSION}"
    print_info "Installation destination: $INSTALL_FILE"
    echo ""

    check_prerequisites
    echo ""

    create_install_dir
    echo ""

    download_awsprof
    echo ""

    make_executable
    echo ""

    add_shell_integration
    echo ""

    verify_installation
    echo ""

    print_header "Installation Complete!"
    echo ""
    print_success "awsprof has been installed successfully"
    echo ""
    echo "Next steps:"
    echo "1. Reload your shell to enable awsprof:"
    echo "   ${BLUE}source ~/.bashrc${NC}"
    echo ""
    echo "2. Verify installation:"
    echo "   ${BLUE}awsprof help${NC}"
    echo ""
    echo "3. Check your AWS profiles:"
    echo "   ${BLUE}awsprof list${NC}"
    echo ""
}

# Run main installation
main "$@"
