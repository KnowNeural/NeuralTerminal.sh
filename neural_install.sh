#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GITHUB_RAW_URL="https://raw.githubusercontent.com/KnowNeural/NeuralTerminal.sh/refs/heads/main/neural_terminal.sh"
SCRIPT_NAME="neural_terminal.sh"
LOCAL_DIR="$HOME/.local/bin/market-monitor"

# Function to detect OS
get_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# Function to install package manager if needed (for macOS)
install_package_manager() {
    local os=$1
    if [[ "$os" == "macos" ]] && ! command -v brew >/dev/null 2>&1; then
        echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Function to install dependencies
install_dependencies() {
    local os=$1
    local missing_deps=()
    
    # Check which dependencies are missing
    for cmd in curl jq bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # If no missing dependencies, return
    if [ ${#missing_deps[@]} -eq 0 ]; then
        return
    fi
    
    echo -e "${YELLOW}Installing missing dependencies: ${missing_deps[*]}${NC}"
    
    case $os in
        "ubuntu"|"debian"|"pop"|"linuxmint")
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
            ;;
        "fedora"|"rhel"|"centos")
            sudo dnf install -y "${missing_deps[@]}"
            ;;
        "arch"|"manjaro")
            sudo pacman -Sy --noconfirm "${missing_deps[@]}"
            ;;
        "macos")
            install_package_manager "$os"
            brew install "${missing_deps[@]}"
            ;;
        *)
            echo -e "${RED}Unsupported operating system for automatic installation${NC}"
            echo "Please install the following dependencies manually: ${missing_deps[*]}"
            exit 1
            ;;
    esac
}

# Function to check if all required commands exist
check_dependencies() {
    local os
    os=$(get_os)
    
    echo -e "${GREEN}Detected OS: $os${NC}"
    install_dependencies "$os"
    
    # Verify all dependencies are now installed
    local missing_deps=()
    for cmd in curl jq bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Failed to install required dependencies: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

# Function to create directory and download script
setup_script() {
    mkdir -p "$LOCAL_DIR"
    
    echo "Downloading market monitor script..."
    if curl -s "$GITHUB_RAW_URL" -o "$LOCAL_DIR/$SCRIPT_NAME"; then
        chmod +x "$LOCAL_DIR/$SCRIPT_NAME"
        echo -e "${GREEN}Successfully downloaded market monitor script${NC}"
    else
        echo -e "${RED}Failed to download script${NC}"
        exit 1
    fi
}

# Function to update existing script
update_script() {
    echo "Checking for updates..."
    if curl -s "$GITHUB_RAW_URL" -o "$LOCAL_DIR/$SCRIPT_NAME.tmp"; then
        if ! diff -q "$LOCAL_DIR/$SCRIPT_NAME" "$LOCAL_DIR/$SCRIPT_NAME.tmp" >/dev/null 2>&1; then
            mv "$LOCAL_DIR/$SCRIPT_NAME.tmp" "$LOCAL_DIR/$SCRIPT_NAME"
            chmod +x "$LOCAL_DIR/$SCRIPT_NAME"
            echo -e "${GREEN}Script updated successfully${NC}"
        else
            echo -e "${GREEN}Script is already up to date${NC}"
            rm "$LOCAL_DIR/$SCRIPT_NAME.tmp"
        fi
    else
        echo -e "${RED}Failed to check for updates${NC}"
        rm -f "$LOCAL_DIR/$SCRIPT_NAME.tmp"
    fi
}

# Main execution
main() {
    # Check and install dependencies
    check_dependencies
    
    # Create or update script
    if [ ! -f "$LOCAL_DIR/$SCRIPT_NAME" ]; then
        setup_script
    else
        update_script
    fi
    
    # Run the script with any provided arguments
    echo "Starting market monitor..."
    exec "$LOCAL_DIR/$SCRIPT_NAME" "$@"
}

# Run main function with all arguments passed to the script
main "$@"
