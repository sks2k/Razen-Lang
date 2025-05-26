#!/bin/bash

# Razen Programming Language Installer/Uninstaller
# This script installs, updates, or uninstalls Razen across Linux, macOS, and Windows (via Git Bash/WSL)
# Usage: ./installer.sh          # Install or update Razen
#        ./installer.sh uninstall # Uninstall Razen
#        ./installer.sh force    # Force a fresh installation
# Version: 0.1.2

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for terminal output
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

# Detect OS
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
else
    echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
    exit 1
fi

# Temporary directory for downloads
TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t 'razen_tmp')"
trap 'rm -rf "$TMP_DIR"' EXIT

# Utility Functions
# --------------------------------------------------

# Check for internet connectivity
check_internet() {
    echo -e "${YELLOW}Checking internet connectivity...${NC}"
    
    # Use different commands based on OS
    if [[ "$OS" == "windows" ]]; then
        if ! ping -n 1 github.com &>/dev/null && ! ping -n 1 google.com &>/dev/null; then
            echo -e "${RED}Error: No internet connection detected.${NC}"
            echo -e "${YELLOW}Please check your network connection and try again.${NC}"
            return 1
        fi
    else
        if ! ping -c 1 github.com &>/dev/null && ! ping -c 1 google.com &>/dev/null; then
            echo -e "${RED}Error: No internet connection detected.${NC}"
            echo -e "${YELLOW}Please check your network connection and try again.${NC}"
            return 1
        fi
    fi
    
    echo -e "  ${GREEN}✓${NC} Internet connection detected"
    return 0
}

