#!/usr/bin/env bash

# Razen Language Installer Script
# Author: Prathmesh Barot
# Copyright © 2025 Prathmesh Barot

set -e  # Exit on error

# Colors for terminal output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Print banner
echo -e "${BLUE}"
echo "██████╗  █████╗ ███████╗███████╗███╗   ██╗"
echo "██╔══██╗██╔══██╗╚══███╔╝██╔════╝████╗  ██║"
echo "██████╔╝███████║  ███╔╝ █████╗  ██╔██╗ ██║"
echo "██╔══██╗██╔══██║ ███╔╝  ██╔══╝  ██║╚██╗██║"
echo "██║  ██║██║  ██║███████╗███████╗██║ ╚████║"
echo "╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${YELLOW}Programming Language Installer${NC}"
echo -e "${YELLOW}Copyright © 2025 Prathmesh Barot${NC}\n"

# Check for uninstall flag
if [ "$1" == "--uninstall" ]; then
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Remove binaries and symlinks
    if [ -f "/usr/local/bin/razen" ]; then
        sudo rm /usr/local/bin/razen
        echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/razen"
    fi
    
    if [ -L "/usr/bin/razen" ]; then
        sudo rm /usr/bin/razen
        echo -e "  ${GREEN}✓${NC} Removed symlink /usr/bin/razen"
    fi
    
    if [ -L "/usr/bin/razen-debug" ]; then
        sudo rm /usr/bin/razen-debug
        echo -e "  ${GREEN}✓${NC} Removed symlink /usr/bin/razen-debug"
    fi
    
    if [ -L "/usr/bin/razen-test" ]; then
        sudo rm /usr/bin/razen-test
        echo -e "  ${GREEN}✓${NC} Removed symlink /usr/bin/razen-test"
    fi
    
    if [ -L "/usr/bin/razen-run" ]; then
        sudo rm /usr/bin/razen-run
        echo -e "  ${GREEN}✓${NC} Removed symlink /usr/bin/razen-run"
    fi
    
    echo -e "\n${GREEN}✅ Razen has been successfully uninstalled!${NC}"
    exit 0
fi

# Check if script is being run directly or via curl/wget
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
RAZEN_DIR="$SCRIPT_DIR"

if [ ! -f "$RAZEN_DIR/main.py" ]; then
    echo -e "${RED}Error: main.py not found in $RAZEN_DIR${NC}"
    echo -e "${RED}The installer must be run from the Razen root directory.${NC}"
    exit 1
fi

# Check for existing installation
if [ -f "/usr/local/bin/razen" ]; then
    echo -e "${YELLOW}Razen is already installed.${NC}"
    
    read -p "Do you want to reinstall? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled.${NC}"
        exit 0
    fi
    
    # Remove existing installation
    echo -e "${YELLOW}Removing existing installation...${NC}"
    if [ -f "/usr/local/bin/razen" ]; then
        sudo rm /usr/local/bin/razen
    fi
    
    if [ -L "/usr/bin/razen" ]; then
        sudo rm /usr/bin/razen
    fi
    
    if [ -L "/usr/bin/razen-debug" ]; then
        sudo rm /usr/bin/razen-debug
    fi
    
    if [ -L "/usr/bin/razen-test" ]; then
        sudo rm /usr/bin/razen-test
    fi
    
    if [ -L "/usr/bin/razen-run" ]; then
        sudo rm /usr/bin/razen-run
    fi
    
    echo -e "${GREEN}✓${NC} Previous installation removed."
fi

# Create main runner script
echo -e "${YELLOW}Creating Razen launcher script...${NC}"

LAUNCHER_SCRIPT=$(cat <<EOF
#!/usr/bin/env bash
# Razen Language Launcher
# Copyright © 2025 Prathmesh Barot

# Get the script name that was called
SCRIPT_NAME=\$(basename "\$0")

# Determine which mode to use based on the script name
if [ "\$SCRIPT_NAME" = "razen-debug" ]; then
    MODE="debug"
elif [ "\$SCRIPT_NAME" = "razen-test" ]; then
    MODE="test"
elif [ "\$SCRIPT_NAME" = "razen-run" ]; then
    # Special case for razen-run (clean output)
    if [ -z "\$1" ]; then
        echo "Usage: \$SCRIPT_NAME <filename.rzn>"
        exit 1
    fi
    
    # Run with minimal output through our wrapper
    python3 "$RAZEN_DIR/main.py" --mode=run "\$1" | grep -v "^DEBUG:" | grep -v "^Loaded" | grep -v "^Parser" | grep -v "^--- "
    exit \${PIPESTATUS[0]}
else
    MODE="run"
fi

# Run main.py with appropriate mode
python3 "$RAZEN_DIR/main.py" --mode=\$MODE "\$@"
exit \$?
EOF
)

# Install the main script
echo -e "${YELLOW}Installing Razen to /usr/local/bin/razen...${NC}"
echo "$LAUNCHER_SCRIPT" | sudo tee /usr/local/bin/razen > /dev/null
sudo chmod +x /usr/local/bin/razen
echo -e "  ${GREEN}✓${NC} Installed /usr/local/bin/razen"

# Create symbolic links
echo -e "${YELLOW}Creating symbolic links...${NC}"
sudo ln -sf /usr/local/bin/razen /usr/bin/razen
echo -e "  ${GREEN}✓${NC} Created symlink /usr/bin/razen"

sudo ln -sf /usr/local/bin/razen /usr/bin/razen-debug
echo -e "  ${GREEN}✓${NC} Created symlink /usr/bin/razen-debug"

sudo ln -sf /usr/local/bin/razen /usr/bin/razen-test
echo -e "  ${GREEN}✓${NC} Created symlink /usr/bin/razen-test"

sudo ln -sf /usr/local/bin/razen /usr/bin/razen-run
echo -e "  ${GREEN}✓${NC} Created symlink /usr/bin/razen-run"

# Check if installation was successful
if [ -x "/usr/local/bin/razen" ]; then
    echo -e "\n${GREEN}✅ Razen has been successfully installed!${NC}"
    echo -e "${BLUE}You can now use the following commands:${NC}"
    echo -e "  ${YELLOW}razen${NC} - Run a Razen script"
    echo -e "  ${YELLOW}razen-debug${NC} - Run a Razen script in debug mode"
    echo -e "  ${YELLOW}razen-test${NC} - Run a Razen script in test mode"
    echo -e "  ${YELLOW}razen-run${NC} - Run a Razen script with clean output"
    echo -e "\n${BLUE}Example:${NC}"
    echo -e "  ${YELLOW}razen${NC} path/to/your/script.rzn"
    echo -e "\n${BLUE}To uninstall:${NC}"
    echo -e "  ${YELLOW}bash install.sh --uninstall${NC}"
else
    echo -e "\n${RED}❌ Installation failed.${NC}"
    echo -e "${RED}Please check the error messages above.${NC}"
    exit 1
fi 