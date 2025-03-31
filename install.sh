#!/usr/bin/env bash

# Razen Language Installer Script
# Author: Prathmesh Barot
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.36

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

# Get version from the version file
if [ -f "version" ]; then
    RAZEN_VERSION=$(cat version)
else
    # Download version file if not present
    if ! curl -s -o version "$RAZEN_REPO/version" &>/dev/null; then
        echo -e "${RED}Failed to download version information. Using default version.${NC}"
        RAZEN_VERSION="beta v0.1.36"
    else
        RAZEN_VERSION=$(cat version)
    fi
fi

echo -e "${YELLOW}Installing Razen ${PURPLE}$RAZEN_VERSION${NC}"

# Function to create symbolic links
create_symlinks() {
    local INSTALL_DIR="$1"
    echo -e "${YELLOW}Creating symbolic links...${NC}"
    
    # List of all scripts that need symlinks
    SCRIPTS="razen razen-debug razen-test razen-run razen-update razen-help"
    
    # Create symlinks in /usr/local/bin
    for script in $SCRIPTS; do
        if [ -f "$INSTALL_DIR/scripts/$script" ]; then
            sudo ln -sf "$INSTALL_DIR/scripts/$script" "/usr/local/bin/$script"
            echo -e "  ${GREEN}✓${NC} Created /usr/local/bin/$script"
        else
            echo -e "  ${RED}✗${NC} Failed to create /usr/local/bin/$script (file not found)"
        fi
    done
    
    # Create symlinks in /usr/bin
    for script in $SCRIPTS; do
        if [ -f "/usr/local/bin/$script" ]; then
            sudo ln -sf "/usr/local/bin/$script" "/usr/bin/$script"
            echo -e "  ${GREEN}✓${NC} Created /usr/bin/$script"
        else
            echo -e "  ${RED}✗${NC} Failed to create /usr/bin/$script (file not found)"
        fi
    done
    
    # Verify all symlinks are created
    local missing_links=0
    for script in $SCRIPTS; do
        if [ ! -f "/usr/local/bin/$script" ] || [ ! -L "/usr/bin/$script" ]; then
            echo -e "  ${RED}✗${NC} Missing symlink for $script"
            missing_links=$((missing_links + 1))
        fi
    done
    
    if [ $missing_links -gt 0 ]; then
        echo -e "${RED}Failed to create some symbolic links. Please check the errors above.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} All symbolic links created successfully"
    return 0
}