# Check for sudo/admin privileges
check_permissions() {
    echo -e "${YELLOW}Checking for required permissions...${NC}"
    
    if [[ "$OS" == "windows" ]]; then
        # Check for admin rights on Windows
        if ! net session &>/dev/null; then
            echo -e "${YELLOW}Administrator privileges recommended for Windows installation.${NC}"
            echo -e "${YELLOW}Some features may not work correctly without admin rights.${NC}"
            read -p "Continue anyway? (y/n): " continue_anyway
            if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                echo -e "${RED}Installation aborted. Please restart with administrator privileges.${NC}"
                exit 1
            fi
        else
            echo -e "  ${GREEN}✓${NC} Running with administrator privileges"
        fi
    else
        # Check for sudo access on Linux/macOS
        if [ "$EUID" -eq 0 ]; then
            # Already running as root
            echo -e "  ${GREEN}✓${NC} Running with root privileges"
        else
            # Test sudo access
            if ! sudo -v &>/dev/null; then
                echo -e "${RED}Error: This script requires sudo privileges to install system-wide.${NC}"
                echo -e "${YELLOW}Please run with sudo or as root.${NC}"
                return 1
            fi
            echo -e "  ${GREEN}✓${NC} Sudo access confirmed"
        fi
    fi
    
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

# Create a symbolic link based on OS
create_symlink() {
    local src=$1
    local dest=$2
    
    if [[ "$OS" == "windows" ]]; then
        # Windows symlinks (needs admin privileges)
        if [[ -d "$src" ]]; then
            cmd.exe /c "mklink /d \"$(cygpath -w "$dest")\" \"$(cygpath -w "$src")\"" &>/dev/null || true
        else
            cmd.exe /c "mklink \"$(cygpath -w "$dest")\" \"$(cygpath -w "$src")\"" &>/dev/null || true
        fi
    else
        # Linux/macOS symlinks
        sudo ln -sf "$src" "$dest"
    fi
}

# Add to PATH for Windows
add_to_path_windows() {
    echo -e "${YELLOW}Adding Razen to your PATH...${NC}"
    if command -v powershell &>/dev/null; then
        powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$BIN_DIR', 'User')" || true
        echo -e "  ${GREEN}✓${NC} Added $BIN_DIR to your PATH"
    else
        echo -e "${YELLOW}Could not add Razen to your PATH automatically.${NC}"
        echo -e "${YELLOW}Please add $BIN_DIR to your PATH manually.${NC}"
    fi
}

# Install Rust based on OS
install_rust() {
    echo -e "${YELLOW}Installing Rust...${NC}"
    
    if [[ "$OS" == "windows" ]]; then
        # Download and run rustup-init.exe for Windows
        curl -sSf -o "$TMP_DIR/rustup-init.exe" https://win.rustup.rs/x86_64
        "$TMP_DIR/rustup-init.exe" -y --no-modify-path
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        # Linux/macOS
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    echo -e "  ${GREEN}✓${NC} Rust installed successfully"
}

# Get version information
get_version() {
    if [ -f "version" ]; then
        RAZEN_VERSION=$(cat version)
    else
        # Download version file if not present
        if ! curl -s -o "$TMP_DIR/version" "$RAZEN_REPO/version" &>/dev/null; then
            echo -e "${RED}Failed to download version information. Using default version.${NC}"
            RAZEN_VERSION="beta v0.1.67 (Tokens update and new libraries added.)"
        else
            RAZEN_VERSION=$(cat "$TMP_DIR/version")
            # Store the version file for future reference
            echo -e "  ${GREEN}✓${NC} Downloaded version information: $RAZEN_VERSION"
        fi
    fi
}

# Check if Razen is installed and get the installed version
check_installed_razen() {
    echo -e "${YELLOW}Checking for existing Razen installation...${NC}"
    
    # Check if razen-help command exists
    if command -v razen-help &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Razen is installed"
        
        # Try to get the installed version
        if [[ "$OS" == "windows" ]]; then
            if [ -f "$INSTALL_DIR/version" ]; then
                INSTALLED_VERSION=$(cat "$INSTALL_DIR/version")
                echo -e "  ${GREEN}✓${NC} Installed version: $INSTALLED_VERSION"
                return 0
            fi
        else
            if [ -f "$INSTALL_DIR/version" ]; then
                if [ -r "$INSTALL_DIR/version" ]; then
                    INSTALLED_VERSION=$(cat "$INSTALL_DIR/version")
                else
                    INSTALLED_VERSION=$(sudo cat "$INSTALL_DIR/version")
                fi
                echo -e "  ${GREEN}✓${NC} Installed version: $INSTALLED_VERSION"
                return 0
            fi
        fi
        
        # If we couldn't get version but command exists
        echo -e "  ${YELLOW}Could not determine installed version${NC}"
        INSTALLED_VERSION="unknown"
        return 0
    fi
    
    # Check if installation directory exists
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "  ${GREEN}✓${NC} Razen installation directory found"
        
        # Try to get the installed version
        if [[ "$OS" == "windows" ]]; then
            if [ -f "$INSTALL_DIR/version" ]; then
                INSTALLED_VERSION=$(cat "$INSTALL_DIR/version")
                echo -e "  ${GREEN}✓${NC} Installed version: $INSTALLED_VERSION"
                return 0
            fi
        else
            if [ -f "$INSTALL_DIR/version" ]; then
                if [ -r "$INSTALL_DIR/version" ]; then
                    INSTALLED_VERSION=$(cat "$INSTALL_DIR/version")
                else
                    INSTALLED_VERSION=$(sudo cat "$INSTALL_DIR/version")
                fi
                echo -e "  ${GREEN}✓${NC} Installed version: $INSTALLED_VERSION"
                return 0
            fi
        fi
        
        # If we couldn't get version but directory exists
        echo -e "  ${YELLOW}Could not determine installed version${NC}"
        INSTALLED_VERSION="unknown"
        return 0
    fi
    
    echo -e "  ${YELLOW}No existing Razen installation found${NC}"
    return 1
}

# Compare installed version with latest version
# Returns 0 if update is needed, 1 if no update is needed
needs_update() {
    # If no installed version, then update is needed
    if [ -z "$INSTALLED_VERSION" ]; then
        return 0
    fi
    
    # If installed version is unknown, assume update is needed
    if [ "$INSTALLED_VERSION" == "unknown" ]; then
        return 0
    fi
    
    # If versions are different, update is needed
    if [ "$INSTALLED_VERSION" != "$RAZEN_VERSION" ]; then
        return 0
    fi
    
    # Versions are the same, no update needed
    return 1
}

# Display Banner
# --------------------------------------------------
display_banner() {
    echo -e "${BLUE}"
    echo "██████╗  █████╗ ███████╗███████╗███╗   ██╗"
    echo "██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║"
    echo "██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║"
    echo "██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║"
    echo "██║  ██║██║  ██║███████╗███████╗██║ ╚████║"
    echo "╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝"
    echo -e "${NC}"
    
    if [[ "$1" == "uninstall" ]]; then
        echo -e "${CYAN}Razen Programming Language Uninstaller${NC}"
    elif [[ "$1" == "force" ]]; then
        echo -e "${CYAN}Razen Programming Language Forced Installer${NC}"
    elif [[ "$1" == "update" ]]; then
        echo -e "${CYAN}Razen Programming Language Updater${NC}"
    else
        echo -e "${CYAN}Razen Programming Language Installer${NC}"
    fi
    
    echo -e "${CYAN}Version: $RAZEN_VERSION${NC}"
    echo -e "${CYAN}Detected OS: $OS${NC}"
    echo -e "${CYAN}=======================================${NC}"
}

# Main Installation Process
# --------------------------------------------------

# Step 1: Repository Cloning
clone_repository() {
    echo -e "${YELLOW}Cloning Razen repository...${NC}"
    if ! command -v git &>/dev/null; then
        echo -e "${RED}Git is not installed. Please install Git and try again.${NC}"
        exit 1
    fi
    
    git clone --depth=1 "$RAZEN_GIT_REPO" "$TMP_DIR/razen" || handle_error $? "Failed to clone repository" "Check your internet connection and GitHub access"
    echo -e "  ${GREEN}✓${NC} Razen repository cloned successfully"
}

# Step 2: Copy Required Files and Folders
copy_files() {
    # Create installation directory if it doesn't exist
    if [[ "$OS" == "windows" ]]; then
        mkdir -p "$INSTALL_DIR" || handle_error $? "Failed to create installation directory" "Check your permissions"
    else
        sudo mkdir -p "$INSTALL_DIR" || handle_error $? "Failed to create installation directory" "Check your permissions"
    fi
    
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
        if [[ "$OS" == "windows" ]]; then
            cp -r "$TMP_DIR/razen/$item" "$INSTALL_DIR/" || handle_error $? "Failed to copy $item" "Check permissions and disk space"
        else
            sudo cp -r "$TMP_DIR/razen/$item" "$INSTALL_DIR/" || handle_error $? "Failed to copy $item" "Check permissions and disk space"
        fi
    done
    
    # Copy universal installer for reference
    if [[ "$OS" == "windows" ]]; then
        cp "$TMP_DIR/razen/installer.sh" "$INSTALL_DIR/" 2>/dev/null || true
    else
        sudo cp "$TMP_DIR/razen/installer.sh" "$INSTALL_DIR/" 2>/dev/null || true
    fi
    
    echo -e "  ${GREEN}✓${NC} All required files copied successfully"
}

# Step 3: IDE Extension Selection
select_ide() {
    echo -e "${YELLOW}Select your preferred IDE environment:${NC}"
    echo "1. VSCode or VSCode-based IDEs"
    echo "2. JetBrains IDEs"
    echo "3. Both"
    echo "4. Skip IDE extension installation"
    
    read -p "Enter your choice (1-4): " ide_choice
    
    case $ide_choice in
        1)
            echo -e "${YELLOW}Installing VSCode extension support...${NC}"
            if [[ "$OS" == "windows" ]]; then
                cp -r "$TMP_DIR/razen/razen-vscode-extension" "$INSTALL_DIR/" || handle_error $? "Failed to copy VSCode extension" "Check permissions"
            else
                sudo cp -r "$TMP_DIR/razen/razen-vscode-extension" "$INSTALL_DIR/" || handle_error $? "Failed to copy VSCode extension" "Check permissions"
            fi
            echo -e "  ${GREEN}✓${NC} VSCode extension support installed"
            IDE_CHOICE="vscode"
            ;;
        2)
            echo -e "${YELLOW}Installing JetBrains plugin support...${NC}"
            if [[ "$OS" == "windows" ]]; then
                cp -r "$TMP_DIR/razen/razen-jetbrains-plugin" "$INSTALL_DIR/" || handle_error $? "Failed to copy JetBrains plugin" "Check permissions"
            else
                sudo cp -r "$TMP_DIR/razen/razen-jetbrains-plugin" "$INSTALL_DIR/" || handle_error $? "Failed to copy JetBrains plugin" "Check permissions"
            fi
            echo -e "  ${GREEN}✓${NC} JetBrains plugin support installed"
            IDE_CHOICE="jetbrains"
            ;;
        3)
            echo -e "${YELLOW}Installing support for both IDE types...${NC}"
            if [[ "$OS" == "windows" ]]; then
                cp -r "$TMP_DIR/razen/razen-vscode-extension" "$INSTALL_DIR/" || handle_error $? "Failed to copy VSCode extension" "Check permissions"
                cp -r "$TMP_DIR/razen/razen-jetbrains-plugin" "$INSTALL_DIR/" || handle_error $? "Failed to copy JetBrains plugin" "Check permissions"
            else
                sudo cp -r "$TMP_DIR/razen/razen-vscode-extension" "$INSTALL_DIR/" || handle_error $? "Failed to copy VSCode extension" "Check permissions"
                sudo cp -r "$TMP_DIR/razen/razen-jetbrains-plugin" "$INSTALL_DIR/" || handle_error $? "Failed to copy JetBrains plugin" "Check permissions"
            fi
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
}

