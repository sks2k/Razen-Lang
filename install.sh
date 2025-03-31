#!/usr/bin/env bash

# Razen Language Installer Script
# Author: Prathmesh Barot
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.1

set -e  # Exit on error

# Colors for terminal output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
NC="\033[0m" # No Color

# Version
RAZEN_VERSION="beta v0.1.1"
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/razen-lang/main"

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

# Check for update flag
if [ "$1" == "update" ] || [ "$1" == "--update" ]; then
    echo -e "${YELLOW}Checking for Razen updates...${NC}"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Download version check file
    if ! curl -s -o version.txt "$RAZEN_REPO/version" &>/dev/null; then
        echo -e "${RED}Failed to check for updates. Please check your internet connection.${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Read latest version
    LATEST_VERSION=$(cat version.txt 2>/dev/null || echo "unknown")
    
    if [ "$LATEST_VERSION" == "$RAZEN_VERSION" ]; then
        echo -e "${GREEN}Razen is already up to date ($RAZEN_VERSION).${NC}"
        rm -rf "$TMP_DIR"
        exit 0
    else
        echo -e "${YELLOW}New version available: $LATEST_VERSION${NC}"
        echo -e "${YELLOW}Current version: $RAZEN_VERSION${NC}"
        echo -e "${YELLOW}Updating Razen...${NC}"
        
        # Download the latest installer
        if curl -s -o install.sh "$RAZEN_REPO/install.sh" &>/dev/null; then
            chmod +x install.sh
            # Run the installer
            bash install.sh
            rm -rf "$TMP_DIR"
            exit $?
        else
            echo -e "${RED}Failed to download the latest installer.${NC}"
            rm -rf "$TMP_DIR"
            exit 1
        fi
    fi
fi

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

echo -e "${YELLOW}Installing Razen $RAZEN_VERSION in secure root locations...${NC}"
echo -e "${YELLOW}This ensures only authorized users can modify the language core.${NC}"

# Create main runner script
echo -e "${YELLOW}Creating Razen launcher script...${NC}"

