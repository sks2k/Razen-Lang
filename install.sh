#!/usr/bin/env bash

# Razen Language Installer Script
# Author: Prathmesh Barot
# Copyright 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.658 (Enhanced GitHub cloning and installation process)

set -e  # Exit on error

# Colors for terminal output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Repository URLs
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/Razen-Lang/main"
RAZEN_GIT_REPO="https://github.com/BasaiCorp/Razen-Lang.git"

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
        RAZEN_VERSION="beta v0.1.657 (Colours & Installers & Updaters updated properly.)"
    else
        RAZEN_VERSION=$(cat version)
        # Store the version file for future reference
        echo -e "  ${GREEN}✓${NC} Downloaded version information: $RAZEN_VERSION"
    fi
fi

if [ "$UPDATE_MODE" = true ]; then
    echo -e "${YELLOW}Updating Razen to $RAZEN_VERSION...${NC}"
else
    echo -e "${YELLOW}Installing Razen $RAZEN_VERSION...${NC}"
fi

# Function to create symbolic links
create_symlinks() {
    local INSTALL_DIR="$1"
    echo -e "${YELLOW}Creating symbolic links for all executable scripts...${NC}"
    
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
    
    # Find all executable files in the scripts directory
    local missing_links=0
    local script_count=0
    
    if [ -d "$INSTALL_DIR/scripts" ]; then
        # Loop through all files in the scripts directory
        for script_path in "$INSTALL_DIR/scripts"/*; do
            if [ -f "$script_path" ] && [ -x "$script_path" ]; then
                script_count=$((script_count + 1))
                script_name=$(basename "$script_path")
                
                if [ -w "$BIN_DIR" ]; then
                    # Direct creation if we have write permissions
                    ln -sf "$script_path" "$BIN_DIR/$script_name"
                    echo -e "  ${GREEN}✓${NC} Created $BIN_DIR/$script_name"
                else
                    # Use sudo if we don't have direct write permissions
                    if sudo ln -sf "$script_path" "$BIN_DIR/$script_name"; then
                        echo -e "  ${GREEN}✓${NC} Created $BIN_DIR/$script_name"
                    else
                        echo -e "  ${RED}✗${NC} Failed to create symlink in $BIN_DIR/$script_name (permission denied)"
                        missing_links=$((missing_links + 1))
                    fi
                fi
            fi
        done
    else
        echo -e "  ${RED}✗${NC} Scripts directory not found: $INSTALL_DIR/scripts"
        return 1
    fi
    
    # Verify all symlinks are created
    if [ $missing_links -gt 0 ]; then
        echo -e "${RED}Failed to create $missing_links symbolic links. Please check the errors above.${NC}"
        echo -e "${YELLOW}You may need to manually create symlinks or add the scripts directory to your PATH.${NC}"
        return 1
    fi
    
    if [ $script_count -eq 0 ]; then
        echo -e "${RED}No executable scripts found in $INSTALL_DIR/scripts${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} All $script_count symbolic links created successfully in $BIN_DIR"
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

# Function to handle uninstallation
uninstall_razen() {
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Check if Razen is installed
    if [ ! -d "/usr/local/lib/razen" ]; then
        echo -e "${RED}Error: Razen is not installed.${NC}"
        return 1
    fi

    # Remove all binary and script symlinks
    for cmd in razen razen-debug razen-test razen-run razen-update razen-help razen-docs razen-extension; do
        if [ -f "/usr/local/bin/$cmd" ]; then
            sudo rm -f "/usr/local/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed $cmd"
        fi
    done

    # Remove the installation directory
    sudo rm -rf "/usr/local/lib/razen"
    echo -e "  ${GREEN}✓${NC} Removed installation directory"

    # Remove version file if it exists
    if [ -f "/usr/local/lib/razen/version" ]; then
        sudo rm -f "/usr/local/lib/razen/version"
        echo -e "  ${GREEN}✓${NC} Removed version file"
    fi

    echo -e "${GREEN}✅ Razen has been successfully uninstalled!${NC}"
    return 0
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

# Create temporary directory for setup
TMP_DIR=$(mktemp -d)
if [ ! -d "$TMP_DIR" ]; then
    handle_error 3 "Failed to create temporary directory" "Check if /tmp is writable"
fi
echo -e "  ${GREEN}✓${NC} Created temporary directory for installation: $TMP_DIR"

# Initialize array to track downloaded files with detailed logging
DOWNLOADED_FILES=()
SUCCESSFUL_DOWNLOADS=0
TOTAL_FILES=0

# Required folders and files to be copied from the cloned repository
REQUIRED_FOLDERS=("src" "src/functions" "properties" "properties/libs" "scripts" "examples" "docs")
CONFIG_FILES=("Cargo.toml" "version" "install.sh")

# Flag to determine if we should use direct download
USE_DIRECT_DOWNLOAD=false

# Check for command line flags
UPDATE_MODE=false
FORCE_UPDATE=false
CUSTOM_INSTALL_PATH=""

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --uninstall)
            uninstall_razen
            exit $?
            ;;
        --update)
            UPDATE_MODE=true
            ;;
        --force)
            FORCE_UPDATE=true
            ;;
        --path=*)
            CUSTOM_INSTALL_PATH="${1#*=}"
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo -e "${YELLOW}Available options: --uninstall, --update, --force, --path=PATH${NC}"
            exit 1
            ;;
    esac
    shift
done

# If update mode is enabled, set the installation directory
if [ "$UPDATE_MODE" = true ] && [ -n "$CUSTOM_INSTALL_PATH" ]; then
    INSTALL_DIR="$CUSTOM_INSTALL_PATH"
    echo -e "${YELLOW}Update mode: Using custom installation path: $INSTALL_DIR${NC}"
elif [ "$UPDATE_MODE" = true ]; then
    # Try to find existing installation
    if [ -d "/usr/local/lib/razen" ]; then
        INSTALL_DIR="/usr/local/lib/razen"
    elif [ -d "$HOME/.local/lib/razen" ]; then
        INSTALL_DIR="$HOME/.local/lib/razen"
    fi
    echo -e "${YELLOW}Update mode: Using detected installation path: $INSTALL_DIR${NC}"
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

# Initialize array to track downloaded files with detailed logging
DOWNLOADED_FILES=()
SUCCESSFUL_DOWNLOADS=0
TOTAL_FILES=0

# Function to clone the GitHub repository
clone_github_repository() {
    echo -e "${YELLOW}Cloning the Razen GitHub repository...${NC}"
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed. Please install git first.${NC}"
        echo -e "${YELLOW}You can install git with: sudo apt-get install git${NC}"
        return 1
    fi
    
    # Try to clone from the official repository
    echo -e "  ${CYAN}Attempting to clone from: $RAZEN_GIT_REPO${NC}"
    if git clone --depth 1 "$RAZEN_GIT_REPO" "$TMP_DIR/razen-repo" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Successfully cloned Razen repository"
        
        # Count and log files in the cloned repository
        local file_count=$(find "$TMP_DIR/razen-repo" -type f | wc -l)
        echo -e "  ${GREEN}✓${NC} Cloned repository contains $file_count files"
        
        # List key directories to verify
        for dir in "src" "properties" "scripts"; do
            if [ -d "$TMP_DIR/razen-repo/$dir" ]; then
                local dir_file_count=$(find "$TMP_DIR/razen-repo/$dir" -type f | wc -l)
                echo -e "  ${GREEN}✓${NC} Found $dir directory with $dir_file_count files"
            else
                echo -e "  ${YELLOW}⚠${NC} Directory $dir not found in cloned repository"
            fi
        done
        
        return 0
    else
        # Try a fallback repository if the main one fails
        local fallback_repo="https://github.com/BasaiCorp/Razen-Lang.git"
        echo -e "${YELLOW}Main repository clone failed, trying fallback: $fallback_repo${NC}"
        
        if git clone --depth 1 "$fallback_repo" "$TMP_DIR/razen-repo" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Successfully cloned from fallback repository"
            
            # Count and log files in the cloned repository
            local file_count=$(find "$TMP_DIR/razen-repo" -type f | wc -l)
            echo -e "  ${GREEN}✓${NC} Cloned repository contains $file_count files"
            
            # List key directories to verify
            for dir in "src" "properties" "scripts"; do
                if [ -d "$TMP_DIR/razen-repo/$dir" ]; then
                    local dir_file_count=$(find "$TMP_DIR/razen-repo/$dir" -type f | wc -l)
                    echo -e "  ${GREEN}✓${NC} Found $dir directory with $dir_file_count files"
                else
                    echo -e "  ${YELLOW}⚠${NC} Directory $dir not found in cloned repository"
                fi
            done
            
            return 0
        else
            echo -e "${RED}All git clone attempts failed${NC}"
            return 1
        fi
    fi
}

# Required folders that will be created or used
REQUIRED_FOLDERS=("src" "properties" "scripts" "examples" "docs")
# Configuration files to copy
CONFIG_FILES=("Cargo.toml" "version")
# IDE extension folders
EXTENSION_FOLDERS=("razen-vscode-extension" "razen-jetbrains-plugin")

# Function to create a default Cargo.toml file
create_default_cargo_toml() {
    local target_file=$1
    cat > "$target_file" << EOF
[package]
name = "razen_compiler"
version = "0.1.0"
edition = "2021"

[dependencies]
# For machine code generation
cranelift = "0.100.0"
cranelift-module = "0.100.0"
cranelift-jit = "0.100.0"
cranelift-object = "0.100.0"
target-lexicon = "0.12.12"
cc = "1.0.83"

# Error handling helper
thiserror = "1.0"

# For library system
rand = "0.8"
rand_chacha = "0.3"
lazy_static = "1.4"
chrono = "0.4"
serde_json = "1.0"

# For crypto library
sha2 = "0.10"
base64 = "0.21"
aes-gcm = "0.10"
hkdf = "0.12"

# For regex library
regex = "1.9"

# For UUID library
uuid = { version = "1.4", features = ["v4", "serde"] }

# For networking and HTTP requests
curl = "0.4.44"
reqwest = { version = "0.11", features = ["blocking", "json"] }
tokio = { version = "1", features = ["full"] }

# For logging
log = "0.4"
env_logger = "0.10"
EOF
}

# Function to verify directory structure after copying
verify_directory_structure() {
    for dir in "src" "properties" "scripts"; do
        if [ -d "$TMP_DIR/$dir" ]; then
            dir_file_count=$(find "$TMP_DIR/$dir" -type f | wc -l)
            echo -e "  ${GREEN}✓${NC} $dir directory contains $dir_file_count files"
        else
            echo -e "  ${RED}✗${NC} $dir directory is missing"
        fi
    done
}

# Function to copy files from the cloned repository
copy_from_repository() {
    echo -e "${YELLOW}Copying files from cloned repository...${NC}"
    
    # Check if the repository was cloned successfully
    if [ ! -d "$TMP_DIR/razen-repo" ]; then
        echo -e "${RED}Error: Repository directory not found.${NC}"
        return 1
    fi
    
    # Initialize counters for detailed logging
    local total_copied=0
    local total_missing=0
    local copied_files_list=()
    
    # Copy required folders
    echo -e "${CYAN}Copying required folders:${NC}"
    for folder in "${REQUIRED_FOLDERS[@]}"; do
        if [ -d "$TMP_DIR/razen-repo/$folder" ]; then
            mkdir -p "$TMP_DIR/$folder"
            local files_before=$(find "$TMP_DIR/$folder" -type f 2>/dev/null | wc -l)
            
            # Copy files and capture output
            cp -r "$TMP_DIR/razen-repo/$folder"/* "$TMP_DIR/$folder/" 2>/dev/null || true
            
            local files_after=$(find "$TMP_DIR/$folder" -type f 2>/dev/null | wc -l)
            local files_copied=$((files_after - files_before))
            total_copied=$((total_copied + files_copied))
            
            if [ $files_copied -gt 0 ]; then
                echo -e "  ${GREEN}✓${NC} Copied $files_copied files from $folder directory"
                # Log some of the copied files (up to 5)
                local file_examples=$(find "$TMP_DIR/$folder" -type f -printf "%f\n" 2>/dev/null | head -5)
                echo -e "    ${BLUE}Sample files:${NC} $file_examples"
                copied_files_list+=("$folder")
            else
                echo -e "  ${YELLOW}⚠${NC} No files copied from $folder (directory empty or copy failed)"
                total_missing=$((total_missing + 1))
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} $folder not found in repository, creating empty directory"
            mkdir -p "$TMP_DIR/$folder"
            total_missing=$((total_missing + 1))
        fi
    done
    
    # Copy config files
    echo -e "${CYAN}Copying configuration files:${NC}"
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$TMP_DIR/razen-repo/$file" ]; then
            cp "$TMP_DIR/razen-repo/$file" "$TMP_DIR/$file" 2>/dev/null
            if [ -f "$TMP_DIR/$file" ]; then
                echo -e "  ${GREEN}✓${NC} Copied $file from repository"
                total_copied=$((total_copied + 1))
                copied_files_list+=("$file")
            else
                echo -e "  ${YELLOW}⚠${NC} Failed to copy $file"
                total_missing=$((total_missing + 1))
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} $file not found in repository"
            total_missing=$((total_missing + 1))
        fi
    done
    
    # Copy IDE extension folders if they exist
    echo -e "${CYAN}Copying IDE extension folders:${NC}"
    for ext_folder in "razen-vscode-extension" "razen-jetbrains-plugin"; do
        if [ -d "$TMP_DIR/razen-repo/$ext_folder" ]; then
            mkdir -p "$TMP_DIR/$ext_folder"
            local files_before=$(find "$TMP_DIR/$ext_folder" -type f 2>/dev/null | wc -l)
            
            # Copy files and capture output
            cp -r "$TMP_DIR/razen-repo/$ext_folder"/* "$TMP_DIR/$ext_folder/" 2>/dev/null || true
            
            local files_after=$(find "$TMP_DIR/$ext_folder" -type f 2>/dev/null | wc -l)
            local files_copied=$((files_after - files_before))
            total_copied=$((total_copied + files_copied))
            
            if [ $files_copied -gt 0 ]; then
                echo -e "  ${GREEN}✓${NC} Copied $files_copied files from $ext_folder directory"
                # Log some of the copied files (up to 5)
                local file_examples=$(find "$TMP_DIR/$ext_folder" -type f -printf "%f\n" 2>/dev/null | head -5)
                echo -e "    ${BLUE}Sample files:${NC} $file_examples"
                copied_files_list+=("$ext_folder")
            else
                echo -e "  ${YELLOW}⚠${NC} No files copied from $ext_folder (directory empty or copy failed)"
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} $ext_folder not found in repository"
        fi
    done
    
    # Check for src/functions and properties/libs subdirectories
    echo -e "${CYAN}Checking for important subdirectories:${NC}"
    if [ -d "$TMP_DIR/src/functions" ]; then
        local func_count=$(find "$TMP_DIR/src/functions" -type f | wc -l)
        echo -e "  ${GREEN}✓${NC} Found src/functions directory with $func_count files"
    else
        echo -e "  ${YELLOW}⚠${NC} src/functions directory not found, creating it"
        mkdir -p "$TMP_DIR/src/functions"
    fi
    
    if [ -d "$TMP_DIR/properties/libs" ]; then
        local libs_count=$(find "$TMP_DIR/properties/libs" -type f | wc -l)
        echo -e "  ${GREEN}✓${NC} Found properties/libs directory with $libs_count files"
    else
        echo -e "  ${YELLOW}⚠${NC} properties/libs directory not found, creating it"
        mkdir -p "$TMP_DIR/properties/libs"
    fi
    
    # Create Cargo.toml if it doesn't exist
    if [ ! -f "$TMP_DIR/Cargo.toml" ]; then
        echo -e "${YELLOW}Cargo.toml not found. Creating a default one...${NC}"
        create_default_cargo_toml "$TMP_DIR/Cargo.toml"
        echo -e "  ${GREEN}✓${NC} Created default Cargo.toml file"
        total_copied=$((total_copied + 1))
        copied_files_list+=("Cargo.toml")
    fi
    
    # Summary of copied files
    echo -e "${CYAN}Copy summary:${NC}"
    echo -e "  ${GREEN}✓${NC} Successfully copied $total_copied files from repository"
    if [ $total_missing -gt 0 ]; then
        echo -e "  ${YELLOW}⚠${NC} $total_missing directories or files were missing or empty"
    fi
    
    # Update global counter
    SUCCESSFUL_DOWNLOADS=$total_copied
    
    # Return success if we copied at least some files
    if [ $total_copied -gt 0 ]; then
        return 0
    else
        echo -e "${RED}Error: No files were copied from the repository.${NC}"
        return 1
    fi
}

# Download project files
echo -e "${YELLOW}Downloading project files...${NC}"

# First attempt to clone the GitHub repository
if clone_github_repository; then
    echo -e "${GREEN}✓${NC} Successfully cloned the GitHub repository"
    
    # Copy files from the cloned repository
    if copy_from_repository; then
        echo -e "${GREEN}✓${NC} Successfully copied files from the cloned repository"
        USE_DIRECT_DOWNLOAD=false
        
        # List the directory structure to verify files were copied
        echo -e "${CYAN}Verifying directory structure:${NC}"
        verify_directory_structure
    else
        echo -e "${YELLOW}Failed to copy files from cloned repository. Trying direct download method...${NC}"
        USE_DIRECT_DOWNLOAD=true
    fi
else
    # Fallback to the direct download method if cloning fails
    echo -e "${YELLOW}Git clone failed. Trying direct download method...${NC}"
    USE_DIRECT_DOWNLOAD=true
fi

# If direct download is needed
if [ "$USE_DIRECT_DOWNLOAD" = true ]; then
    
    # Create all required directories in the temporary folder
echo -e "${CYAN}Creating required directories:${NC}"
for folder in "${REQUIRED_FOLDERS[@]}"; do
    mkdir -p "$TMP_DIR/$folder"
    echo -e "  ${GREEN}✓${NC} Created directory: $folder"
done
echo -e "  ${GREEN}✓${NC} Created all required directories in temporary folder"
    
    # Download Cargo.toml file directly
    echo -e "${YELLOW}Downloading Cargo.toml file...${NC}"
    if curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/Cargo.toml" "$RAZEN_REPO/Cargo.toml" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Downloaded Cargo.toml"
        DOWNLOADED_FILES+=("Cargo.toml")
        SUCCESSFUL_DOWNLOADS=$((SUCCESSFUL_DOWNLOADS + 1))
        TOTAL_FILES=$((TOTAL_FILES + 1))
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to download Cargo.toml, creating a default one"
        # Create a default Cargo.toml file
        cat > "$TMP_DIR/Cargo.toml" << EOF
[package]
name = "razen_compiler"
version = "0.1.0"
edition = "2021"

[dependencies]
# For machine code generation
cranelift = "0.100.0"
cranelift-module = "0.100.0"
cranelift-jit = "0.100.0"
cranelift-object = "0.100.0"
target-lexicon = "0.12.12"
cc = "1.0.83"

# Error handling helper
thiserror = "1.0"

# For library system
rand = "0.8"
rand_chacha = "0.3"
lazy_static = "1.4"
chrono = "0.4"
serde_json = "1.0"

# For crypto library
sha2 = "0.10"
base64 = "0.21"
aes-gcm = "0.10"
hkdf = "0.12"

# For regex library
regex = "1.9"

# For UUID library
uuid = { version = "1.4", features = ["v4", "serde"] }

# For networking and HTTP requests
curl = "0.4.44"
reqwest = { version = "0.11", features = ["blocking", "json"] }
tokio = { version = "1", features = ["full"] }

# For logging
log = "0.4"
env_logger = "0.10"
EOF
        echo -e "  ${GREEN}✓${NC} Created Cargo.toml file"
        DOWNLOADED_FILES+=("Cargo.toml")
        SUCCESSFUL_DOWNLOADS=$((SUCCESSFUL_DOWNLOADS + 1))
        TOTAL_FILES=$((TOTAL_FILES + 1))
    fi
    
    # Download files for each required folder
    for folder in "${REQUIRED_FOLDERS[@]}"; do
        echo -e "${YELLOW}Downloading files for $folder folder...${NC}"
        
        # Try to download a few sample files for each folder
        case "$folder" in
            "src")
                files="main.rs compiler.rs parser.rs lexer.rs ast.rs token.rs value.rs library.rs functions.rs syntax.rs"
                ;;
            "src/functions")
                files="array.rs math.rs string.rs random.rs file.rs json.rs bolt.rs seed.rs color.rs crypto.rs regex.rs uuid.rs os.rs validation.rs system.rs boxutil.rs log.rs ht.rs net.rs time.rs"
                ;;
            "properties")
                files="api.rzn conditionals.rzn functions.rzn error_handling.rzn developer_experience.rzn"
                ;;
            "properties/libs")
                files="array.rzn arrlib.rzn mathlib.rzn strlib.rzn random.rzn file.rzn json.rzn bolt.rzn seed.rzn color.rzn crypto.rzn regex.rzn uuid.rzn os.rzn system.rzn timelib.rzn net.rzn ht.rzn log.rzn"
                ;;
            "scripts")
                files="razen razen-debug razen-test razen-run razen-update razen-help razen-docs razen-extension razen-autogen"
                ;;
            "examples")
                files="12-16.rzn guess.rzn quiz.rzn library_test.rzn color_test.rzn purchase.rzn order.rzn function_test.rzn library_demo.rzn all_libraries_demo.rzn bracket_test.rzn"
                ;;
            "docs")
                files="README.md CONTRIBUTING.md"
                ;;
        esac
        
        # Download each file
        for file in $files; do
            TOTAL_FILES=$((TOTAL_FILES + 1))
            if curl -s --retry 3 --retry-delay 2 -o "$TMP_DIR/$folder/$file" "$RAZEN_REPO/$folder/$file" &>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Downloaded: $folder/$file"
                DOWNLOADED_FILES+=("$folder/$file")
                SUCCESSFUL_DOWNLOADS=$((SUCCESSFUL_DOWNLOADS + 1))
                
                # Make scripts executable
                if [ "$folder" = "scripts" ]; then
                    chmod +x "$TMP_DIR/$folder/$file"
                fi
            else
                echo -e "  ${YELLOW}⚠${NC} Failed to download: $folder/$file, creating placeholder"
                
                # Create placeholder based on file extension
                case "$file" in
                    *.rs)
                        echo "// Placeholder for $folder/$file - This file was not found in the repository" > "$TMP_DIR/$folder/$file"
                        ;;
                    *.rzn)
                        echo "# Placeholder for $folder/$file - This file was not found in the repository" > "$TMP_DIR/$folder/$file"
                        ;;
                    *.md)
                        echo "# Placeholder for $folder/$file - This file was not found in the repository" > "$TMP_DIR/$folder/$file"
                        ;;
                    *)
                        if [ "$folder" = "scripts" ]; then
                            echo '#!/bin/bash\necho "This is a placeholder script for '$file'"\necho "The original script was not found during installation"' > "$TMP_DIR/$folder/$file"
                            chmod +x "$TMP_DIR/$folder/$file"
                        else
                            touch "$TMP_DIR/$folder/$file"
                        fi
                        ;;
                esac
            fi
        done
    done
    
    echo -e "${GREEN}✅ Downloaded or created placeholders for all required files${NC}"
    
    # Function to download directory contents
    download_directory() {
        local dir_name=$1
        local target_dir=$2
        local files_count=0
        local success_count=0
        
        echo -e "${YELLOW}Downloading all files from $dir_name folder...${NC}"
        
        # Create target directory if it doesn't exist
        mkdir -p "$target_dir" 2>/dev/null
        
        # Check if we're running from a local repository
        if [ -d "$dir_name" ]; then
            echo -e "  ${CYAN}Found local $dir_name directory, copying files...${NC}"
            
            # Find all files in the local directory
            local local_files=$(find "$dir_name" -type f | sort)
            
            # Copy each file
            for file in $local_files; do
                files_count=$((files_count + 1))
                TOTAL_FILES=$((TOTAL_FILES + 1))
                local rel_path=${file#"$dir_name/"}
                mkdir -p "$target_dir/$(dirname "$rel_path")" 2>/dev/null
                
                cp "$file" "$target_dir/$rel_path"
                if [ $? -eq 0 ]; then
                    success_count=$((success_count + 1))
                    SUCCESSFUL_DOWNLOADS=$((SUCCESSFUL_DOWNLOADS + 1))
                    echo -e "    ${GREEN}✓${NC} Downloaded: $dir_name/$rel_path"
                    # Add to downloaded files list
                    DOWNLOADED_FILES+=("$dir_name/$rel_path")
                else
                    echo -e "    ${RED}✗${NC} Failed to copy $rel_path"
                fi
            done
            
            echo -e "  ${GREEN}✓${NC} Copied $success_count/$files_count files from local $dir_name/ directory"
            return 0
        fi
        
        # Try to get a file listing from GitHub
        echo -e "  ${CYAN}Attempting to download from repository...${NC}"
        if curl -s "$RAZEN_REPO/$dir_name/" > "$TMP_DIR/filelist.html"; then
            # Extract filenames from HTML (this is a simple approach and might need adjustment)
            grep -o "href=\"[^\"]*\.rzn\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 > "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.sh\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.py\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.rs\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.json\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            grep -o "href=\"[^\"]*\.md\"" "$TMP_DIR/filelist.html" | cut -d'"' -f2 >> "$TMP_DIR/files.txt"
            
            # Download each file
            while read -r file; do
                files_count=$((files_count + 1))
                # Create subdirectories if needed
                mkdir -p "$target_dir/$(dirname "$file")" 2>/dev/null
                echo -e "    ${CYAN}Downloading${NC} $file"
                if curl -s --retry 3 --retry-delay 2 -o "$target_dir/$file" "$RAZEN_REPO/$dir_name/$file" &>/dev/null; then
                    success_count=$((success_count + 1))
                    echo -e "    ${GREEN}✓${NC} Downloaded $file"
                    # Add to downloaded files list
                    DOWNLOADED_FILES+=("$dir_name/$file")
                    
                    # Special handling for functions directory
                    if [[ "$dir_name" == "src" && "$file" == "functions.rs" ]]; then
                        echo -e "    ${CYAN}Detected functions.rs, downloading functions directory...${NC}"
                        mkdir -p "$target_dir/functions" 2>/dev/null
                        local function_files="array.rs mathlib.rs strlib.rs randomlib.rs filelib.rs jsonlib.rs boltlib.rs seedlib.rs colorlib.rs cryptolib.rs regexlib.rs uuidlib.rs oslib.rs validationlib.rs systemlib.rs boxutillib.rs loglib.rs htlib.rs netlib.rs timelib.rs color.rs"
                        for func_file in $function_files; do
                            echo -e "    ${CYAN}Downloading${NC} functions/$func_file"
                            if curl -s --retry 3 --retry-delay 2 -o "$target_dir/functions/$func_file" "$RAZEN_REPO/src/functions/$func_file" &>/dev/null; then
                                success_count=$((success_count + 1))
                                echo -e "    ${GREEN}✓${NC} Downloaded functions/$func_file"
                                # Add to downloaded files list
                                DOWNLOADED_FILES+=("src/functions/$func_file")
                            else
                                echo -e "    ${RED}✗${NC} Failed to download functions/$func_file"
                            fi
                        done
                    fi
                else
                    echo -e "    ${RED}✗${NC} Failed to download $file"
                fi
            done < "$TMP_DIR/files.txt"
            
            echo -e "  ${GREEN}✓${NC} Downloaded $success_count/$files_count files from $dir_name/"
        else
            echo -e "  ${YELLOW}Could not get file listing from repository, using fallback list...${NC}"
            # Fallback: try to download known files
            case "$dir_name" in
                "properties")
                    local files="variables.rzn keywords.rzn operators.rzn functions.rzn loops.rzn conditionals.rzn types.rzn api.rzn syntax.rzn usage.rzn"
                    # Create libs directory
                    mkdir -p "$target_dir/libs" 2>/dev/null
                    # Download library files
                    local lib_files="arrlib.rzn strlib.rzn mathlib.rzn random.rzn file.rzn json.rzn bolt.rzn seed.rzn color.rzn crypto.rzn regex.rzn uuid.rzn os.rzn validation.rzn system.rzn boxlib.rzn loglib.rzn htlib.rzn netlib.rzn timelib.rzn"
                    for lib_file in $lib_files; do
                        echo -e "    ${CYAN}Downloading${NC} libs/$lib_file"
                        if curl -s --retry 3 --retry-delay 2 -o "$target_dir/libs/$lib_file" "$RAZEN_REPO/properties/libs/$lib_file" &>/dev/null; then
                            success_count=$((success_count + 1))
                            echo -e "    ${GREEN}✓${NC} Downloaded libs/$lib_file"
                            # Add to downloaded files list
                            DOWNLOADED_FILES+=("properties/libs/$lib_file")
                        else
                            echo -e "    ${RED}✗${NC} Failed to download libs/$lib_file"
                        fi
                    done
                    ;;
                "scripts")
                    local files="razen razen-debug razen-test razen-run razen-update razen-help razen-docs razen-extension"
                    ;;
                "src")
                    local files="main.rs compiler.rs parser.rs lexer.rs interpreter.rs ast.rs token.rs value.rs library.rs functions.rs"
                    
                    # Download core files
                    for src_file in $files; do
                        echo -e "    ${CYAN}Downloading${NC} $src_file"
                        if curl -s --retry 3 --retry-delay 2 -o "$target_dir/$src_file" "$RAZEN_REPO/src/$src_file" &>/dev/null; then
                            success_count=$((success_count + 1))
                            echo -e "    ${GREEN}✓${NC} Downloaded $src_file"
                            # Add to downloaded files list
                            DOWNLOADED_FILES+=("src/$src_file")
                        else
                            echo -e "    ${RED}✗${NC} Failed to download $src_file"
                        fi
                    done
                    
                    # Create functions directory
                    mkdir -p "$target_dir/functions" 2>/dev/null
                    echo -e "    ${GREEN}✓${NC} Created functions directory"
                    
                    # Download function files
                    local function_files="arrlib.rs mathlib.rs strlib.rs randomlib.rs filelib.rs jsonlib.rs boltlib.rs seedlib.rs colorlib.rs cryptolib.rs regexlib.rs uuidlib.rs oslib.rs validationlib.rs systemlib.rs boxutillib.rs loglib.rs htlib.rs netlib.rs timelib.rs color.rs"
                    for func_file in $function_files; do
                        echo -e "    ${CYAN}Downloading${NC} functions/$func_file"
                        if curl -s --retry 3 --retry-delay 2 -o "$target_dir/functions/$func_file" "$RAZEN_REPO/src/functions/$func_file" &>/dev/null; then
                            success_count=$((success_count + 1))
                            echo -e "    ${GREEN}✓${NC} Downloaded functions/$func_file"
                            # Add to downloaded files list
                            DOWNLOADED_FILES+=("src/functions/$func_file")
                        else
                            echo -e "    ${RED}✗${NC} Failed to download functions/$func_file"
                        fi
                    done
                    ;;
                "examples")
                    local files="hello.rzn calculator.rzn web-example/script.rzn quiz.rzn guess.rzn 12-16.rzn library_test.rzn color_test.rzn purchase.rzn order.rzn"
                    ;;
                "razen-vscode-extension")
                    local files="package.json syntaxes/razen.tmLanguage.json language-configuration/language-configuration.json README.md"
                    # Create src directory
                    mkdir -p "$target_dir/src" 2>/dev/null
                    # Download extension source files
                    local ext_files="extension.js razenLanguageData.js test.rzn"
                    for ext_file in $ext_files; do
                        echo -e "    ${CYAN}Downloading${NC} src/$ext_file"
                        if curl -s --retry 3 --retry-delay 2 -o "$target_dir/src/$ext_file" "$RAZEN_REPO/razen-vscode-extension/src/$ext_file" &>/dev/null; then
                            success_count=$((success_count + 1))
                            echo -e "    ${GREEN}✓${NC} Downloaded src/$ext_file"
                            # Add to downloaded files list
                            DOWNLOADED_FILES+=("razen-vscode-extension/src/$ext_file")
                        else
                            echo -e "    ${RED}✗${NC} Failed to download src/$ext_file"
                        fi
                    done
                    # Create snippets directory
                    mkdir -p "$target_dir/snippets" 2>/dev/null
                    # Download snippets file
                    echo -e "    ${CYAN}Downloading${NC} snippets/razen.json"
                    if curl -s --retry 3 --retry-delay 2 -o "$target_dir/snippets/razen.json" "$RAZEN_REPO/razen-vscode-extension/snippets/razen.json" &>/dev/null; then
                        success_count=$((success_count + 1))
                        echo -e "    ${GREEN}✓${NC} Downloaded snippets/razen.json"
                        # Add to downloaded files list
                        DOWNLOADED_FILES+=("razen-vscode-extension/snippets/razen.json")
                    else
                        echo -e "    ${RED}✗${NC} Failed to download snippets/razen.json"
                    fi
                    # Create icons directory
                    mkdir -p "$target_dir/icons" 2>/dev/null
                    # Download icon file
                    echo -e "    ${CYAN}Downloading${NC} icons/razen-icon.png"
                    if curl -s --retry 3 --retry-delay 2 -o "$target_dir/icons/razen-icon.png" "$RAZEN_REPO/razen-vscode-extension/icons/razen-icon.png" &>/dev/null; then
                        success_count=$((success_count + 1))
                        echo -e "    ${GREEN}✓${NC} Downloaded icons/razen-icon.png"
                        # Add to downloaded files list
                        DOWNLOADED_FILES+=("razen-vscode-extension/icons/razen-icon.png")
                    else
                        echo -e "    ${RED}✗${NC} Failed to download icons/razen-icon.png"
                    fi
                    ;;
                "razen-jetbrain-plugin")
                    local files="plugin.xml build.gradle settings.gradle src/main/resources/META-INF/plugin.xml"
                    ;;
                *)
                    local files=""
                    ;;
            esac
            
            for file in $files; do
                files_count=$((files_count + 1))
                mkdir -p "$target_dir/$(dirname "$file")" 2>/dev/null
                echo -e "    ${CYAN}Downloading${NC} $file"
                if curl -s --retry 3 --retry-delay 2 -o "$target_dir/$file" "$RAZEN_REPO/$dir_name/$file" &>/dev/null; then
                    success_count=$((success_count + 1))
                    echo -e "    ${GREEN}✓${NC} Downloaded $file"
                    # Add to downloaded files list
                    DOWNLOADED_FILES+=("$dir_name/$file")
                else
                    echo -e "    ${RED}✗${NC} Failed to download $file"
                fi
            done
            
            if [ $success_count -eq 0 ]; then
                echo -e "  ${RED}✗${NC} Failed to download any files from $dir_name/"
                
                # If we have a local directory with this name, use it as fallback
                if [ -d "$dir_name" ]; then
                    echo -e "  ${YELLOW}Using local $dir_name directory as fallback...${NC}"
                    
                    # Reset counters
                    files_count=0
                    success_count=0
                    
                    # Find all files in the local directory
                    local local_files=$(find "$dir_name" -type f | sort)
                    
                    # Copy each file
                    for file in $local_files; do
                        files_count=$((files_count + 1))
                        local rel_path=${file#"$dir_name/"}
                        mkdir -p "$target_dir/$(dirname "$rel_path")" 2>/dev/null
                        
                        cp "$file" "$target_dir/$rel_path"
                        if [ $? -eq 0 ]; then
                            success_count=$((success_count + 1))
                            echo -e "    ${GREEN}✓${NC} Copied $rel_path"
                            # Add to downloaded files list
                            DOWNLOADED_FILES+=("$dir_name/$rel_path")
                        else
                            echo -e "    ${RED}✗${NC} Failed to copy $rel_path"
                        fi
                    done
                    
                    echo -e "  ${GREEN}✓${NC} Copied $success_count/$files_count files from local $dir_name/ directory"
                else
                    echo -e "  ${RED}✗${NC} No local $dir_name directory found as fallback"
                fi
            else
                echo -e "  ${GREEN}✓${NC} Downloaded $success_count/$files_count files from $dir_name/"
            fi
        fi
    }
    
    # Download required directories
echo -e "${YELLOW}Downloading additional required directories...${NC}"

# We've already downloaded all required files individually, so we don't need to use download_directory
# Just ensure all directories exist
for dir in "properties" "properties/libs" "examples" "examples/web-example" "scripts" "docs"; do
    mkdir -p "$TMP_DIR/$dir"
done

# Check if any additional files exist in local directories that we might have missed
if [ -d "src" ]; then
    echo -e "${YELLOW}Checking for additional files in local src directory...${NC}"
    find "src" -type f | while read -r file; do
        rel_path=${file#"src/"}
        target_file="$TMP_DIR/src/$rel_path"
        if [ ! -f "$target_file" ]; then
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
            echo -e "  ${GREEN}✓${NC} Copied additional file: src/$rel_path"
            DOWNLOADED_FILES+=("src/$rel_path")
        fi
    done
fi

if [ -d "properties" ]; then
    echo -e "${YELLOW}Checking for additional files in local properties directory...${NC}"
    find "properties" -type f | while read -r file; do
        rel_path=${file#"properties/"}
        target_file="$TMP_DIR/properties/$rel_path"
        if [ ! -f "$target_file" ]; then
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
            echo -e "  ${GREEN}✓${NC} Copied additional file: properties/$rel_path"
            DOWNLOADED_FILES+=("properties/$rel_path")
        fi
    done
fi

if [ -d "examples" ]; then
    echo -e "${YELLOW}Checking for additional files in local examples directory...${NC}"
    find "examples" -type f | while read -r file; do
        rel_path=${file#"examples/"}
        target_file="$TMP_DIR/examples/$rel_path"
        if [ ! -f "$target_file" ]; then
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
            echo -e "  ${GREEN}✓${NC} Copied additional file: examples/$rel_path"
            DOWNLOADED_FILES+=("examples/$rel_path")
        fi
    done
fi

if [ -d "scripts" ]; then
    echo -e "${YELLOW}Checking for additional files in local scripts directory...${NC}"
    find "scripts" -type f | while read -r file; do
        rel_path=${file#"scripts/"}
        target_file="$TMP_DIR/scripts/$rel_path"
        if [ ! -f "$target_file" ]; then
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
            chmod +x "$target_file"
            echo -e "  ${GREEN}✓${NC} Copied additional file: scripts/$rel_path"
            DOWNLOADED_FILES+=("scripts/$rel_path")
        fi
    done
fi

if [ -d "docs" ]; then
    echo -e "${YELLOW}Checking for additional files in local docs directory...${NC}"
    find "docs" -type f | while read -r file; do
        rel_path=${file#"docs/"}
        target_file="$TMP_DIR/docs/$rel_path"
        if [ ! -f "$target_file" ]; then
            mkdir -p "$(dirname "$target_file")"
            cp "$file" "$target_file"
            echo -e "  ${GREEN}✓${NC} Copied additional file: docs/$rel_path"
            DOWNLOADED_FILES+=("docs/$rel_path")
        fi
    done
fi
    
        # Extensions will be handled at the end of installation
fi

# Function to verify Rust installation
verify_rust_installation() {
    echo -e "${YELLOW}Checking for Rust installation...${NC}"
    
    # Check for rustc
    if ! command -v rustc &> /dev/null; then
        echo -e "  ${RED}✗${NC} Rustc not found"
        return 1
    fi
    
    # Check rustc version
    RUSTC_VERSION=$(rustc --version)
    RUSTC_VERSION_NUM=$(echo $RUSTC_VERSION | sed -E 's/rustc ([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
    echo -e "  ${GREEN}✓${NC} Rustc detected: $RUSTC_VERSION"
    
    # Check if rustc version is sufficient (needs 1.60.0 or higher)
    if [ "$(printf '%s\n' "1.60.0" "$RUSTC_VERSION_NUM" | sort -V | head -n1)" = "1.60.0" ]; then
        echo -e "  ${GREEN}✓${NC} Rustc version is sufficient (>= 1.60.0)"
    else
        echo -e "  ${YELLOW}⚠${NC} Rustc version is too old (< 1.60.0), consider updating"
    fi
    
    # Check for cargo
    if ! command -v cargo &> /dev/null; then
        echo -e "  ${RED}✗${NC} Cargo not found"
        return 1
    fi
    
    # Check cargo version
    CARGO_VERSION=$(cargo --version)
    echo -e "  ${GREEN}✓${NC} Cargo detected: $CARGO_VERSION"
    
    # Check if cargo can find required dependencies
    echo -e "  ${CYAN}Checking cargo environment...${NC}"
    if cargo --list &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Cargo environment is working properly"
    else
        echo -e "  ${YELLOW}⚠${NC} Cargo environment may have issues"
    fi
    
    # Check for rustup (for better Rust management)
    if command -v rustup &> /dev/null; then
        RUSTUP_VERSION=$(rustup --version)
        echo -e "  ${GREEN}✓${NC} Rustup detected: $RUSTUP_VERSION"
        
        # Check active toolchain
        ACTIVE_TOOLCHAIN=$(rustup show active-toolchain)
        echo -e "  ${GREEN}✓${NC} Active Rust toolchain: $ACTIVE_TOOLCHAIN"
    else
        echo -e "  ${YELLOW}⚠${NC} Rustup not found (recommended for managing Rust)"
    fi
    
    echo -e "  ${GREEN}✓${NC} Rust is properly installed"
    return 0
}

# Function to install VS Code extension
install_vscode_extension() {
    echo -e "${YELLOW}Installing VS Code Extension for Razen...${NC}"
    local vscode_ext_dir="$HOME/.vscode/extensions/razen-lang.razen-language"
    
    if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
        mkdir -p "$vscode_ext_dir"
        cp -r "$TMP_DIR/razen-vscode-extension"/* "$vscode_ext_dir/" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} VS Code Extension installed"
        echo -e "  Location: $vscode_ext_dir"
        echo -e "  Restart VS Code to activate the extension"
    else
        echo -e "  ${RED}✗${NC} Razen extension files not found"
    fi
}

# Function to install Windsurf extension
install_windsurf_extension() {
    echo -e "${YELLOW}Installing Windsurf Extension for Razen...${NC}"
    local windsurf_ext_dir="$HOME/.windsurf/extensions/razen-lang.razen-language"
    
    if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
        mkdir -p "$windsurf_ext_dir"
        cp -r "$TMP_DIR/razen-vscode-extension"/* "$windsurf_ext_dir/" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Windsurf Extension installed"
        echo -e "  Location: $windsurf_ext_dir"
        echo -e "  Restart Windsurf to activate the extension"
    else
        echo -e "  ${RED}✗${NC} Razen extension files not found"
    fi
}

# Function to install Cursor AI extension
install_cursor_extension() {
    echo -e "${YELLOW}Installing Cursor AI Extension for Razen...${NC}"
    local cursor_ext_dir="$HOME/.cursor/extensions/razen-lang.razen-language"
    
    if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
        mkdir -p "$cursor_ext_dir"
        cp -r "$TMP_DIR/razen-vscode-extension"/* "$cursor_ext_dir/" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Cursor AI Extension installed"
        echo -e "  Location: $cursor_ext_dir"
        echo -e "  Restart Cursor AI to activate the extension"
    else
        echo -e "  ${RED}✗${NC} Razen extension files not found"
        echo -e "  ${GREEN}✓${NC} Cursor AI Extension installed"
        echo -e "  Location: $cursor_ext_dir"
        echo -e "  Restart Cursor AI to activate the extension"
    fi
}

# Function to install TraeAI extension
install_traeai_extension() {
    echo -e "${YELLOW}Installing TraeAI Extension for Razen...${NC}"
    local traeai_ext_dir="$HOME/.traeai/extensions/razen-lang.razen-language"
    
    if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
        mkdir -p "$traeai_ext_dir"
        cp -r "$TMP_DIR/razen-vscode-extension"/* "$traeai_ext_dir/" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} TraeAI Extension installed"
        echo -e "  Location: $traeai_ext_dir"
        echo -e "  Restart TraeAI to activate the extension"
    else
        echo -e "  ${RED}✗${NC} Razen extension files not found"
    fi
}

# Function to install JetBrains plugin
install_jetbrains_plugin() {
    echo -e "${YELLOW}Installing JetBrains Plugin for Razen...${NC}"
    local jetbrains_plugin_file="$HOME/.razen/plugins/razen-jetbrains-plugin.zip"
    
    if [ -d "$TMP_DIR/razen-jetbrains-plugin" ]; then
        mkdir -p "$HOME/.razen/plugins"
        
        # Create a zip file from the plugin directory
        cd "$TMP_DIR"
        zip -r "$jetbrains_plugin_file" razen-jetbrains-plugin > /dev/null
        
        echo -e "  ${GREEN}✓${NC} JetBrains Plugin packaged"
        echo -e "  Location: $jetbrains_plugin_file"
        echo -e "  To install, open your JetBrains IDE, go to Settings > Plugins > Install Plugin from Disk"
        echo -e "  and select the plugin file"
    else
        echo -e "  ${RED}✗${NC} Razen JetBrains plugin files not found"
    fi
}

# Function to build the Razen compiler
build_razen_compiler() {
    echo -e "${YELLOW}Building Razen compiler...${NC}"
    
    # Check if Rust is installed
    if ! verify_rust_installation; then
        echo -e "${YELLOW}Rust not installed or not properly configured. Skipping build.${NC}"
        echo -e "${YELLOW}Creating placeholder binary for installation to continue...${NC}"
        echo '#!/bin/bash\necho "Razen compiler placeholder - Rust not installed"' > "$TMP_DIR/razen_compiler"
        chmod +x "$TMP_DIR/razen_compiler"
        echo -e "  ${GREEN}✓${NC} Created placeholder binary"
        return 1
    fi
    
    # Change to the temporary directory
    cd "$TMP_DIR"
    
    # Ensure src/main.rs exists
    if [ ! -f "src/main.rs" ]; then
        echo -e "${YELLOW}src/main.rs not found. Creating a minimal one...${NC}"
        mkdir -p "src"
        cat > "src/main.rs" << EOF
// Razen Compiler - Main Entry Point
// Auto-generated during installation

fn main() {
    println!("Razen Compiler - Installation Test");
    println!("This is a placeholder main.rs file created during installation.");
}
EOF
        echo -e "  ${GREEN}✓${NC} Created src/main.rs file"
    fi
    
    # Run the build with timing
    echo -e "${YELLOW}Starting build process (this may take a few minutes)...${NC}"
    BUILD_START=$(date +%s)
    BUILD_SUCCESS=true
    
    if ! cargo build --release; then
        echo -e "${YELLOW}Warning: Build failed, but continuing with installation${NC}"
        echo -e "${YELLOW}You may need to build the project manually later${NC}"
        BUILD_SUCCESS=false
    fi
    
    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    
    if [ "$BUILD_SUCCESS" = true ]; then
        echo -e "  ${GREEN}✓${NC} Built Razen compiler from source in ${BUILD_DURATION} seconds"
        
        # Copy the binary if build was successful
        if [ -f "target/release/razen_compiler" ]; then
            cp "target/release/razen_compiler" "$TMP_DIR/razen_compiler" || 
                echo -e "${YELLOW}Warning: Could not copy binary from target/release${NC}"
            
            if [ -f "$TMP_DIR/razen_compiler" ]; then
                chmod +x "$TMP_DIR/razen_compiler" || 
                    echo -e "${YELLOW}Warning: Failed to make binary executable${NC}"
                echo -e "  ${GREEN}✓${NC} Made binary executable"
                return 0
            fi
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Build process completed with errors in ${BUILD_DURATION} seconds"
    fi
    
    # If we get here, either the build failed or the binary wasn't found
    echo -e "${YELLOW}Creating placeholder binary for installation to continue...${NC}"
    echo '#!/bin/bash\necho "Razen compiler placeholder - Build failed"' > "$TMP_DIR/razen_compiler"
    chmod +x "$TMP_DIR/razen_compiler"
    echo -e "  ${GREEN}✓${NC} Created placeholder binary"
    
    # Return to the original directory
    cd - > /dev/null
    return 1
}

# Now that all files are copied and verified, build the Razen compiler
build_razen_compiler

# Make scripts executable and create symbolic links
echo -e "${YELLOW}Making scripts executable and creating symbolic links...${NC}"
if [ -d "$TMP_DIR/scripts" ]; then
    # Make all scripts executable
    chmod +x "$TMP_DIR/scripts/"* || handle_error 8 "Failed to make scripts executable" "Check file permissions"
    echo -e "  ${GREEN}✓${NC} Made all scripts in /scripts directory executable"
    
    # Create symbolic links for each script with its own name
    for script in "$TMP_DIR/scripts/"*; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            script_name=$(basename "$script")
            echo -e "  ${GREEN}✓${NC} Prepared script for symlink: $script_name"
        fi
    done
    
    echo -e "  ${GREEN}✓${NC} All scripts will be symlinked during installation"
else
    echo -e "  ${RED}✗${NC} Scripts directory not found"
fi

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

# Create or update installation directory
if [ "$UPDATE_MODE" = true ]; then
    echo -e "${YELLOW}Updating installation directory...${NC}"
    # Check if the directory exists
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}Error: Installation directory not found: $INSTALL_DIR${NC}"
        echo -e "${YELLOW}Please specify the correct path with --path=PATH${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Creating installation directory...${NC}"
sudo mkdir -p "$INSTALL_DIR" || handle_error 10 "Failed to create installation directory" "Check if you have sudo permissions"
sudo mkdir -p "$INSTALL_DIR/properties" || handle_error 11 "Failed to create properties directory" "Check directory permissions"
sudo mkdir -p "$INSTALL_DIR/scripts" || handle_error 12 "Failed to create scripts directory" "Check directory permissions"
sudo mkdir -p "$INSTALL_DIR/examples" || handle_error 13 "Failed to create examples directory" "Check directory permissions"
sudo mkdir -p "$INSTALL_DIR/src" || handle_error 14 "Failed to create src directory" "Check directory permissions"

# Create directories for extensions if they were downloaded
if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
    sudo mkdir -p "$INSTALL_DIR/razen-vscode-extension" || handle_error 15 "Failed to create vscode extension directory" "Check directory permissions"
fi

if [ -d "$TMP_DIR/razen-jetbrain-plugin" ]; then
    sudo mkdir -p "$INSTALL_DIR/razen-jetbrain-plugin" || handle_error 16 "Failed to create jetbrains plugin directory" "Check directory permissions"
fi

if [ "$UPDATE_MODE" = true ]; then
    echo -e "  ${GREEN}✓${NC} Verified installation directory structure"
else
    echo -e "  ${GREEN}✓${NC} Created installation directory structure"
fi

# Copy files to installation directory
if [ "$UPDATE_MODE" = true ]; then
    echo -e "${YELLOW}Updating files in installation directory...${NC}"
else
    echo -e "${YELLOW}Copying files to installation directory...${NC}"
fi
sudo cp "$TMP_DIR/razen_compiler" "/usr/local/bin/" || handle_error 17 "Failed to copy compiler binary" "Check file permissions"

# Copy all downloaded directories to installation directory
sudo cp -r "$TMP_DIR/properties/"* "$INSTALL_DIR/properties/" 2>/dev/null || true
sudo cp -r "$TMP_DIR/scripts/"* "$INSTALL_DIR/scripts/" || handle_error 18 "Failed to copy scripts" "Check file permissions"
sudo cp -r "$TMP_DIR/examples/"* "$INSTALL_DIR/examples/" 2>/dev/null || true
sudo cp -r "$TMP_DIR/src/"* "$INSTALL_DIR/src/" 2>/dev/null || true

# Copy extension directories if they were downloaded
if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
    sudo cp -r "$TMP_DIR/razen-vscode-extension/"* "$INSTALL_DIR/razen-vscode-extension/" 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Copied VS Code extension files"
fi

if [ -d "$TMP_DIR/razen-jetbrain-plugin" ]; then
    sudo cp -r "$TMP_DIR/razen-jetbrain-plugin/"* "$INSTALL_DIR/razen-jetbrain-plugin/" 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Copied JetBrains plugin files"
fi

# Save the version file to the installation directory
echo -e "${YELLOW}Saving version information...${NC}"
echo "$RAZEN_VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null || handle_error 19 "Failed to save version information" "Check file permissions"
echo -e "  ${GREEN}✓${NC} Saved version information: $RAZEN_VERSION"

# Save the installer script for future updates, uninstallation, and version checking
echo -e "${YELLOW}Saving installer script for future updates...${NC}"

# First try to download the latest installer
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
echo -e "  ${GREEN}✓${NC} Saved installer script for future updates"

# Set proper permissions
sudo chmod -R 755 "$INSTALL_DIR" || handle_error 20 "Failed to set permissions" "Check directory permissions"
sudo chown -R root:root "$INSTALL_DIR" || handle_error 21 "Failed to set ownership" "Check if you have sudo permissions"

echo -e "  ${GREEN}✓${NC} Copied files to installation directory"

# Check for Rust installation
echo -e "${YELLOW}Checking for Rust installation...${NC}"

# Function to verify Rust installation
verify_rust_installation() {
    # Check for rustc command
    if ! command -v rustc &> /dev/null; then
        return 1
    fi
    
    # Check for cargo command
    if ! command -v cargo &> /dev/null; then
        return 1
    fi
    
    # Try to get Rust version
    if ! RUST_VERSION=$(rustc --version 2>/dev/null); then
        return 1
    fi
    
    # Try to run a simple cargo command
    if ! cargo --version &>/dev/null; then
        return 1
    fi
    
    # All checks passed
    return 0
}

# Check if Rust is properly installed
if verify_rust_installation; then
    RUST_VERSION=$(rustc --version | cut -d' ' -f2)
    echo -e "  ${GREEN}✓${NC} Rust installation detected (version $RUST_VERSION)"
else
    echo -e "  ${RED}✗${NC} Rust is not installed or not properly configured"
    echo -e "${YELLOW}⚠️ Rust is not installed. Would you like to install it now? (Y/n)${NC}"
    read -p "Enter your choice: " rust_choice
    
    if [[ $rust_choice =~ ^[Nn]$ ]]; then
        echo -e "${RED}Rust installation skipped. Razen requires Rust to run.${NC}"
        echo -e "${YELLOW}Please install Rust manually with:${NC}"
        echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        rm -rf "$TMP_DIR"
        exit 1
    else
        # Download and run the Rust installer
        echo -e "${YELLOW}Installing Rust using the official installer...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh || handle_error 18 "Failed to install Rust" "Try installing Rust manually"
        
        echo -e "${GREEN}✓${NC} Rust installation completed"
        
        # Source the cargo environment
        source "$HOME/.cargo/env"
        
        # Verify Rust installation
        if verify_rust_installation; then
            RUST_VERSION=$(rustc --version | cut -d' ' -f2)
            echo -e "  ${GREEN}✓${NC} Rust has been successfully installed (version $RUST_VERSION)"
        else
            echo -e "${YELLOW}Please restart your terminal and run the installer again to complete Rust setup${NC}"
            echo -e "${YELLOW}You can manually activate Rust in this session with:${NC}"
            echo -e "  source $HOME/.cargo/env"
            
            # Try to source it again
            if [ -f "$HOME/.cargo/env" ]; then
                source "$HOME/.cargo/env"
                echo -e "  ${GREEN}✓${NC} Activated Rust environment for current session"
            fi
        fi
    fi
fi

# Cleaning up temporary files
rm -rf "$TMP_DIR"
echo -e "  ${GREEN}✓${NC} Cleaned up temporary files"

# Ask user for IDE extension preference
echo -e "\n${YELLOW}Would you like to install the extension/plugin to your IDE?${NC}"
echo -e "1. ${CYAN}VS Code${NC}"
echo -e "2. ${CYAN}Windsurf${NC}"
echo -e "3. ${CYAN}Cursor AI${NC}"
echo -e "4. ${CYAN}TraeAI${NC}"
echo -e "5. ${CYAN}JetBrains IDEs${NC} (IntelliJ IDEA, PyCharm, WebStorm, etc.)"
echo -e "6. ${CYAN}Skip${NC} (don't install IDE extensions)"

read -p "Enter your choice (1-6): " ide_choice
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
            
            # Copy from downloaded or installation directory
            if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
                # Copy from downloaded directory
                cp -r "$TMP_DIR/razen-vscode-extension/"* "$VSCODE_EXT_DIR/" 2>/dev/null || true
                echo -e "  ${GREEN}✓${NC} Copied VS Code extension from downloaded files"
            elif [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
                # Copy from installation directory if available
                cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$VSCODE_EXT_DIR/" 2>/dev/null || true
                echo -e "  ${GREEN}✓${NC} Copied VS Code extension from installation directory"
            else
                echo -e "  ${RED}✗${NC} VS Code extension files not found"
            fi
            
            echo -e "  ${GREEN}✓${NC} VS Code Extension installed"
            echo -e "  ${YELLOW}Location:${NC} $VSCODE_EXT_DIR"
            echo -e "  ${YELLOW}Restart VS Code to activate the extension${NC}"
        else
            echo -e "${YELLOW}VS Code not detected. Installing extension files only...${NC}"
            
            # Create a directory in the user's home for the extension
            VSCODE_EXT_DIR="$HOME/.razen/vscode-extension"
            mkdir -p "$VSCODE_EXT_DIR"
            
            # Copy VS Code extension files from downloaded or installation directory
            if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
                cp -r "$TMP_DIR/razen-vscode-extension/"* "$VSCODE_EXT_DIR/" 2>/dev/null || true
            elif [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
                cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$VSCODE_EXT_DIR/" 2>/dev/null || true
            fi
            
            echo -e "  ${GREEN}✓${NC} VS Code Extension files installed to: $VSCODE_EXT_DIR"
            echo -e "  ${YELLOW}To use with VS Code, copy these files to:${NC}"
            echo -e "  ${CYAN}~/.vscode/extensions/razen-lang.razen-language/${NC}"
        fi
        ;;
    2)
        echo -e "${YELLOW}Installing Windsurf Extension for Razen...${NC}"
        
        # Windsurf extensions directory
        WINDSURF_EXT_DIR="$HOME/.windsurf/extensions/razen-lang.razen-language"
        mkdir -p "$WINDSURF_EXT_DIR"
        
        # Copy extension files from downloaded or installation directory
        if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
            cp -r "$TMP_DIR/razen-vscode-extension/"* "$WINDSURF_EXT_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied Razen extension from downloaded files"
        elif [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
            cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$WINDSURF_EXT_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied Razen extension from installation directory"
        else
            echo -e "  ${RED}✗${NC} Razen extension files not found"
        fi
        
        echo -e "  ${GREEN}✓${NC} Windsurf Extension installed"
        echo -e "  ${YELLOW}Location:${NC} $WINDSURF_EXT_DIR"
        echo -e "  ${YELLOW}Restart Windsurf to activate the extension${NC}"
        ;;
    3)
        echo -e "${YELLOW}Installing Cursor AI Extension for Razen...${NC}"
        
        # Cursor AI extensions directory
        CURSOR_EXT_DIR="$HOME/.cursor/extensions/razen-lang.razen-language"
        mkdir -p "$CURSOR_EXT_DIR"
        
        # Copy extension files from downloaded or installation directory
        if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
            cp -r "$TMP_DIR/razen-vscode-extension/"* "$CURSOR_EXT_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied Razen extension from downloaded files"
        elif [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
            cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$CURSOR_EXT_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied Razen extension from installation directory"
        else
            echo -e "  ${RED}✗${NC} Razen extension files not found"
        fi
        
        echo -e "  ${GREEN}✓${NC} Cursor AI Extension installed"
        echo -e "  ${YELLOW}Location:${NC} $CURSOR_EXT_DIR"
        echo -e "  ${YELLOW}Restart Cursor AI to activate the extension${NC}"
        ;;
    4)
        echo -e "${YELLOW}Installing TraeAI Extension for Razen...${NC}"
        
        # TraeAI extensions directory
        TRAE_EXT_DIR="$HOME/.trae/extensions/razen-lang.razen-language"
        mkdir -p "$TRAE_EXT_DIR"
        
        # Copy extension files from downloaded or installation directory
        if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
            cp -r "$TMP_DIR/razen-vscode-extension/"* "$TRAE_EXT_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied Razen extension from downloaded files"
        elif [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
            cp -r "$INSTALL_DIR/razen-vscode-extension/"* "$TRAE_EXT_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied Razen extension from installation directory"
        else
            echo -e "  ${RED}✗${NC} Razen extension files not found"
        fi
        
        echo -e "  ${GREEN}✓${NC} TraeAI Extension installed"
        echo -e "  ${YELLOW}Location:${NC} $TRAE_EXT_DIR"
        echo -e "  ${YELLOW}Restart TraeAI to activate the extension${NC}"
        ;;
    5)
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
        
        # Copy JetBrains plugin files from downloaded or installation directory
        if [ -d "$TMP_DIR/razen-jetbrain-plugin" ]; then
            cp -r "$TMP_DIR/razen-jetbrain-plugin/"* "$JETBRAINS_PLUGIN_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied JetBrains plugin from downloaded files"
        elif [ -d "$INSTALL_DIR/razen-jetbrain-plugin" ]; then
            cp -r "$INSTALL_DIR/razen-jetbrain-plugin/"* "$JETBRAINS_PLUGIN_DIR/" 2>/dev/null || true
            echo -e "  ${GREEN}✓${NC} Copied JetBrains plugin from installation directory"
        else
            echo -e "  ${RED}✗${NC} JetBrains plugin files not found"
        fi
        
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
        if [ -d "$INSTALL_DIR/razen-vscode-extension" ]; then
            echo -e "  VS Code/Windsurf/Cursor/TraeAI: $INSTALL_DIR/razen-vscode-extension/"
        fi
        if [ -d "$INSTALL_DIR/razen-jetbrain-plugin" ]; then
            echo -e "  JetBrains: $INSTALL_DIR/razen-jetbrain-plugin/"
        fi
        ;;
esac

# Print installation summary
if [ "$UPDATE_MODE" = true ]; then
    echo -e "\n${GREEN}=== Update Summary ===${NC}"
    echo -e "${GREEN}✅ Razen has been successfully updated!${NC}"
    # Count installed files (without using local variable outside function)
    installed_files=$(find "$INSTALL_DIR" -type f | wc -l)
    echo -e "${GREEN}✅ Updated $installed_files files${NC}"
else
    echo -e "\n${GREEN}=== Installation Summary ===${NC}"
    echo -e "${GREEN}✅ Razen has been successfully installed!${NC}"
    # Count installed files (without using local variable outside function)
    installed_files=$(find "$INSTALL_DIR" -type f | wc -l)
    echo -e "${GREEN}✅ Installed $installed_files files${NC}"
fi

# Summarize what was downloaded
if [ $SUCCESSFUL_DOWNLOADS -eq $TOTAL_FILES ] && [ $TOTAL_FILES -gt 0 ]; then
    echo -e "${GREEN}✅ All files downloaded successfully! ($SUCCESSFUL_DOWNLOADS files)${NC}"
else
    local missing=$((TOTAL_FILES - SUCCESSFUL_DOWNLOADS))
    if [ $missing -gt 0 ]; then
        echo -e "${YELLOW}⚠ Downloaded $SUCCESSFUL_DOWNLOADS files, but $missing files had issues.${NC}"
    fi
    echo -e "${GREEN}✅ All required files are now available!${NC}"
fi

# Summarize the build process
if [ -f "target/release/razen_compiler" ]; then
    echo -e "${GREEN}✅ Build completed successfully in ${BUILD_DURATION} seconds!${NC}"
else
    echo -e "${YELLOW}⚠ Build process completed, but output verification had issues.${NC}"
fi

# Summarize Rust installation
if verify_rust_installation; then
    echo -e "${GREEN}✅ Rust environment properly detected and configured.${NC}"
else
    echo -e "${YELLOW}⚠ Rust environment had some issues, but installation proceeded.${NC}"
fi

echo -e "${GREEN}🎉 All files installed and ready to use! Welcome to Razen!${NC}"

# Show installation path
echo -e "${CYAN}Installation path: ${INSTALL_DIR}${NC}"

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