# Step 4: Create Symbolic Links
create_symlinks() {
    echo -e "${YELLOW}Creating executable links for Razen scripts...${NC}"
    
    # Get list of script files
    SCRIPT_FILES=($(find "$INSTALL_DIR/scripts" -type f -name "*.sh" -o -name "*.py" 2>/dev/null))
    
    # Create symbolic links for each script
    for script in "${SCRIPT_FILES[@]}"; do
        # Extract just the filename without extension
        filename=$(basename "$script")
        filename_noext="${filename%.*}"
        
        # Make the script executable
        if [[ "$OS" == "windows" ]]; then
            chmod +x "$script" || handle_error $? "Failed to make $script executable" "Check permissions"
        else
            sudo chmod +x "$script" || handle_error $? "Failed to make $script executable" "Check permissions"
        fi
        
        # Create symbolic link or batch file wrapper
        if [[ "$OS" == "windows" ]]; then
            # For Windows, create .bat wrapper in BIN_DIR
            echo "@echo off" > "$BIN_DIR/$filename_noext.bat"
            echo "\"$script\" %*" >> "$BIN_DIR/$filename_noext.bat"
            echo -e "  ${GREEN}✓${NC} Created wrapper for $filename_noext"
        else
            # For Linux/macOS, create symbolic link in /usr/local/bin
            create_symlink "$script" "$BIN_DIR/$filename_noext"
            echo -e "  ${GREEN}✓${NC} Created symbolic link for $filename_noext"
        fi
    done
    
    # For Windows, add to PATH
    if [[ "$OS" == "windows" ]]; then
        add_to_path_windows
    fi
    
    echo -e "  ${GREEN}✓${NC} All command links created successfully"
}