# Function to check for updates
check_for_updates() {
    echo -e "${YELLOW}Checking for updates...${NC}"
    
    # Download version check file
    if ! curl -s -o "$TMP_DIR/version.txt" "$RAZEN_REPO/version" &>/dev/null; then
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
    if ! curl -s -o "$TMP_DIR/install.sh" "$RAZEN_REPO/install.sh" &>/dev/null; then
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
echo -e "${YELLOW}Programming Language ${PURPLE}$RAZEN_VERSION${NC}"
echo -e "${CYAN}By Prathmesh Barot, Basai Corporation${NC}"
echo -e "${YELLOW}Copyright © 2025 Prathmesh Barot${NC}\n"
sleep 1  # Add a small delay to make the banner more readable

# Prepare installation
echo -e "${YELLOW}Preparing Razen installation...${NC}"

# Create temporary directory for installation
TMP_DIR=$(mktemp -d)
echo -e "  ${GREEN}✓${NC} Created temporary directory for installation"

# Check for uninstall flag
if [ "$1" == "--uninstall" ]; then
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Remove all binary and script symlinks
    for cmd in razen razen-debug razen-test razen-run razen-update razen-help; do
        if [ -f "/usr/local/bin/$cmd" ]; then
            sudo rm "/usr/local/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/$cmd"
        fi
        if [ -L "/usr/bin/$cmd" ]; then
            sudo rm "/usr/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed symlink /usr/bin/$cmd"
        fi
    done
    
    # Remove installation directory
    if [ -d "/usr/local/lib/razen" ]; then
        sudo rm -rf /usr/local/lib/razen
        echo -e "  ${GREEN}✓${NC} Removed /usr/local/lib/razen directory"
    fi
    
    echo -e "\n${GREEN}✅ Razen has been successfully uninstalled!${NC}"
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
        read -p "Do you want to update Razen? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Update cancelled.${NC}"
            echo -e "${GREEN}Tip:${NC} You can use 'razen-update' to update Razen later."
            rm -rf "$TMP_DIR"
            exit 0
        fi
        
        # Perform the update
        perform_update
        if [ $? -ne 0 ]; then
            echo -e "${RED}Update failed. Please try again later.${NC}"
            rm -rf "$TMP_DIR"
            exit 1
        fi
        exit 0
    elif [ $UPDATE_STATUS -eq 0 ]; then
        echo -e "${GREEN}Razen is already up to date.${NC}"
        rm -rf "$TMP_DIR"
        exit 0
    else
        echo -e "${RED}Failed to check for updates.${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
fi

# Download Razen files
echo -e "${YELLOW}Downloading Razen files...${NC}"

# Create necessary directories in temp folder
mkdir -p "$TMP_DIR/src"
mkdir -p "$TMP_DIR/scripts"
mkdir -p "$TMP_DIR/properties"

# Download main.py
if ! curl -s -o "$TMP_DIR/main.py" "$RAZEN_REPO/main.py" &>/dev/null; then
    echo -e "${RED}Failed to download main.py${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Downloaded main.py"

# Download requirements.txt
if ! curl -s -o "$TMP_DIR/requirements.txt" "$RAZEN_REPO/requirements.txt" &>/dev/null; then
    echo -e "${RED}Failed to download requirements.txt${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Downloaded requirements.txt"

# Download src files
for file in lexer.py parser.py interpreter.py runtime.py; do
    if ! curl -s -o "$TMP_DIR/src/$file" "$RAZEN_REPO/src/$file" &>/dev/null; then
        echo -e "${RED}Failed to download src/$file${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    echo -e "  ${GREEN}✓${NC} Downloaded src/$file"
done

# Download properties files
for file in variables.rzn keywords.rzn operators.rzn; do
    if ! curl -s -o "$TMP_DIR/properties/$file" "$RAZEN_REPO/properties/$file" &>/dev/null; then
        # Create empty file if download fails
        touch "$TMP_DIR/properties/$file"
        echo -e "  ${YELLOW}⚠${NC} Created empty properties/$file"
    else
        echo -e "  ${GREEN}✓${NC} Downloaded properties/$file"
    fi
done

# Download script files
for script in razen razen-debug razen-test razen-run razen-update razen-help; do
    if ! curl -s -o "$TMP_DIR/scripts/$script" "$RAZEN_REPO/scripts/$script" &>/dev/null; then
        # Create empty file if download fails
        touch "$TMP_DIR/scripts/$script"
        echo -e "  ${YELLOW}⚠${NC} Created empty scripts/$script"
    else
        echo -e "  ${GREEN}✓${NC} Downloaded scripts/$script"
    fi
done

# Make scripts executable
chmod +x "$TMP_DIR/scripts/"*
echo -e "  ${GREEN}✓${NC} Made scripts executable"

# Create installation directory
INSTALL_DIR="/usr/local/lib/razen"

# Check if installation directory exists
if [ -d "$INSTALL_DIR" ]; then
    if [ "$FORCE_UPDATE" == "true" ]; then
        echo -e "${YELLOW}Removing existing Razen installation...${NC}"
        sudo rm -rf "$INSTALL_DIR"
    else
        echo -e "${YELLOW}Razen is already installed.${NC}"
        echo -e "${YELLOW}New Razen commands are available with this version.${NC}"
        read -p "Do you want to update Razen? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Installation cancelled.${NC}"
            echo -e "${GREEN}Tip:${NC} You can use 'razen-update' to update Razen later."
            rm -rf "$TMP_DIR"
            exit 0
        fi
        echo -e "${YELLOW}Updating Razen...${NC}"
        sudo rm -rf "$INSTALL_DIR"
    fi
fi

sudo mkdir -p "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR/src"
sudo mkdir -p "$INSTALL_DIR/scripts"
sudo mkdir -p "$INSTALL_DIR/properties"
echo -e "  ${GREEN}✓${NC} Created installation directory"

# Copy files to installation directory
sudo cp "$TMP_DIR/main.py" "$INSTALL_DIR/"
sudo cp "$TMP_DIR/src/"*.py "$INSTALL_DIR/src/" 2>/dev/null || true
sudo cp "$TMP_DIR/properties/"*.rzn "$INSTALL_DIR/properties/"
sudo cp "$TMP_DIR/scripts/"* "$INSTALL_DIR/scripts/"

# Download and save the latest installer script for future updates
if ! curl -s -o "$TMP_DIR/install.sh" "$RAZEN_REPO/install.sh" &>/dev/null; then
    echo -e "${YELLOW}Warning: Could not download latest installer script. Using current version instead.${NC}"
    # If we're running from a downloaded script, copy it
    if [ -f "$0" ] && [[ "$0" != "/usr/local/bin/"* ]]; then
        sudo cp "$0" "$INSTALL_DIR/install.sh"
    fi
else
    sudo cp "$TMP_DIR/install.sh" "$INSTALL_DIR/install.sh"
    sudo chmod +x "$INSTALL_DIR/install.sh"
    echo -e "${GREEN}  ✓${NC} Saved latest installer script for future updates"
fi

# Create version file with proper permissions
echo "$RAZEN_VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null

# Create an empty __init__.py file in each directory to make them proper Python packages
sudo touch "$INSTALL_DIR/__init__.py"
sudo touch "$INSTALL_DIR/src/__init__.py"

# Set proper permissions
sudo chmod -R 755 "$INSTALL_DIR"
sudo chown -R root:root "$INSTALL_DIR"

echo -e "  ${GREEN}✓${NC} Copied files to installation directory"

# Install Python dependencies
echo -e "${YELLOW}Installing Python dependencies...${NC}"
if ! pip3 install -r "$TMP_DIR/requirements.txt"; then
    echo -e "${RED}Failed to install Python dependencies. Please install them manually:${NC}"
    echo -e "  pip3 install -r $TMP_DIR/requirements.txt"
    rm -rf "$TMP_DIR"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Installed Python dependencies"

# Generate parser tables
echo -e "${YELLOW}Generating parser tables...${NC}"
cd "$TMP_DIR"
export PYTHONPATH="$TMP_DIR/src:$PYTHONPATH"

# Clean up old parser tables
rm -f "$TMP_DIR/src/parser_parsetab.py" "$TMP_DIR/src/parser.out" "$TMP_DIR/src/razen_parsetab.py"

if ! python3 -c "
import os
import sys
os.chdir('src')
try:
    import ply.yacc as yacc
    from lexer import tokens
    from parser import *
    
    # Force clean build
    parser = yacc.yacc(
        debug=True,
        write_tables=True,
        tabmodule='parser_parsetab',
        outputdir='.',
        optimize=False,
        errorlog=yacc.PlyLogger(sys.stderr)  # Enable error logging
    )
    print('Parser tables generated successfully')
except Exception as e:
    print(f'Error: {str(e)}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"; then
    echo -e "${RED}Failed to generate parser tables. Please check the parser implementation.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Copy generated parser tables to installation directory
if [ -f "$TMP_DIR/src/parser_parsetab.py" ]; then
    sudo cp "$TMP_DIR/src/parser_parsetab.py" "$INSTALL_DIR/src/"
    echo -e "  ${GREEN}✓${NC} Copied parser tables"
fi

cd - > /dev/null
echo -e "  ${GREEN}✓${NC} Generated parser tables"

# Create symbolic links
create_symlinks "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to create symbolic links.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Clean up
rm -rf "$TMP_DIR"
echo -e "  ${GREEN}✓${NC} Cleaned up temporary files"

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