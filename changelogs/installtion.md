# Razen Programming Language Installation Guide

> **IMPORTANT**: Razen now uses a single unified installer (`installer.sh`) that works across all supported operating systems. There is no need to download separate OS-specific installers anymore.

## Overview

This document provides comprehensive instructions for creating a universal installation script for the Razen programming language that works across all major operating systems (Linux, macOS, and Windows). The installation process ensures that all necessary components are properly set up, dependencies are installed, and the environment is configured correctly.

## How to Use the Universal Installer

1. Download the `installer.sh` script from the official Razen website or repository
2. Make it executable: `chmod +x installer.sh` (for Linux/macOS)
3. Run it:
   - Linux/macOS: `./installer.sh`
   - Windows: Run through Git Bash with `./installer.sh`

> **Note for Windows users**: The universal installer requires Git Bash or WSL (Windows Subsystem for Linux) to run. You can download Git Bash from [https://git-scm.com/downloads](https://git-scm.com/downloads).

## Universal Installation Components

The unified installer script includes these core components to work across all supported operating systems:

### 1. Script Setup and Environment

```bash
#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Colors for terminal output (for better user experience)
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Repository URLs
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"
RAZEN_GIT_REPO="https://github.com/BasaiCorp/razen-lang.git"

# Detect OS and set installation directories
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Set installation paths based on OS
if [[ "$OS" == "linux" ]]; then
    INSTALL_DIR="/usr/local/lib/razen"
    BIN_DIR="/usr/local/bin"
elif [[ "$OS" == "macos" ]]; then
    INSTALL_DIR="/usr/local/lib/razen"
    BIN_DIR="/usr/local/bin"
elif [[ "$OS" == "windows" ]]; then
    INSTALL_DIR="$PROGRAMFILES/Razen"
    if [[ -z "$PROGRAMFILES" ]]; then
        INSTALL_DIR="C:/Program Files/Razen"
    fi
    BIN_DIR="$INSTALL_DIR/bin"
    mkdir -p "$BIN_DIR" 2>/dev/null || true
fi

# Temporary directory for downloads
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
```

### 2. Utility Functions

```bash
# Check for internet connectivity
check_internet() {
    echo -e "${YELLOW}Checking internet connectivity...${NC}"
    if ! ping -c 1 github.com &>/dev/null && ! ping -c 1 google.com &>/dev/null; then
        echo -e "${RED}Error: No internet connection detected.${NC}"
        echo -e "${YELLOW}Please check your network connection and try again.${NC}"
        return 1
    fi
    echo -e "  ${GREEN}✓${NC} Internet connection detected"
    return 0
}

# Check for sudo/root privileges
check_permissions() {
    echo -e "${YELLOW}Checking for required permissions...${NC}"
    if [ "$EUID" -eq 0 ]; then
        # Already running as root
        echo -e "  ${GREEN}✓${NC} Running with root privileges"
        return 0
    fi

    # Test sudo access
    if ! sudo -v &>/dev/null; then
        echo -e "${RED}Error: This script requires sudo privileges to install system-wide.${NC}"
        echo -e "${YELLOW}Please run with sudo or as root.${NC}"
        return 1
    fi

    echo -e "  ${GREEN}✓${NC} Sudo access confirmed"
    return 0
}

# Error handling function
handle_error() {
    local exit_code=$1
    local error_message=$2
    local recovery_hint=$3

    echo -e "${RED}Error: $error_message (Exit code: $exit_code)${NC}"

    if [ -n "$recovery_hint" ]; then
        echo -e "${YELLOW}Hint: $recovery_hint${NC}"
    fi

    if [ -d "$TMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TMP_DIR"
    fi

    exit $exit_code
}

# Get version from the version file
if [ -f "version" ]; then
    RAZEN_VERSION=$(cat version)
else
    # Download version file if not present
    if ! curl -s -o version "$RAZEN_REPO/version" &>/dev/null; then
        echo -e "${RED}Failed to download version information. Using default version.${NC}"
        RAZEN_VERSION="beta v0.1.7 - (Tokens Update)"
    else
        RAZEN_VERSION=$(cat version)
        # Store the version file for future reference
        echo -e "  ${GREEN}✓${NC} Downloaded version information: $RAZEN_VERSION"
    fi
fi
```

### 3. Display Banner

```bash
# Print banner
echo -e "${BLUE}"
echo "██████╗  █████╗ ███████╗███████╗███╗   ██╗"
echo "██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║"
echo "██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║"
echo "██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║"
echo "██║  ██║██║  ██║███████╗███████╗██║ ╚████║"
echo "╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${CYAN}Razen Programming Language Installer${NC}"
echo -e "${CYAN}Version: ${RAZEN_VERSION}${NC}"
echo -e "${CYAN}=======================================${NC}"
```

## Installation Process

### Step 1: Repository Cloning
- The installer will clone the Razen GitHub repository to a temporary folder:
```bash
echo -e "${YELLOW}Cloning Razen repository...${NC}"
git clone --depth=1 "$RAZEN_GIT_REPO" "$TMP_DIR/razen" || handle_error $? "Failed to clone repository" "Check your internet connection and GitHub access"
echo -e "  ${GREEN}✓${NC} Razen repository cloned successfully"
```

### Step 2: Copy Required Files and Folders
- The installer copies all required files and folders to the appropriate installation directory based on the operating system:
```bash
# Determine installation directory based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    INSTALL_DIR="$LINUX_INSTALL_DIR"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_DIR="$MACOS_INSTALL_DIR"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    INSTALL_DIR="$WINDOWS_INSTALL_DIR"
else
    handle_error 1 "Unsupported operating system: $OSTYPE" "This installer supports Linux, macOS, and Windows"
fi

# Create installation directory if it doesn't exist
sudo mkdir -p "$INSTALL_DIR" || handle_error $? "Failed to create installation directory" "Check your permissions"

# Copy required files and folders
echo -e "${YELLOW}Copying Razen files to $INSTALL_DIR...${NC}"
REQUIRED_ITEMS=(
    "properties"
    "src"
    "examples"
    "docs"
    "core"
    "scripts"
    "Cargo.toml"
    "version"
    "LICENSE"
    "README.md"
)

for item in "${REQUIRED_ITEMS[@]}"; do
    sudo cp -r "$TMP_DIR/razen/$item" "$INSTALL_DIR/" || handle_error $? "Failed to copy $item" "Check permissions and disk space"
done

# Copy universal installer for reference
sudo cp "$TMP_DIR/razen/installer.sh" "$INSTALL_DIR/" || handle_error $? "Failed to copy installer script" "Check permissions"

echo -e "  ${GREEN}✓${NC} All required files copied successfully"
```

### Step 3: IDE Extension Selection
- The installer prompts the user to select their preferred IDE environment:
```bash
echo -e "${YELLOW}Select your preferred IDE environment:${NC}"
echo "1. VSCode or VSCode-based IDEs"
echo "2. JetBrains IDEs"
echo "3. Both"
echo "4. Skip IDE extension installation"

read -p "Enter your choice (1-4): " ide_choice

case $ide_choice in
    1)
        echo -e "${YELLOW}Installing VSCode extension support...${NC}"
        sudo cp -r "$TMP_DIR/razen/razen-vscode-extension" "$INSTALL_DIR/" || handle_error $? "Failed to copy VSCode extension" "Check permissions"
        echo -e "  ${GREEN}✓${NC} VSCode extension support installed"
        IDE_CHOICE="vscode"
        ;;
    2)
        echo -e "${YELLOW}Installing JetBrains plugin support...${NC}"
        sudo cp -r "$TMP_DIR/razen/razen-jetbrains-plugin" "$INSTALL_DIR/" || handle_error $? "Failed to copy JetBrains plugin" "Check permissions"
        echo -e "  ${GREEN}✓${NC} JetBrains plugin support installed"
        IDE_CHOICE="jetbrains"
        ;;
    3)
        echo -e "${YELLOW}Installing support for both IDE types...${NC}"
        sudo cp -r "$TMP_DIR/razen/razen-vscode-extension" "$INSTALL_DIR/" || handle_error $? "Failed to copy VSCode extension" "Check permissions"
        sudo cp -r "$TMP_DIR/razen/razen-jetbrains-plugin" "$INSTALL_DIR/" || handle_error $? "Failed to copy JetBrains plugin" "Check permissions"
        echo -e "  ${GREEN}✓${NC} All IDE extensions installed"
        IDE_CHOICE="both"
        ;;
    4)
        echo -e "${YELLOW}Skipping IDE extension installation${NC}"
        IDE_CHOICE="none"
        ;;
    *)
        echo -e "${RED}Invalid choice. Skipping IDE extension installation.${NC}"
        IDE_CHOICE="none"
        ;;
esac
```

### Step 4: Create Symbolic Links
- The installer creates symbolic links for all scripts to make them globally accessible:
```bash
echo -e "${YELLOW}Creating symbolic links for Razen scripts...${NC}"

# Get list of script files
SCRIPT_FILES=($(find "$INSTALL_DIR/scripts" -type f -name "*.sh" -o -name "*.py"))

# Create symbolic links for each script in /usr/local/bin
for script in "${SCRIPT_FILES[@]}"; do
    # Extract just the filename without extension
    filename=$(basename "$script")
    filename_noext="${filename%.*}"

    # Make the script executable
    sudo chmod +x "$script" || handle_error $? "Failed to make $script executable" "Check permissions"

    # Create symbolic link
    sudo ln -sf "$script" "/usr/local/bin/$filename_noext" || handle_error $? "Failed to create symbolic link for $filename_noext" "Check if /usr/local/bin exists and is writable"

    echo -e "  ${GREEN}✓${NC} Created symbolic link for $filename_noext"
done

echo -e "  ${GREEN}✓${NC} All symbolic links created successfully"
```

### Step 5: Rust Dependency Check and Build
- The installer checks for Rust installation and builds the Razen language components:
```bash
echo -e "${YELLOW}Checking for Rust installation...${NC}"

# Check if Rust is installed
if ! command -v rustc &>/dev/null || ! command -v cargo &>/dev/null; then
    echo -e "${RED}Rust is not installed on your system.${NC}"
    read -p "Would you like to install Rust now? (y/n): " install_rust

    if [[ "$install_rust" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || handle_error $? "Failed to install Rust" "Try installing Rust manually from https://rustup.rs/"

        # Source the cargo environment
        source "$HOME/.cargo/env" || handle_error $? "Failed to source Cargo environment" "Try restarting your terminal and running the installer again"

        echo -e "  ${GREEN}✓${NC} Rust installed successfully"
    else
        handle_error 1 "Rust is required to build Razen" "Please install Rust from https://rustup.rs/ and run the installer again"
    fi
else
    echo -e "  ${GREEN}✓${NC} Rust is installed"
fi

# Build Razen
echo -e "${YELLOW}Building Razen...${NC}"
cd "$INSTALL_DIR" || handle_error $? "Failed to navigate to installation directory" "Check if the directory exists"
cargo build --release || handle_error $? "Failed to build Razen" "Check for compilation errors and ensure Rust is properly installed"
echo -e "  ${GREEN}✓${NC} Razen built successfully"
```

### Step 6: IDE Extension Installation
- The installer helps the user install the Razen extensions or plugins to their selected IDEs:
```bash
if [[ "$IDE_CHOICE" == "vscode" || "$IDE_CHOICE" == "both" ]]; then
    echo -e "${YELLOW}Select your VSCode-based IDE to install the Razen extension:${NC}"
    echo "1. Visual Studio Code"
    echo "2. VSCodium"
    echo "3. Cursor AI"
    echo "4. Windsurf"
    echo "5. Trae AI"
    echo "6. Zed"
    echo "7. Skip extension installation"

    read -p "Enter your choice (1-7): " vscode_choice

    case $vscode_choice in
        [1-6])
            # Get IDE-specific extension directory
            case $vscode_choice in
                1) ext_dir="$HOME/.vscode/extensions" && ide_name="Visual Studio Code" ;;
                2) ext_dir="$HOME/.vscode-oss/extensions" && ide_name="VSCodium" ;;
                3) ext_dir="$HOME/.cursor/extensions" && ide_name="Cursor AI" ;;
                4) ext_dir="$HOME/.windsurf/extensions" && ide_name="Windsurf" ;;
                5) ext_dir="$HOME/.trae/extensions" && ide_name="Trae AI" ;;
                6) ext_dir="$HOME/.zed/extensions" && ide_name="Zed" ;;
            esac

            # Create extension directory if it doesn't exist
            mkdir -p "$ext_dir" || handle_error $? "Failed to create extension directory" "Check permissions"

            # Copy extension
            echo -e "${YELLOW}Installing Razen extension for $ide_name...${NC}"
            cp -r "$INSTALL_DIR/razen-vscode-extension" "$ext_dir/razen.razen-lang" || handle_error $? "Failed to install extension" "Check permissions"
            echo -e "  ${GREEN}✓${NC} Razen extension installed for $ide_name"
            ;;
        7)
            echo -e "${YELLOW}Skipping VSCode extension installation${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice. Skipping VSCode extension installation.${NC}"
            ;;
    esac
fi

if [[ "$IDE_CHOICE" == "jetbrains" || "$IDE_CHOICE" == "both" ]]; then
    echo -e "${YELLOW}Select your JetBrains IDE to install the Razen plugin:${NC}"
    echo "1. IntelliJ IDEA"
    echo "2. PyCharm"
    echo "3. WebStorm"
    echo "4. CLion"
    echo "5. Rider"
    echo "6. PhpStorm"
    echo "7. GoLand"
    echo "8. RubyMine"
    echo "9. Skip plugin installation"

    read -p "Enter your choice (1-9): " jetbrains_choice

    if [[ "$jetbrains_choice" =~ ^[1-8]$ ]]; then
        # Get IDE-specific plugin directory
        case $jetbrains_choice in
            1) plugin_dir="$HOME/.config/JetBrains/IntelliJIdea*/plugins" && ide_name="IntelliJ IDEA" ;;
            2) plugin_dir="$HOME/.config/JetBrains/PyCharm*/plugins" && ide_name="PyCharm" ;;
            3) plugin_dir="$HOME/.config/JetBrains/WebStorm*/plugins" && ide_name="WebStorm" ;;
            4) plugin_dir="$HOME/.config/JetBrains/CLion*/plugins" && ide_name="CLion" ;;
            5) plugin_dir="$HOME/.config/JetBrains/Rider*/plugins" && ide_name="Rider" ;;
            6) plugin_dir="$HOME/.config/JetBrains/PhpStorm*/plugins" && ide_name="PhpStorm" ;;
            7) plugin_dir="$HOME/.config/JetBrains/GoLand*/plugins" && ide_name="GoLand" ;;
            8) plugin_dir="$HOME/.config/JetBrains/RubyMine*/plugins" && ide_name="RubyMine" ;;
        esac

        # Find actual plugin directory (resolving wildcard)
        plugin_dir=$(echo $plugin_dir)

        if [ -d "$plugin_dir" ]; then
            # Create plugin directory if needed
            mkdir -p "$plugin_dir" || handle_error $? "Failed to create plugin directory" "Check permissions"

            # Copy plugin
            echo -e "${YELLOW}Installing Razen plugin for $ide_name...${NC}"
            cp -r "$INSTALL_DIR/razen-jetbrains-plugin" "$plugin_dir/razen-lang" || handle_error $? "Failed to install plugin" "Check permissions"
            echo -e "  ${GREEN}✓${NC} Razen plugin installed for $ide_name"
        else
            echo -e "${RED}Could not find plugin directory for $ide_name.${NC}"
            echo -e "${YELLOW}Please install the plugin manually from JetBrains Marketplace.${NC}"
        fi
    elif [[ "$jetbrains_choice" == "9" ]]; then
        echo -e "${YELLOW}Skipping JetBrains plugin installation${NC}"
    else
        echo -e "${RED}Invalid choice. Skipping JetBrains plugin installation.${NC}"
    fi
fi
```

### Step 7: Display Help Information
- The installer runs the help command to introduce the user to Razen:
```bash
echo -e "${YELLOW}Displaying Razen help information...${NC}"
if command -v razen-help &>/dev/null; then
    echo -e "${CYAN}=== Razen Help Information ===${NC}"
    razen-help
else
    echo -e "${RED}Warning: razen-help command not found.${NC}"
    echo -e "${YELLOW}You can manually access help by navigating to $INSTALL_DIR/scripts and running the help script.${NC}"
fi
```

### Step 8: Installation Complete
- The installer confirms successful installation and provides next steps:
```bash
echo -e "${GREEN}=== Razen Installation Complete ===${NC}"
echo -e "${CYAN}Razen has been successfully installed to: $INSTALL_DIR${NC}"
echo -e "${CYAN}The following commands are now available globally:${NC}"

# List available commands
for cmd in $(find /usr/local/bin -type l -exec readlink {} \; | grep -E "$INSTALL_DIR/scripts" | xargs basename); do
    echo -e "  ${GREEN}•${NC} $cmd"
done

echo -e "\n${CYAN}You can now start using Razen!${NC}"
echo -e "${CYAN}For more information, visit: https://razen-lang.org${NC}"
echo -e "${CYAN}Happy coding!${NC}"
```

## Troubleshooting

If you encounter issues during installation, here are some common solutions:

1. **Permission Errors**:
   - Linux/macOS: Run the installer with sudo privileges
   - Windows: Run Git Bash as Administrator

2. **Missing Dependencies**:
   - Ensure Rust is properly installed
   - For Windows users: Make sure Git Bash or WSL is installed

3. **IDE Extension Issues**:
   - Try manually installing the extensions from their respective marketplaces
   - Check the extension directories match your IDE installation

4. **Path Issues**:
   - Linux/macOS: Make sure /usr/local/bin is in your PATH environment variable
   - Windows: Restart your terminal after installation to refresh PATH

5. **Build Failures**:
   - Check for error messages in the build output
   - Make sure all dependencies are installed
   - Windows users may need Visual C++ Build Tools

6. **Windows-Specific Issues**:
   - If using Git Bash, make sure it's up to date
   - Some commands might require administrator privileges
   - Consider using WSL for a more Linux-like experience

For additional help, please visit the Razen community forum or open an issue on GitHub.

## Legacy Installers

> **Note**: The previous OS-specific installers (`install.sh`, `install-mac.sh`, and `install.bat`) have been deprecated in favor of the unified `installer.sh` script. We recommend using the unified installer for all platforms.