# Step 5: Rust Dependency Check and Build
setup_rust_and_build() {
    echo -e "${YELLOW}Checking for Rust installation...${NC}"
    
    # Check if Rust is installed
    if ! command -v rustc &>/dev/null || ! command -v cargo &>/dev/null; then
        echo -e "${RED}Rust is not installed on your system.${NC}"
        read -p "Would you like to install Rust now? (y/n): " install_rust_choice
        
        if [[ "$install_rust_choice" =~ ^[Yy]$ ]]; then
            install_rust
        else
            handle_error 1 "Rust is required to build Razen" "Please install Rust from https://rustup.rs/ and run the installer again"
        fi
    else
        echo -e "  ${GREEN}✓${NC} Rust is installed"
    fi
    
    # Build Razen
    echo -e "${YELLOW}Building Razen...${NC}"
    cd "$INSTALL_DIR" || handle_error $? "Failed to navigate to installation directory" "Check if the directory exists"
    
    # Ensure PATH includes cargo
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Fix permissions before building
    if [[ "$OS" == "windows" ]]; then
        # Windows doesn't need permission fixes
        cargo build --release || handle_error $? "Failed to build Razen" "Check for compilation errors and ensure Rust is properly installed"
    else
        # For Linux/macOS, temporarily change ownership to current user for the build
        echo -e "${YELLOW}Setting proper permissions for build...${NC}"
        current_user=$(whoami)
        sudo chown -R "$current_user" "$INSTALL_DIR"
        
        # Build with current user permissions
        cargo build --release || handle_error $? "Failed to build Razen" "Check for compilation errors and ensure Rust is properly installed"
        
        # Return ownership to root for system directories
        sudo chown -R root:root "$INSTALL_DIR"
    fi
    
    echo -e "  ${GREEN}✓${NC} Razen built successfully"
}

