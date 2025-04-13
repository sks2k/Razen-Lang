#!/usr/bin/env bash

# Razen Language Installer Script
# Author: Prathmesh Barot
# Copyright 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.53

set -e  # Exit on error

# Colors for terminal output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Repository URL
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"

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
        RAZEN_VERSION="beta v0.1.53"
    else
        RAZEN_VERSION=$(cat version)
        # Store the version file for future reference
        echo -e "  ${GREEN}✓${NC} Downloaded version information: $RAZEN_VERSION"
    fi
fi

echo -e "${YELLOW}Installing Razen ${PURPLE}$RAZEN_VERSION${NC}"

# Function to create symbolic links
create_symlinks() {
    local INSTALL_DIR="$1"
    echo -e "${YELLOW}Creating symbolic links...${NC}"
    
    # List of all scripts that need symlinks
    SCRIPTS="razen razen-debug razen-test razen-run razen-update razen-help razen-docs razen-extension"
    
    # Determine the appropriate bin directory based on permissions
    if [ -w "/usr/local/bin" ]; then
        BIN_DIR="/usr/local/bin"
    elif [ -w "$HOME/.local/bin" ]; then
        BIN_DIR="$HOME/.local/bin"
    else
        # Create user bin directory if it doesn't exist
        mkdir -p "$HOME/.local/bin"
        BIN_DIR="$HOME/.local/bin"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
            echo -e "${YELLOW}Added $HOME/.local/bin to your PATH. Please restart your terminal after installation.${NC}"
        fi
    fi
    
    echo -e "${YELLOW}Using bin directory: ${CYAN}$BIN_DIR${NC}"
    
    # Create symlinks in the bin directory
    local missing_links=0
    for script in $SCRIPTS; do
        if [ -f "$INSTALL_DIR/scripts/$script" ]; then
            if [ -w "$BIN_DIR" ]; then
                # Direct creation if we have write permissions
                ln -sf "$INSTALL_DIR/scripts/$script" "$BIN_DIR/$script"
                echo -e "  ${GREEN}✓${NC} Created $BIN_DIR/$script"
            else
                # Use sudo if we don't have direct write permissions
                if sudo ln -sf "$INSTALL_DIR/scripts/$script" "$BIN_DIR/$script"; then
                    echo -e "  ${GREEN}✓${NC} Created $BIN_DIR/$script"
                else
                    echo -e "  ${RED}✗${NC} Failed to create symlink in $BIN_DIR/$script (permission denied)"
                    missing_links=$((missing_links + 1))
                fi
            fi
        else
            echo -e "  ${RED}✗${NC} Failed to create $BIN_DIR/$script (source file not found)"
            missing_links=$((missing_links + 1))
        fi
    done
    
    # Verify all symlinks are created
    if [ $missing_links -gt 0 ]; then
        echo -e "${RED}Failed to create some symbolic links. Please check the errors above.${NC}"
        echo -e "${YELLOW}You may need to manually create symlinks or add the scripts directory to your PATH.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} All symbolic links created successfully in $BIN_DIR"
    return 0
}

# Function to check for updates
check_for_updates() {
    echo -e "${YELLOW}Checking for updates...${NC}"
    
    # Download version check file
    if ! curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/version.txt" "$RAZEN_REPO/version" &>/dev/null; then
        echo -e "${RED}Failed to check for updates. Please check your internet connection.${NC}"
        return 1
    fi
    
    # Read latest version
    LATEST_VERSION=$(cat "$TMP_DIR/version.txt" 2>/dev/null || echo "unknown")
    
    if [ "$LATEST_VERSION" == "$RAZEN_VERSION" ]; then
        echo -e "${GREEN}Razen is already up to date ($RAZEN_VERSION).${NC}"
        return 0
    else
        echo -e "${YELLOW}New version available: $LATEST_VERSION${NC}"
        echo -e "${YELLOW}Current version: $RAZEN_VERSION${NC}"
        return 2
    fi
}

# Function to perform update
perform_update() {
    echo -e "${YELLOW}Updating Razen...${NC}"
    
    # Download the latest installer
    if ! curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/install.sh" "$RAZEN_REPO/install.sh" &>/dev/null; then
        echo -e "${RED}Failed to download the latest installer.${NC}"
        return 1
    fi
    
    # Make it executable
    chmod +x "$TMP_DIR/install.sh"
    
    # Run the installer with the latest version
    bash "$TMP_DIR/install.sh"
    
    return $?
}

