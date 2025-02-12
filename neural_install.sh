#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

GITHUB_RAW_URL="https://raw.githubusercontent.com/KnowNeural/NeuralTerminal.sh/refs/heads/main/neural_terminal.sh"
SCRIPT_NAME="neural_terminal.sh"

get_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

install_package_manager() {
    local os=$1
    if [[ "$os" == "macos" ]] && ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_dependencies() {
    local os=$1
    local missing_deps=()
    
    for cmd in curl jq bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
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

check_dependencies() {
    local os
    os=$(get_os)
    
    echo -e "${GREEN}Detected OS: $os${NC}"
    install_dependencies "$os"
    
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

setup_script() {
    if curl -s "$GITHUB_RAW_URL" -o "$SCRIPT_NAME"; then
        chmod +x "$SCRIPT_NAME"
        echo -e "${GREEN}Successfully downloaded market monitor script${NC}"
    else
        echo -e "${RED}Failed to download script${NC}"
        exit 1
    fi
}

update_script() {
    if curl -s "$GITHUB_RAW_URL" -o "$SCRIPT_NAME.tmp"; then
        if ! diff -q "$SCRIPT_NAME" "$SCRIPT_NAME.tmp" >/dev/null 2>&1; then
            mv "$SCRIPT_NAME.tmp" "$SCRIPT_NAME"
            chmod +x "$SCRIPT_NAME"
            echo -e "${GREEN}Script updated successfully${NC}"
        else
            echo -e "${GREEN}Script is already up to date${NC}"
            rm "$SCRIPT_NAME.tmp"
        fi
    else
        echo -e "${RED}Failed to check for updates${NC}"
        rm -f "$SCRIPT_NAME.tmp"
    fi
}

main() {
    check_dependencies
    
    if [ ! -f "$SCRIPT_NAME" ]; then
        setup_script
    else
        update_script
    fi
    
    exec "./$SCRIPT_NAME" "$@"
}

main "$@"