# Step 6: IDE Extension Installation
install_ide_extensions() {
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
                # Get IDE-specific extension directory based on OS
                if [[ "$OS" == "windows" ]]; then
                    case $vscode_choice in
                        1) ext_dir="$APPDATA/Code/User/extensions" && ide_name="Visual Studio Code" ;;
                        2) ext_dir="$APPDATA/VSCodium/User/extensions" && ide_name="VSCodium" ;;
                        3) ext_dir="$APPDATA/Cursor/User/extensions" && ide_name="Cursor AI" ;;
                        4) ext_dir="$APPDATA/Windsurf/User/extensions" && ide_name="Windsurf" ;;
                        5) ext_dir="$APPDATA/Trae/User/extensions" && ide_name="Trae AI" ;;
                        6) ext_dir="$APPDATA/Zed/User/extensions" && ide_name="Zed" ;;
                    esac
                elif [[ "$OS" == "macos" ]]; then
                    case $vscode_choice in
                        1) ext_dir="$HOME/Library/Application Support/Code/User/extensions" && ide_name="Visual Studio Code" ;;
                        2) ext_dir="$HOME/Library/Application Support/VSCodium/User/extensions" && ide_name="VSCodium" ;;
                        3) ext_dir="$HOME/Library/Application Support/Cursor/User/extensions" && ide_name="Cursor AI" ;;
                        4) ext_dir="$HOME/Library/Application Support/Windsurf/User/extensions" && ide_name="Windsurf" ;;
                        5) ext_dir="$HOME/Library/Application Support/Trae/User/extensions" && ide_name="Trae AI" ;;
                        6) ext_dir="$HOME/Library/Application Support/Zed/extensions" && ide_name="Zed" ;;
                    esac
                else # Linux
                    case $vscode_choice in
                        1) ext_dir="$HOME/.vscode/extensions" && ide_name="Visual Studio Code" ;;
                        2) ext_dir="$HOME/.vscode-oss/extensions" && ide_name="VSCodium" ;;
                        3) ext_dir="$HOME/.cursor/extensions" && ide_name="Cursor AI" ;;
                        4) ext_dir="$HOME/.windsurf/extensions" && ide_name="Windsurf" ;;
                        5) ext_dir="$HOME/.trae/extensions" && ide_name="Trae AI" ;;
                        6) ext_dir="$HOME/.zed/extensions" && ide_name="Zed" ;;
                    esac
                fi
                
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
            # Get IDE-specific plugin directory based on OS
            if [[ "$OS" == "windows" ]]; then
                case $jetbrains_choice in
                    1) plugin_dir="$APPDATA/JetBrains/IntelliJIdea*/plugins" && ide_name="IntelliJ IDEA" ;;
                    2) plugin_dir="$APPDATA/JetBrains/PyCharm*/plugins" && ide_name="PyCharm" ;;
                    3) plugin_dir="$APPDATA/JetBrains/WebStorm*/plugins" && ide_name="WebStorm" ;;
                    4) plugin_dir="$APPDATA/JetBrains/CLion*/plugins" && ide_name="CLion" ;;
                    5) plugin_dir="$APPDATA/JetBrains/Rider*/plugins" && ide_name="Rider" ;;
                    6) plugin_dir="$APPDATA/JetBrains/PhpStorm*/plugins" && ide_name="PhpStorm" ;;
                    7) plugin_dir="$APPDATA/JetBrains/GoLand*/plugins" && ide_name="GoLand" ;;
                    8) plugin_dir="$APPDATA/JetBrains/RubyMine*/plugins" && ide_name="RubyMine" ;;
                esac
            elif [[ "$OS" == "macos" ]]; then
                case $jetbrains_choice in
                    1) plugin_dir="$HOME/Library/Application Support/JetBrains/IntelliJIdea*/plugins" && ide_name="IntelliJ IDEA" ;;
                    2) plugin_dir="$HOME/Library/Application Support/JetBrains/PyCharm*/plugins" && ide_name="PyCharm" ;;
                    3) plugin_dir="$HOME/Library/Application Support/JetBrains/WebStorm*/plugins" && ide_name="WebStorm" ;;
                    4) plugin_dir="$HOME/Library/Application Support/JetBrains/CLion*/plugins" && ide_name="CLion" ;;
                    5) plugin_dir="$HOME/Library/Application Support/JetBrains/Rider*/plugins" && ide_name="Rider" ;;
                    6) plugin_dir="$HOME/Library/Application Support/JetBrains/PhpStorm*/plugins" && ide_name="PhpStorm" ;;
                    7) plugin_dir="$HOME/Library/Application Support/JetBrains/GoLand*/plugins" && ide_name="GoLand" ;;
                    8) plugin_dir="$HOME/Library/Application Support/JetBrains/RubyMine*/plugins" && ide_name="RubyMine" ;;
                esac
            else # Linux
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
            fi
            
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
}

