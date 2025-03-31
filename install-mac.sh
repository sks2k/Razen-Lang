#!/bin/bash

# Razen Language Installer for macOS
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.3

# Repository URL
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"
RAZEN_VERSION="beta v0.1.3"

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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
            return 1
        fi
    done
    
    # Verify all symlinks are created
    local missing_links=0
    for script in $SCRIPTS; do
        if [ ! -f "/usr/local/bin/$script" ]; then
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
    if ! curl -s -o "$TMP_DIR/install-mac.sh" "$RAZEN_REPO/install-mac.sh" &>/dev/null; then
        echo -e "${RED}Failed to download the latest installer.${NC}"
        return 1
    fi
    
    # Make it executable
    chmod +x "$TMP_DIR/install-mac.sh"
    
    # Run the installer with the latest version
    sudo "$TMP_DIR/install-mac.sh"
    
    return $?
}

# Function to uninstall Razen
uninstall_razen() {
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Remove all binary and script symlinks
    for cmd in razen razen-debug razen-test razen-run razen-update razen-help; do
        if [ -f "/usr/local/bin/$cmd" ]; then
            sudo rm "/usr/local/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/$cmd"
        fi
    done
    
    # Remove installation directory
    if [ -d "/usr/local/razen" ]; then
        sudo rm -rf /usr/local/razen
        echo -e "  ${GREEN}✓${NC} Removed /usr/local/razen directory"
    fi
    
    echo -e "\n${GREEN}✅ Razen has been successfully uninstalled!${NC}"
    exit 0
}

# Print banner
echo -e "${BLUE}"
cat << "EOF"
██████╗  █████╗ ███████╗███████╗███╗   ██╗
██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║
██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║
██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║
██║  ██║██║  ██║███████╗███████╗██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝
EOF

echo -e "${YELLOW}Programming Language ${RAZEN_VERSION}${NC}"
echo -e "${CYAN}By Prathmesh Barot, Basai Corporation${NC}"
echo -e "${YELLOW}Copyright © 2025 Prathmesh Barot\n${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script requires root privileges.${NC}"
    echo -e "${YELLOW}Please run with sudo and try again.${NC}"
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)
echo -e "${GREEN}  ✓ Created temporary directory${NC}"

# Check for uninstall flag
if [ "$1" == "--uninstall" ]; then
    uninstall_razen
fi

# Check for update flag or if already installed
if [ "$1" == "update" ] || [ "$1" == "--update" ] || [ -f "/usr/local/bin/razen" ]; then
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

# Create installation directory
INSTALL_DIR="/usr/local/razen"
echo -e "${YELLOW}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
echo -e "${GREEN}  ✓ Created installation directory${NC}"

# Download files
echo -e "\n${YELLOW}Downloading Razen files...${NC}"

# Download main files
files=(
    "main.py"
    "parser/parser.py"
    "parser/lexer.py"
    "parser/ast.py"
    "utils/utils.py"
    "utils/error.py"
)

for file in "${files[@]}"; do
    url="$RAZEN_REPO/$file"
    outfile="$TMP_DIR/$(basename "$file")"
    if curl -s -o "$outfile" "$url"; then
        echo -e "${GREEN}  ✓ Downloaded $file${NC}"
    else
        echo -e "${RED}  ✗ Failed to download $file${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
done

# Download scripts
scripts=(
    "razen"
    "razen-debug"
    "razen-test"
    "razen-run"
    "razen-update"
    "razen-help"
)

mkdir -p "$TMP_DIR/scripts"
for script in "${scripts[@]}"; do
    url="$RAZEN_REPO/scripts/$script"
    outfile="$TMP_DIR/scripts/$script"
    if curl -s -o "$outfile" "$url"; then
        echo -e "${GREEN}  ✓ Downloaded $script${NC}"
    else
        echo -e "${RED}  ✗ Failed to download $script${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
done

# Make scripts executable
chmod +x "$TMP_DIR/scripts/"*
echo -e "${GREEN}  ✓ Made scripts executable${NC}"

# Copy files to installation directory
echo -e "\n${YELLOW}Installing files...${NC}"
cp -r "$TMP_DIR"/* "$INSTALL_DIR/"
echo -e "${GREEN}  ✓ Copied files to installation directory${NC}"

# Create version file
echo "$RAZEN_VERSION" > "$INSTALL_DIR/version"
echo -e "${GREEN}  ✓ Created version file${NC}"

# Create symbolic links
create_symlinks "$INSTALL_DIR"
if [ $? -ne 0 ]; then
    rm -rf "$TMP_DIR"
    exit 1
fi

# Clean up
echo -e "\n${YELLOW}Cleaning up...${NC}"
rm -rf "$TMP_DIR"
echo -e "${GREEN}  ✓ Cleaned up temporary files${NC}"

# Success message
echo -e "\n${GREEN}✅ Razen has been successfully installed!${NC}"
echo -e "\n${YELLOW}Available commands:${NC}"
echo -e "${GREEN}  razen - Run Razen programs${NC}"
echo -e "${GREEN}  razen-debug - Run programs in debug mode${NC}"
echo -e "${GREEN}  razen-test - Run programs in test mode${NC}"
echo -e "${GREEN}  razen-run - Run programs with clean output${NC}"
echo -e "${GREEN}  razen-update - Update Razen to the latest version${NC}"
echo -e "${GREEN}  razen-help - Show help information${NC}"
echo -e "${GREEN}  razen new myprogram - Create a new program${NC}"
echo -e "${GREEN}  razen version - Show version information${NC}"
echo -e "${GREEN}  razen uninstall - Remove Razen from your system${NC}"

echo -e "\n${YELLOW}Example usage:${NC}"
echo -e "${GREEN}  razen run hello_world.rzn - Run a Razen program${NC}"
echo -e "${GREEN}  razen new myprogram - Create a new program${NC}"
echo -e "${GREEN}  razen-update - Update Razen${NC}"
echo -e "${GREEN}  razen-help - Get help${NC}"

echo -e "\n${YELLOW}Note: You may need to restart your terminal for the changes to take effect.${NC}" 