# Print banner
echo -e "${BLUE}"
echo "██████╗  █████╗ ███████╗███████╗███╗   ██╗"
echo "██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║"
echo "██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║"
echo "██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║"
echo "██║  ██║██║  ██║███████╗███████╗██║ ╚████║"
echo "╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝"
echo -e "${NC}"

# Check for internet connectivity first
check_internet || handle_error 1 "No internet connection" "Please check your network connection and try again"

# Check for required permissions
check_permissions || handle_error 2 "Insufficient permissions" "Please run with sudo or as root"

# Prepare installation
echo -e "${YELLOW}Preparing Razen installation...${NC}"

# Create temporary directory for installation
TMP_DIR=$(mktemp -d)
if [ ! -d "$TMP_DIR" ]; then
    handle_error 3 "Failed to create temporary directory" "Check if /tmp is writable"
fi
echo -e "  ${GREEN}✓${NC} Created temporary directory for installation"

# Check for uninstall flag
if [ "$1" == "--uninstall" ]; then
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Remove all binary and script symlinks
    for cmd in razen razen-debug razen-test razen-run razen-update razen-help; do
        if [ -L "/usr/local/bin/$cmd" ]; then
            sudo rm -f "/usr/local/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/$cmd"
        fi
        
        if [ -L "/usr/bin/$cmd" ]; then
            sudo rm -f "/usr/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed /usr/bin/$cmd"
        fi
    done
    
    # Remove installation directory
    if [ -d "/usr/local/lib/razen" ]; then
        sudo rm -rf "/usr/local/lib/razen"
        echo -e "  ${GREEN}✓${NC} Removed /usr/local/lib/razen"
    fi
    
    # Remove razen_compiler binary
    if [ -f "/usr/local/bin/razen_compiler" ]; then
        sudo rm -f "/usr/local/bin/razen_compiler"
        echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/razen_compiler"
    fi
    
    echo -e "${GREEN}Razen has been uninstalled successfully.${NC}"
    rm -rf "$TMP_DIR"
    exit 0
fi

# Check for force update flag
if [ "$1" == "--force-update" ]; then
    echo -e "${YELLOW}Force update mode activated. Will replace all existing files.${NC}"
    FORCE_UPDATE=true
else
    FORCE_UPDATE=false
fi

# Check for update flag or if already installed
if [ "$1" == "update" ] || [ "$1" == "--update" ] || [ -f "/usr/local/bin/razen" ] && [ "$FORCE_UPDATE" != "true" ]; then
    # Check for updates
    check_for_updates
    UPDATE_STATUS=$?
    
    if [ $UPDATE_STATUS -eq 2 ]; then
        # New version available
        echo -e "${YELLOW}Do you want to update Razen to the latest version? (y/n)${NC}"
        read -p "Enter your choice: " update_choice
        
        if [[ $update_choice =~ ^[Yy]$ ]]; then
            perform_update
            exit $?
        else
            echo -e "${YELLOW}Update cancelled. Continuing with current version.${NC}"
        fi
    elif [ $UPDATE_STATUS -eq 0 ]; then
        # Already up to date
        if [ "$1" == "update" ] || [ "$1" == "--update" ]; then
            echo -e "${GREEN}No update needed. Exiting.${NC}"
            rm -rf "$TMP_DIR"
            exit 0
        fi
    else
        # Error checking for updates
        echo -e "${YELLOW}Continuing with installation despite update check failure.${NC}"
    fi
fi

# Create necessary directories in temp folder
mkdir -p "$TMP_DIR/src"
mkdir -p "$TMP_DIR/scripts"
mkdir -p "$TMP_DIR/properties"
mkdir -p "$TMP_DIR/examples"
echo -e "  ${GREEN}✓${NC} Created temporary directories"

