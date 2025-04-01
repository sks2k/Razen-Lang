#!/bin/bash

# Razen Language Installer for macOS
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.4

# Repository URL
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"

# Get version from the version file
if [ -f "version" ]; then
    RAZEN_VERSION=$(cat version)
else
    # Download version file if not present
    if ! curl -s -o version "$RAZEN_REPO/version" &>/dev/null; then
        echo -e "${RED}Failed to download version information. Using default version.${NC}"
        RAZEN_VERSION="beta v0.1.4"
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
    
    # Dynamically find all scripts in the scripts directory
    if [ -d "$INSTALL_DIR/scripts" ]; then
        SCRIPTS=$(find "$INSTALL_DIR/scripts" -type f -executable -exec basename {} \;)
        if [ -z "$SCRIPTS" ]; then
            # Fallback to a predefined list if no executable files are found
            SCRIPTS="razen razen-debug razen-test razen-run razen-update razen-help"
            echo -e "${YELLOW}No executable scripts found, using default list.${NC}"
        else
            echo -e "${GREEN}Found $(echo "$SCRIPTS" | wc -w) scripts to link.${NC}"
        fi
    else
        cleanup_and_exit "Scripts directory not found at $INSTALL_DIR/scripts"
    fi
    
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

# Download Razen files
echo -e "${YELLOW}Downloading Razen files...${NC}"

# Download main.py
if ! curl -s -o "$TMP_DIR/main.py" "$RAZEN_REPO/main.py" &>/dev/null; then
    cleanup_and_exit "Failed to download main.py"
fi
echo -e "  ${GREEN}✓${NC} Downloaded main.py"

# Download src files
for file in lexer.py parser.py interpreter.py runtime.py; do
    if ! curl -s -o "$TMP_DIR/src/$file" "$RAZEN_REPO/src/$file" &>/dev/null; then
        cleanup_and_exit "Failed to download src/$file"
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

# Copy files to installation directory
sudo cp "$TMP_DIR/main.py" "$INSTALL_DIR/"
sudo cp "$TMP_DIR/src/"*.py "$INSTALL_DIR/src/" 2>/dev/null || true
sudo cp "$TMP_DIR/properties/"*.rzn "$INSTALL_DIR/properties/"
sudo cp "$TMP_DIR/scripts/"* "$INSTALL_DIR/scripts/"

# Download and save the latest installer script for future updates
if ! curl -s -o "$TMP_DIR/install-mac.sh" "$RAZEN_REPO/install-mac.sh" &>/dev/null; then
    echo -e "${YELLOW}Warning: Could not download latest installer script. Using current version instead.${NC}"
    # If we're running from a downloaded script, copy it
    if [ -f "$0" ] && [[ "$0" != "/usr/local/bin/"* ]]; then
        sudo cp "$0" "$INSTALL_DIR/install-mac.sh"
    fi
else
    sudo cp "$TMP_DIR/install-mac.sh" "$INSTALL_DIR/install-mac.sh"
    sudo chmod +x "$INSTALL_DIR/install-mac.sh"
    echo -e "${GREEN}  ✓${NC} Saved latest installer script for future updates"
fi

# Create version file with proper permissions
echo "$RAZEN_VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null

# Create an empty __init__.py file in each directory to make them proper Python packages
sudo touch "$INSTALL_DIR/__init__.py"
sudo touch "$INSTALL_DIR/src/__init__.py"

# Set proper permissions
sudo chmod -R 755 "$INSTALL_DIR"
sudo chown -R root:wheel "$INSTALL_DIR"

echo -e "  ${GREEN}✓${NC} Copied files to installation directory"

# Check for Rust installation
echo -e "${YELLOW}Checking for Rust installation...${NC}"
if ! command -v rustc &> /dev/null; then
    echo -e "${YELLOW}Rust is not installed. Razen compiler requires Rust to run.${NC}"
    echo -e "${YELLOW}Installing Rust automatically...${NC}"
    
    # Ask for confirmation before installing Rust
    read -p "Do you want to install Rust now? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Rust installation is required for Razen to function properly.${NC}"
        echo -e "${YELLOW}You can install Rust manually using:${NC}"
        echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Install Rust using rustup
    echo -e "${YELLOW}Downloading and installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Check if installation was successful
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Rust. Please install it manually.${NC}"
        echo -e "${YELLOW}You can install Rust manually using:${NC}"
        echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Source the cargo environment
    source "$HOME/.cargo/env"
    
    # Verify Rust installation
    if ! command -v rustc &> /dev/null; then
        echo -e "${RED}Rust installation completed but rustc command not found.${NC}"
        echo -e "${YELLOW}Please restart your terminal and run the installer again.${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    echo -e "  ${GREEN}✓${NC} Rust has been successfully installed"
else
    echo -e "  ${GREEN}✓${NC} Rust is already installed"
fi

# Check Rust version
RUST_VERSION=$(rustc --version | cut -d' ' -f2)
echo -e "  ${GREEN}✓${NC} Rust version: $RUST_VERSION"

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
echo -e "\n${YELLOW}Note:${NC} Razen is installed in ${GREEN}/usr/local/razen${NC} for security."
echo -e "${YELLOW}Official website and documentation will be available soon.${NC}" 