LAUNCHER_SCRIPT=$(cat <<EOF
#!/usr/bin/env bash
# Razen Language Launcher
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: $RAZEN_VERSION

# Get the script name that was called
SCRIPT_NAME=\$(basename "\$0")

# Check for update command
if [ "\$1" = "update" ]; then
    echo "Updating Razen to the latest version..."
    bash "$RAZEN_DIR/install.sh" update
    exit \$?
fi

# Check for version command
if [ "\$1" = "version" ] || [ "\$1" = "--version" ] || [ "\$1" = "-v" ]; then
    echo "Razen $RAZEN_VERSION"
    echo "Copyright © 2025 Prathmesh Barot, Basai Corporation"
    exit 0
fi

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

# Check if creating a new file
if [ "\$1" = "new" ] && [ -n "\$2" ]; then
    if [[ "\$2" != *.rzn ]]; then
        FILENAME="\$2.rzn"
    else
        FILENAME="\$2"
    fi
    
    echo "// New Razen program created on \$(date)" > "\$FILENAME"
    echo "// Powered by Razen $RAZEN_VERSION - © 2025 Prathmesh Barot" >> "\$FILENAME"
    echo "" >> "\$FILENAME"
    echo "// Your code goes here" >> "\$FILENAME"
    echo "let message = \"Hello, World!\"" >> "\$FILENAME"
    echo "show \"\${message}\"" >> "\$FILENAME"
    echo "" >> "\$FILENAME"
    echo "// Read user input" >> "\$FILENAME"
    echo "read user_input = \"What's your name? \"" >> "\$FILENAME"
    echo "show \"Nice to meet you, \${user_input}!\"" >> "\$FILENAME"
    
    echo "Created new Razen program: \$FILENAME"
    exit 0
fi

# Display help if requested
if [ "\$1" = "help" ] || [ "\$1" = "--help" ] || [ "\$1" = "-h" ]; then
    echo "Razen $RAZEN_VERSION - Programming Language"
    echo "Copyright © 2025 Prathmesh Barot, Basai Corporation"
    echo ""
    echo "Usage:"
    echo "  razen [command] [options]"
    echo ""
    echo "Commands:"
    echo "  <filename.rzn>     Run a Razen script"
    echo "  new <filename>     Create a new Razen program"
    echo "  update             Update Razen to the latest version"
    echo "  version            Display version information"
    echo "  help               Display this help message"
    echo ""
    echo "Alternate modes:"
    echo "  razen-debug        Run a script in debug mode"
    echo "  razen-test         Run a script in test mode"
    echo "  razen-run          Run a script with clean output"
    echo ""
    echo "Examples:"
    echo "  razen hello.rzn"
    echo "  razen new myprogram"
    echo "  razen-run examples/hello_world.rzn"
    exit 0
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

# Create version file for future updates
echo "$RAZEN_VERSION" > "$RAZEN_DIR/version"

# Create examples directory if it doesn't exist
if [ ! -d "$RAZEN_DIR/examples" ]; then
    echo -e "${YELLOW}Creating examples directory...${NC}"
    mkdir -p "$RAZEN_DIR/examples"
    
    # Create a simple hello world example
    cat > "$RAZEN_DIR/examples/hello_world.rzn" <<EOL
// Basic Hello World example
// Powered by Razen $RAZEN_VERSION - © 2025 Prathmesh Barot, Basai Corporation

let name = "World"
show "Hello, \${name}!"

// Read user input
read user_input = "What's your name? "
show "Nice to meet you, \${user_input}!"
EOL

    # Create a more advanced example
    cat > "$RAZEN_DIR/examples/calculator.rzn" <<EOL
// Simple calculator example
// Powered by Razen $RAZEN_VERSION - © 2025 Prathmesh Barot, Basai Corporation

show "Simple Razen Calculator"
show "======================="

read num1 = "Enter first number: "
read num2 = "Enter second number: "
read operation = "Enter operation (+, -, *, /): "

// Convert input to numbers
let number1 = int(num1)
let number2 = int(num2)

if operation == "+" {
    let result = number1 + number2
    show "\${number1} + \${number2} = \${result}"
}

if operation == "-" {
    let result = number1 - number2
    show "\${number1} - \${number2} = \${result}"
}

if operation == "*" {
    let result = number1 * number2
    show "\${number1} * \${number2} = \${result}"
}

if operation == "/" {
    if number2 == 0 {
        show "Error: Cannot divide by zero!"
    } else {
        let result = number1 / number2
        show "\${number1} / \${number2} = \${result}"
    }
}
EOL

    echo -e "  ${GREEN}✓${NC} Created example programs"
fi

# Create a test script to verify installation works correctly
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" <<EOL
#!/usr/bin/env bash
# Test that the Razen commands work properly

echo "Testing Razen installation..."

# Test commands exist
if ! command -v razen &>/dev/null; then
    echo "Error: razen command not found"
    exit 1
fi

if ! command -v razen-run &>/dev/null; then
    echo "Error: razen-run command not found"
    exit 1
fi

if ! command -v razen-debug &>/dev/null; then
    echo "Error: razen-debug command not found"
    exit 1
fi

if ! command -v razen-test &>/dev/null; then
    echo "Error: razen-test command not found"
    exit 1
fi

# Test version command
VERSION_OUTPUT=\$(razen version 2>&1)
if [[ ! "\$VERSION_OUTPUT" == *"$RAZEN_VERSION"* ]]; then
    echo "Error: version command not working correctly"
    exit 1
fi

# Test new command (in temp directory)
TMP_DIR=\$(mktemp -d)
cd "\$TMP_DIR"
razen new test_program &>/dev/null
if [ ! -f "test_program.rzn" ]; then
    echo "Error: new command not working correctly"
    rm -rf "\$TMP_DIR"
    exit 1
fi
rm -rf "\$TMP_DIR"

echo "All tests passed!"
exit 0
EOL

chmod +x "$TEST_SCRIPT"
echo -e "${YELLOW}Testing installation...${NC}"
if bash "$TEST_SCRIPT"; then
    echo -e "  ${GREEN}✓${NC} All commands are working correctly"
else
    echo -e "  ${RED}✗${NC} Some commands are not working correctly"
    echo -e "${RED}Please check the error messages above.${NC}"
fi
rm "$TEST_SCRIPT"

# Check if installation was successful
if [ -x "/usr/local/bin/razen" ]; then
    echo -e "\n${GREEN}✅ Razen $RAZEN_VERSION has been successfully installed!${NC}"
    echo -e "${BLUE}You can now use the following commands:${NC}"
    echo -e "  ${YELLOW}razen${NC} - Run a Razen script"
    echo -e "  ${YELLOW}razen-debug${NC} - Run a Razen script in debug mode"
    echo -e "  ${YELLOW}razen-test${NC} - Run a Razen script in test mode"
    echo -e "  ${YELLOW}razen-run${NC} - Run a Razen script with clean output"
    echo -e "  ${YELLOW}razen new myprogram${NC} - Create a new Razen program"
    echo -e "  ${YELLOW}razen update${NC} - Update Razen to the latest version"
    echo -e "  ${YELLOW}razen version${NC} - Display version information"
    echo -e "  ${YELLOW}razen help${NC} - Display help information"
    
    echo -e "\n${BLUE}Examples:${NC}"
    echo -e "  ${YELLOW}razen-run examples/hello_world.rzn${NC} - Run the hello world example"
    echo -e "  ${YELLOW}razen new hello.rzn${NC} - Create a new hello.rzn program"
    
    echo -e "\n${BLUE}To uninstall:${NC}"
    echo -e "  ${YELLOW}bash install.sh --uninstall${NC}"
    
    echo -e "\n${GREEN}Note:${NC} Razen is installed in root-protected locations for security."
    echo -e "This prevents unauthorized modifications to the core language."
    echo -e "\n${BLUE}Check the examples directory for sample programs.${NC}"
    echo -e "${BLUE}Official website and documentation coming soon!${NC}"
else
    echo -e "\n${RED}❌ Installation failed.${NC}"
    echo -e "${RED}Please check the error messages above.${NC}"
    exit 1
fi 