# Download Rust binary
echo -e "${YELLOW}Downloading Razen compiler binary...${NC}"
if ! curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/razen_compiler" "$RAZEN_REPO/target/release/razen_compiler" &>/dev/null; then
    echo -e "${RED}Failed to download Razen compiler binary${NC}"
    echo -e "${YELLOW}Attempting to build from source...${NC}"
    
    # Clone the repository
    echo -e "${YELLOW}Cloning Razen repository...${NC}"
    if ! git clone --depth 1 https://github.com/BasaiCorp/razen-lang.git "$TMP_DIR/razen-lang" &>/dev/null; then
        handle_error 4 "Failed to clone repository" "Check your internet connection and GitHub access"
    fi
    echo -e "  ${GREEN}✓${NC} Cloned Razen repository"
    
    # Build the project
    echo -e "${YELLOW}Building Razen from source...${NC}"
    cd "$TMP_DIR/razen-lang"
    
    # Check if cargo is available
    if ! command -v cargo &>/dev/null; then
        echo -e "${RED}Cargo not found. Cannot build from source.${NC}"
        echo -e "${YELLOW}Please install Rust and Cargo first:${NC}"
        echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Build the project
    if ! cargo build --release &>/dev/null; then
        handle_error 5 "Failed to build Razen from source" "Try installing Rust dependencies and try again"
    fi
    echo -e "  ${GREEN}✓${NC} Built Razen compiler from source"
    cd - > /dev/null
    
    # Copy the built binary
    cp "$TMP_DIR/razen-lang/target/release/razen_compiler" "$TMP_DIR/razen_compiler" || handle_error 6 "Failed to copy built binary" "Check file permissions"

    # Copy all other files from the cloned repository
    echo -e "${YELLOW}Copying files from cloned repository...${NC}"
    cp -r "$TMP_DIR/razen-lang/properties/"* "$TMP_DIR/properties/" 2>/dev/null || true
    cp -r "$TMP_DIR/razen-lang/scripts/"* "$TMP_DIR/scripts/" 2>/dev/null || true
    cp -r "$TMP_DIR/razen-lang/src/"* "$TMP_DIR/src/" 2>/dev/null || true
    cp -r "$TMP_DIR/razen-lang/examples/"* "$TMP_DIR/examples/" 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Copied files from cloned repository"
else
    echo -e "  ${GREEN}✓${NC} Downloaded Razen compiler binary"
    
    # Download all required files from the repository
    echo -e "${YELLOW}Downloading project files...${NC}"
    
    # Function to download directory contents
    download_directory() {
        local dir_name=$1
        local target_dir=$2
        local files_count=0
        local success_count=0
        
        echo -e "${YELLOW}Downloading $dir_name files...${NC}"
        
        # First try to get a file listing
        if curl -s "$RAZEN_REPO/$dir_name/" > "$TMP_DIR/filelist.html"; then
            # Extract filenames from HTML (this is a simple approach and might need adjustment)
            grep -o "href=\"[^\"]*\.rzn\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 > "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.sh\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.py\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            
            # Download each file
            while read -r file; do
                files_count=$((files_count + 1))
                if curl -s --retry 3 --retry-delay 2 -o "$target_dir/$(basename "$file")" "$RAZEN_REPO/$dir_name/$file" &>/dev/null; then
                    success_count=$((success_count + 1))
                fi
            done < "$TMP_DIR/files.txt"
            
            echo -e "  ${GREEN}✓${NC} Downloaded $success_count/$files_count files from $dir_name/"
        else
            # Fallback: try to download known files
            case "$dir_name" in
                "properties")
                    local files="variables.rzn keywords.rzn operators.rzn functions.rzn loops.rzn conditionals.rzn types.rzn api.rzn syntax.rzn"
                    ;;
                "scripts")
                    local files="razen razen-debug razen-test razen-run razen-update razen-help razen-docs razen-extension"
                    ;;
                "src")
                    local files="main.py compiler.py parser.py lexer.py interpreter.py"
                    ;;
                "examples")
                    local files="hello.rzn calculator.rzn web-example/script.rzn quiz.rzn guess.rzn"
                    ;;
                *)
                    local files=""
                    ;;
            esac
            
            for file in $files; do
                files_count=$((files_count + 1))
                mkdir -p "$target_dir/$(dirname "$file")" 2>/dev/null
                if curl -s --retry 3 --retry-delay 2 -o "$target_dir/$(basename "$file")" "$RAZEN_REPO/$dir_name/$file" &>/dev/null; then
                    success_count=$((success_count + 1))
                fi
            done
            
            echo -e "  ${GREEN}✓${NC} Downloaded $success_count/$files_count files from $dir_name/"
        fi
    }
    
    # Download each directory
    download_directory "properties" "$TMP_DIR/properties"
    download_directory "scripts" "$TMP_DIR/scripts"
    download_directory "src" "$TMP_DIR/src"
    download_directory "examples" "$TMP_DIR/examples"
