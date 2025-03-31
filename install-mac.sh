#!/bin/bash

# Razen Language Installer for macOS
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.36

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

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print error and cleanup
cleanup_and_exit() {
    local error_msg="$1"
    echo -e "${RED}Error: $error_msg${NC}"
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
    exit 1
}

# Function to create symbolic links
create_symlinks() {
    local INSTALL_DIR="$1"
    echo -e "${YELLOW}Creating symbolic links...${NC}"
    
    # List of all scripts that need symlinks
    SCRIPTS="razen razen-debug razen-test razen-run razen-update razen-help"
    
    # Create symlinks in /usr/local/bin
    for script in $SCRIPTS; do
        if [ -f "$INSTALL_DIR/scripts/$script" ]; then
            # Remove existing symlink if it exists
            if [ -L "/usr/local/bin/$script" ]; then
                sudo rm "/usr/local/bin/$script"
            fi
            sudo ln -sf "$INSTALL_DIR/scripts/$script" "/usr/local/bin/$script"
            echo -e "  ${GREEN}✓${NC} Created /usr/local/bin/$script"
        else
            cleanup_and_exit "Failed to create /usr/local/bin/$script (file not found)"
        fi
    done
    
    # Create symlinks in /usr/bin
    for script in $SCRIPTS; do
        if [ -f "/usr/local/bin/$script" ]; then
            # Remove existing symlink if it exists
            if [ -L "/usr/bin/$script" ]; then
                sudo rm "/usr/bin/$script"
            fi
            sudo ln -sf "/usr/local/bin/$script" "/usr/bin/$script"
            echo -e "  ${GREEN}✓${NC} Created /usr/bin/$script"
        else
            cleanup_and_exit "Failed to create /usr/bin/$script (file not found)"
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
        cleanup_and_exit "Failed to create some symbolic links. Please check the errors above."
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
        echo -e "${RED}Error: $(curl -s -w "%{http_code}" "$RAZEN_REPO/version")${NC}"
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
        echo -e "${RED}Error: $(curl -s -w "%{http_code}" "$RAZEN_REPO/install-mac.sh")${NC}"
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
            sudo rm -f "/usr/local/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/$cmd"
        fi
        if [ -L "/usr/bin/$cmd" ]; then
            sudo rm -f "/usr/bin/$cmd"
            echo -e "  ${GREEN}✓${NC} Removed /usr/bin/$cmd"
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

echo -e "${YELLOW}Programming Language ${PURPLE}$RAZEN_VERSION${NC}"
echo -e "${CYAN}By Prathmesh Barot, Basai Corporation${NC}"
echo -e "${YELLOW}Copyright © 2025 Prathmesh Barot${NC}\n"
sleep 1  # Add a small delay to make the banner more readable

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script requires root privileges.${NC}"
    echo -e "${YELLOW}Please run with sudo and try again.${NC}"
    echo -e "\nTo run with sudo:" "Yellow"
    echo -e "1. Open Terminal" "Green"
    echo -e "2. Run: sudo ./install-mac.sh" "Green"
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)
if [ $? -ne 0 ]; then
    cleanup_and_exit "Failed to create temporary directory"
fi
echo -e "${GREEN}  ✓ Created temporary directory${NC}"

# Check for force update flag
if [ "$1" == "--force-update" ]; then
    echo -e "${YELLOW}Force update mode activated. Will replace all existing files.${NC}"
    FORCE_UPDATE=true
else
    FORCE_UPDATE=false
fi

# Check for uninstall flag
if [ "$1" == "--uninstall" ]; then
    uninstall_razen
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
            cleanup_and_exit "Update failed. Please try again later."
        fi
        exit 0
    elif [ $UPDATE_STATUS -eq 0 ]; then
        echo -e "${GREEN}Razen is already up to date.${NC}"
        rm -rf "$TMP_DIR"
        exit 0
    else
        cleanup_and_exit "Failed to check for updates."
    fi
fi

# Create installation directory
INSTALL_DIR="/usr/local/razen"
echo -e "${YELLOW}Creating installation directory...${NC}"
if ! mkdir -p "$INSTALL_DIR"; then
    cleanup_and_exit "Failed to create installation directory"
fi
echo -e "${GREEN}  ✓ Created installation directory${NC}"

# Check if installation directory exists
if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/version" ]; then
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
    fi
fi

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
    if ! curl -s -o "$outfile" "$url"; then
        cleanup_and_exit "Failed to download $file"
    fi
    echo -e "${GREEN}  ✓ Downloaded $file${NC}"
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

if ! mkdir -p "$TMP_DIR/scripts"; then
    cleanup_and_exit "Failed to create scripts directory"
fi

for script in "${scripts[@]}"; do
    url="$RAZEN_REPO/scripts/$script"
    outfile="$TMP_DIR/scripts/$script"
    if ! curl -s -o "$outfile" "$url"; then
        cleanup_and_exit "Failed to download $script"
    fi
    echo -e "${GREEN}  ✓ Downloaded $script${NC}"
done

# Make scripts executable
if ! chmod +x "$TMP_DIR/scripts/"*; then
    cleanup_and_exit "Failed to make scripts executable"
fi
echo -e "${GREEN}  ✓ Made scripts executable${NC}"

# Copy files to installation directory
echo -e "\n${YELLOW}Installing files...${NC}"
if ! cp -r "$TMP_DIR"/* "$INSTALL_DIR/"; then
    cleanup_and_exit "Failed to copy files to installation directory"
fi
echo -e "${GREEN}  ✓ Copied files to installation directory${NC}"

# Create version file
if ! echo "$RAZEN_VERSION" > "$INSTALL_DIR/version"; then
    cleanup_and_exit "Failed to create version file"
fi
echo -e "${GREEN}  ✓ Created version file${NC}"

# Create symbolic links
create_symlinks "$INSTALL_DIR"

# Clean up
echo -e "\n${YELLOW}Cleaning up...${NC}"
if ! rm -rf "$TMP_DIR"; then
    echo -e "${RED}  ✗ Failed to clean up temporary files${NC}"
    echo -e "${RED}    Error: $?${NC}"
else
    echo -e "${GREEN}  ✓ Cleaned up temporary files${NC}"
fi

# Success message
echo -e "\n${GREEN}✅ Razen has been successfully installed!${NC}"
echo -e "\n${YELLOW}Available commands:${NC}"
echo -e "  ${GREEN}razen${NC} - Run Razen programs"
echo -e "  ${GREEN}razen-debug${NC} - Run programs in debug mode"
echo -e "  ${GREEN}razen-test${NC} - Run programs in test mode"
echo -e "  ${GREEN}razen-run${NC} - Run programs with clean output"
echo -e "  ${GREEN}razen-update${NC} - Update Razen to the latest version"
echo -e "  ${GREEN}razen-help${NC} - Show help information"
echo -e "  ${GREEN}razen new myprogram${NC} - Create a new program"
echo -e "  ${GREEN}razen version${NC} - Show version information"
echo -e "  ${GREEN}razen uninstall${NC} - Remove Razen from your system"

echo -e "\n${YELLOW}Example usage:${NC}"
echo -e "  ${GREEN}razen run hello_world.rzn${NC} - Run a Razen program"
echo -e "  ${GREEN}razen new myprogram${NC} - Create a new program"
echo -e "  ${GREEN}razen-update${NC} - Update Razen"
echo -e "  ${GREEN}razen-help${NC} - Get help"

echo -e "\n${YELLOW}Note:${NC} You may need to restart your terminal for the changes to take effect." 