# Step 7: Display Help Information
display_help() {
    echo -e "${YELLOW}Displaying Razen help information...${NC}"
    
    # Determine razen-help command path
    if [[ "$OS" == "windows" ]]; then
        RAZEN_HELP="$BIN_DIR/razen-help.bat"
        if [ -f "$RAZEN_HELP" ]; then
            echo -e "${CYAN}=== Razen Help Information ===${NC}"
            "$RAZEN_HELP"
        else
            echo -e "${RED}Warning: razen-help command not found.${NC}"
            echo -e "${YELLOW}You can manually access help by navigating to $INSTALL_DIR/scripts and running the help script.${NC}"
        fi
    else
        if command -v razen-help &>/dev/null; then
            echo -e "${CYAN}=== Razen Help Information ===${NC}"
            razen-help
        else
            echo -e "${RED}Warning: razen-help command not found.${NC}"
            echo -e "${YELLOW}You can manually access help by navigating to $INSTALL_DIR/scripts and running the help script.${NC}"
        fi
    fi
}

# Step 8: Installation Complete
installation_complete() {
    echo -e "${GREEN}=== Razen Installation Complete ===${NC}"
    echo -e "${CYAN}Razen has been successfully installed to: $INSTALL_DIR${NC}"
    
    if [[ "$OS" == "windows" ]]; then
        echo -e "${CYAN}The following commands are now available from: $BIN_DIR${NC}"
        echo -e "${CYAN}Make sure this directory is in your PATH.${NC}"
        
        # List available commands
        for cmd in "$BIN_DIR"/*.bat; do
            if [ -f "$cmd" ]; then
                cmd_name=$(basename "$cmd" .bat)
                echo -e "  ${GREEN}•${NC} $cmd_name"
            fi
        done
    else
        echo -e "${CYAN}The following commands are now available globally:${NC}"
        
        # List available commands
        for cmd in $(find "$BIN_DIR" -type l -exec readlink {} \; 2>/dev/null | grep -E "$INSTALL_DIR/scripts" | xargs -r basename); do
            echo -e "  ${GREEN}•${NC} $cmd"
        done
    fi
    
    echo -e "\n${CYAN}You can now start using Razen!${NC}"
    echo -e "${CYAN}For more information, visit: https://razen-lang.org${NC}"
    echo -e "${CYAN}Happy coding!${NC}"
}

# Uninstall Razen
uninstall_razen() {
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Get confirmation
    read -p "Are you sure you want to uninstall Razen? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Uninstallation cancelled.${NC}"
        exit 0
    fi
    
    # Remove symbolic links
    echo -e "${YELLOW}Removing symbolic links...${NC}"
    if [[ "$OS" == "windows" ]]; then
        # Remove bat files from BIN_DIR
        rm -f "$BIN_DIR"/*.bat 2>/dev/null
    else
        # Find and remove all symlinks pointing to Razen scripts
        for link in $(find "$BIN_DIR" -type l -exec readlink {} \; 2>/dev/null | grep -E "$INSTALL_DIR/scripts" | xargs -r dirname | xargs -r basename); do
            sudo rm -f "$BIN_DIR/$link" 2>/dev/null
        done
    fi
    
    # Remove installation directory
    echo -e "${YELLOW}Removing Razen installation directory...${NC}"
    if [[ "$OS" == "windows" ]]; then
        rm -rf "$INSTALL_DIR" 2>/dev/null || echo -e "${RED}Failed to remove installation directory. You may need to remove it manually: $INSTALL_DIR${NC}"
    else
        sudo rm -rf "$INSTALL_DIR" 2>/dev/null || echo -e "${RED}Failed to remove installation directory. You may need to remove it manually: $INSTALL_DIR${NC}"
    fi
    
    echo -e "${GREEN}Razen has been uninstalled successfully.${NC}"
}

# Main
main() {
    # Check if uninstall flag is passed
    if [[ "$1" == "uninstall" ]]; then
        check_permissions || exit 1
        uninstall_razen
        exit 0
    fi
    
    # Check for internet connectivity
    check_internet || exit 1
    
    # Check for required permissions
    check_permissions || exit 1
    
    # Get version information
    get_version
    
    # Display banner
    display_banner "$1"
    
    # Check for existing installation unless force flag is used
    if [[ "$1" != "force" ]]; then
        if check_installed_razen; then
            # Check if update is needed
            if needs_update; then
                echo -e "${YELLOW}A new version of Razen is available.${NC}"
                echo -e "${YELLOW}Installed version: $INSTALLED_VERSION${NC}"
                echo -e "${YELLOW}Latest version: $RAZEN_VERSION${NC}"
                read -p "Do you want to update? (y/n): " update_choice
                if [[ ! "$update_choice" =~ ^[Yy]$ ]]; then
                    echo -e "${CYAN}Update cancelled. Exiting.${NC}"
                    exit 0
                fi
                echo -e "${YELLOW}Updating Razen...${NC}"
            else
                echo -e "${GREEN}Razen is already up to date (version $INSTALLED_VERSION).${NC}"
                read -p "Do you want to reinstall? (y/n): " reinstall_choice
                if [[ ! "$reinstall_choice" =~ ^[Yy]$ ]]; then
                    echo -e "${CYAN}Reinstallation cancelled. Exiting.${NC}"
                    exit 0
                fi
                echo -e "${YELLOW}Reinstalling Razen...${NC}"
            fi
        fi
    fi
    
    # Step 1: Clone repository
    clone_repository
    
    # Step 2: Copy required files and folders
    copy_files
    
    # Step 3: IDE Extension Selection
    select_ide
    
    # Step 4: Create Symbolic Links
    create_symlinks
    
    # Step 5: Rust Dependency Check and Build
    setup_rust_and_build
    
    # Step 6: IDE Extension Installation
    install_ide_extensions
    
    # Step 7: Display Help Information
    display_help
    
    # Step 8: Installation Complete
    installation_complete
    
    echo -e "${CYAN}To uninstall Razen in the future, run: $0 uninstall${NC}"
    echo -e "${CYAN}To check for updates, simply run this installer again.${NC}"
}

# Execute main function with all arguments
main "$@"