fi

# Make the binary executable
chmod +x "$TMP_DIR/razen_compiler" || handle_error 7 "Failed to make binary executable" "Check file permissions"

# Make scripts executable
chmod +x "$TMP_DIR/scripts/"* || handle_error 8 "Failed to make scripts executable" "Check file permissions"
echo -e "  ${GREEN}✓${NC} Made scripts executable"

# Create installation directory
INSTALL_DIR="/usr/local/lib/razen"

# Check if installation directory exists
if [ -d "$INSTALL_DIR" ]; then
    if [ "$FORCE_UPDATE" == "true" ]; then
        echo -e "${YELLOW}Removing existing Razen installation...${NC}"
        sudo rm -rf "$INSTALL_DIR" || handle_error 9 "Failed to remove existing installation" "Check directory permissions"
    else
        echo -e "${YELLOW}Razen is already installed.${NC}"
        echo -e "${YELLOW}Use --force-update to reinstall or --update to update.${NC}"
        rm -rf "$TMP_DIR"
        exit 0
    fi
fi

# Create installation directory
echo -e "${YELLOW}Creating installation directory...${NC}"
sudo mkdir -p "$INSTALL_DIR" || handle_error 10 "Failed to create installation directory" "Check if you have sudo permissions"
sudo mkdir -p "$INSTALL_DIR/properties" || handle_error 11 "Failed to create properties directory" "Check directory permissions"
sudo mkdir -p "$INSTALL_DIR/scripts" || handle_error 12 "Failed to create scripts directory" "Check directory permissions"
echo -e "  ${GREEN}✓${NC} Created installation directory"

# Copy files to installation directory
echo -e "${YELLOW}Copying files to installation directory...${NC}"
sudo cp "$TMP_DIR/razen_compiler" "/usr/local/bin/" || handle_error 13 "Failed to copy compiler binary" "Check file permissions"
sudo cp "$TMP_DIR/properties/"*.rzn "$INSTALL_DIR/properties/" 2>/dev/null || true
sudo cp "$TMP_DIR/scripts/"* "$INSTALL_DIR/scripts/" || handle_error 14 "Failed to copy scripts" "Check file permissions"

# Save the version file to the installation directory
echo -e "${YELLOW}Saving version information...${NC}"
echo "$RAZEN_VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null || handle_error 15 "Failed to save version information" "Check file permissions"
echo -e "  ${GREEN}✓${NC} Saved version information: $RAZEN_VERSION"

# Download and save the latest installer script for future updates
if ! curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/install.sh" "$RAZEN_REPO/install.sh" &>/dev/null; then
    echo -e "${YELLOW}Warning: Could not download latest installer script. Using current version instead.${NC}"
    # If we're running from a downloaded script, copy it
    if [ -f "install.sh" ]; then
        sudo cp "install.sh" "$INSTALL_DIR/install.sh"
    fi
else
    # Copy the downloaded installer
    sudo cp "$TMP_DIR/install.sh" "$INSTALL_DIR/install.sh"
fi

# Make the installer executable
sudo chmod +x "$INSTALL_DIR/install.sh" 2>/dev/null || true

# Set proper permissions
sudo chmod -R 755 "$INSTALL_DIR" || handle_error 16 "Failed to set permissions" "Check directory permissions"
sudo chown -R root:root "$INSTALL_DIR" || handle_error 17 "Failed to set ownership" "Check if you have sudo permissions"

echo -e "  ${GREEN}✓${NC} Copied files to installation directory"

# Check for Rust installation
echo -e "${YELLOW}Checking for Rust installation...${NC}"
if command -v rustc &> /dev/null; then
    RUST_VERSION=$(rustc --version | cut -d' ' -f2)
    echo -e "  ${GREEN}✓${NC} Rust is already installed (version $RUST_VERSION)"
else
    echo -e "${YELLOW}Rust is not installed. Razen compiler requires Rust to run.${NC}"
    echo -e "${YELLOW}Installing Rust automatically...${NC}"
    
    # Ask for confirmation before installing Rust
    echo -e "${YELLOW}Do you want to install Rust now? (y/n)${NC}"
    read -p "Enter your choice: " rust_choice
    
    if [[ $rust_choice =~ ^[Yy]$ ]]; then
        # Download and run the Rust installer
        echo -e "${YELLOW}Downloading Rust installer...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || handle_error 18 "Failed to install Rust" "Try installing Rust manually"
        
        echo -e "${GREEN}✓${NC} Rust installation completed"
        
        # Source the cargo environment
        source "$HOME/.cargo/env"
        
        # Verify Rust installation
        if ! command -v rustc &> /dev/null; then
            handle_error 19 "Rust installation completed but rustc command not found" "Please restart your terminal and run the installer again"
        fi
        
        RUST_VERSION=$(rustc --version | cut -d' ' -f2)
        echo -e "  ${GREEN}✓${NC} Rust has been successfully installed (version $RUST_VERSION)"
    else
        echo -e "${RED}Rust installation skipped. Razen requires Rust to run.${NC}"
        echo -e "${YELLOW}Please install Rust manually with:${NC}"
        echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        rm -rf "$TMP_DIR"
        exit 1
    fi
fi

# Create symbolic links
create_symlinks "$INSTALL_DIR" || handle_error 20 "Failed to create symbolic links" "Check if you have sudo permissions"

# Clean up temporary files
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$TMP_DIR"
echo -e "  ${GREEN}✓${NC} Cleaned up temporary files"

# Ask about IDE extensions
echo -e "\n${YELLOW}Would you like to install IDE extensions for Razen?${NC}"
echo -e "1. ${CYAN}VS Code Extension${NC} (syntax highlighting, code completion, etc.)"
echo -e "2. ${CYAN}JetBrains Plugin${NC} (works with IntelliJ IDEA, PyCharm, WebStorm, etc.)"
echo -e "3. ${CYAN}Skip${NC} (don't install IDE extensions)"

read -p "Enter your choice (1-3): " ide_choice
echo

# Install IDE extensions based on user choice
case $ide_choice in
    1)
        echo -e "${YELLOW}Installing VS Code Extension for Razen...${NC}"
        
        # Check if VS Code is installed
        if command -v code &> /dev/null; then
            # Get VS Code extensions directory
            if [ "$(uname)" == "Darwin" ]; then
                # macOS
                VSCODE_EXT_DIR="$HOME/.vscode/extensions/razen-lang.razen-language"
            else
                # Linux
                VSCODE_EXT_DIR="$HOME/.vscode/extensions/razen-lang.razen-language"
            fi
            
            # Create the extension directory
            mkdir -p "$VSCODE_EXT_DIR"
            
            # Download VS Code extension files
            echo -e "${YELLOW}Downloading VS Code extension...${NC}"
            if ! curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/vscode-extension.zip" "$RAZEN_REPO/razen-vscode-extension.zip" &>/dev/null; then
                echo -e "  ${RED}✗${NC} Failed to download VS Code extension"
                # Copy from installation directory if available
                if [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
                    cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$VSCODE_EXT_DIR/"
                    echo -e "  ${GREEN}✓${NC} Copied VS Code extension from installation directory"
                fi
            else
                # Extract the extension
                unzip -q "$TMP_DIR/vscode-extension.zip" -d "$VSCODE_EXT_DIR"
                echo -e "  ${GREEN}✓${NC} Installed VS Code extension"
            fi
            
            echo -e "  ${GREEN}✓${NC} VS Code Extension installed"
            echo -e "  ${YELLOW}Location:${NC} $VSCODE_EXT_DIR"
            echo -e "  ${YELLOW}Restart VS Code to activate the extension${NC}"
        else
            echo -e "${YELLOW}VS Code not detected. Installing extension files only...${NC}"
            
            # Create a directory in the user's home for the extension
            VSCODE_EXT_DIR="$HOME/.razen/vscode-extension"
            mkdir -p "$VSCODE_EXT_DIR"
            
            # Copy VS Code extension files
            cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$VSCODE_EXT_DIR/" 2>/dev/null || true
            
            echo -e "  ${GREEN}✓${NC} VS Code Extension files installed to: $VSCODE_EXT_DIR"
            echo -e "  ${YELLOW}To use with VS Code, copy these files to:${NC}"
            echo -e "  ${CYAN}~/.vscode/extensions/razen-lang.razen-language/${NC}"
        fi
        ;;
    2)
        echo -e "${YELLOW}Installing JetBrains Plugin for Razen...${NC}"
        
        # Check if any JetBrains IDE is installed
        JETBRAINS_FOUND=false
        for ide_dir in "$HOME/.local/share/JetBrains" "$HOME/Library/Application Support/JetBrains"; do
            if [ -d "$ide_dir" ]; then
                JETBRAINS_FOUND=true
                break
            fi
        done
        
        # Create a directory for the JetBrains plugin
        JETBRAINS_PLUGIN_DIR="$HOME/.razen/jetbrains-plugin"
        mkdir -p "$JETBRAINS_PLUGIN_DIR"
        
        # Copy JetBrains plugin files
        cp -r "$INSTALL_DIR/razen-jetbrains-plugin/"* "$JETBRAINS_PLUGIN_DIR/" 2>/dev/null || true
        
        if [ "$JETBRAINS_FOUND" = true ]; then
            echo -e "  ${GREEN}✓${NC} JetBrains Plugin files installed to: $JETBRAINS_PLUGIN_DIR"
            echo -e "  ${YELLOW}To activate the plugin:${NC}"
            echo -e "  1. Open your JetBrains IDE"
            echo -e "  2. Go to Settings/Preferences > Plugins"
            echo -e "  3. Click the gear icon and select 'Install Plugin from Disk...'"
            echo -e "  4. Navigate to $JETBRAINS_PLUGIN_DIR and select the plugin JAR file"
            echo -e "     (You may need to build it first using Gradle)"
        else
            echo -e "  ${GREEN}✓${NC} JetBrains Plugin files installed to: $JETBRAINS_PLUGIN_DIR"
            echo -e "  ${YELLOW}No JetBrains IDE detected. To use the plugin:${NC}"
            echo -e "  1. Build the plugin using Gradle: cd $JETBRAINS_PLUGIN_DIR && ./gradlew buildPlugin"
            echo -e "  2. Install the plugin from: $JETBRAINS_PLUGIN_DIR/build/distributions/"
        fi
        ;;
    *)
        echo -e "${YELLOW}Skipping IDE extension installation.${NC}"
        echo -e "${CYAN}You can install extensions later from:${NC}"
        echo -e "  VS Code: $INSTALL_DIR/razen-vscode-extension/"
        echo -e "  JetBrains: $INSTALL_DIR/razen-jetbrains-plugin/"
        ;;
esac

# Success message
echo -e "\n${GREEN}✅ Razen has been successfully installed!${NC}"
echo -e "\n${YELLOW}Available commands:${NC}"
echo -e "  ${GREEN}razen${NC} - Run Razen programs"
echo -e "  ${GREEN}razen-debug${NC} - Run Razen programs in debug mode"
echo -e "  ${GREEN}razen-test${NC} - Run Razen tests"
echo -e "  ${GREEN}razen-run${NC} - Run Razen programs with additional options"
echo -e "  ${GREEN}razen-update${NC} - Update Razen to the latest version"
echo -e "  ${GREEN}razen-help${NC} - Show help information"
echo -e "  ${GREEN}razen new myprogram${NC} - Create a new Razen program"
echo -e "  ${GREEN}razen version${NC} - Show Razen version"
echo -e "\n${YELLOW}Example usage:${NC}"
echo -e "  ${GREEN}razen run hello_world.rzn${NC} - Run a Razen program"
echo -e "  ${GREEN}razen new myprogram${NC} - Create a new program"
echo -e "  ${GREEN}razen-update${NC} - Update Razen"
echo -e "  ${GREEN}razen-help${NC} - Get help"
echo -e "\n${YELLOW}To uninstall Razen:${NC}"
echo -e "  ${GREEN}razen uninstall${NC}"
echo -e "\n${YELLOW}Note:${NC} Razen is installed in ${GREEN}/usr/local/lib/razen${NC} for security."
echo -e "${YELLOW}Official website and documentation will be available soon.${NC}"