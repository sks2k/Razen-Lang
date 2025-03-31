#!/usr/bin/env bash

# Razen Language Installer Script
# Author: Prathmesh Barot
# Copyright © 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.2

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
RAZEN_VERSION="beta v0.1.2"
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

# Check for update flag
if [ "$1" == "update" ] || [ "$1" == "--update" ]; then
    echo -e "${YELLOW}Checking for Razen updates...${NC}"
    
    # Download version check file
    if ! curl -s -o "$TMP_DIR/version.txt" "$RAZEN_REPO/version" &>/dev/null; then
        echo -e "${RED}Failed to check for updates. Please check your internet connection.${NC}"
        rm -rf "$TMP_DIR"
        exit 1
    fi
    
    # Read latest version
    LATEST_VERSION=$(cat "$TMP_DIR/version.txt" 2>/dev/null || echo "unknown")
    
    if [ "$LATEST_VERSION" == "$RAZEN_VERSION" ]; then
        echo -e "${GREEN}Razen is already up to date ($RAZEN_VERSION).${NC}"
        rm -rf "$TMP_DIR"
        exit 0
    else
        echo -e "${YELLOW}New version available: $LATEST_VERSION${NC}"
        echo -e "${YELLOW}Current version: $RAZEN_VERSION${NC}"
        echo -e "${YELLOW}Updating Razen...${NC}"
        
        # Download the latest installer
        if ! curl -s -o "$TMP_DIR/install.sh" "$RAZEN_REPO/install.sh" &>/dev/null; then
            echo -e "${RED}Failed to download the latest installer.${NC}"
            rm -rf "$TMP_DIR"
            exit 1
        fi
        
        # Make it executable
        chmod +x "$TMP_DIR/install.sh"
        
        # Run the installer with the latest version
        bash "$TMP_DIR/install.sh"
        
        # Clean up and exit
        rm -rf "$TMP_DIR"
        exit $?
    fi
fi

# Download necessary files
echo -e "${YELLOW}Downloading Razen files...${NC}"
cd "$TMP_DIR"

# Download main.py
if ! curl -s -o "$TMP_DIR/main.py" "$RAZEN_REPO/main.py" &>/dev/null; then
    echo -e "${RED}Failed to download main.py. Please check your internet connection.${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi
echo -e "  ${GREEN}✓${NC} Downloaded main.py"

# Create directories
mkdir -p "$TMP_DIR/examples" "$TMP_DIR/parser" "$TMP_DIR/utils" "$TMP_DIR/scripts"

# Download parser files
curl -s -o "$TMP_DIR/parser/__init__.py" "$RAZEN_REPO/parser/__init__.py" &>/dev/null
curl -s -o "$TMP_DIR/parser/lexer.py" "$RAZEN_REPO/parser/lexer.py" &>/dev/null
curl -s -o "$TMP_DIR/parser/ast.py" "$RAZEN_REPO/parser/ast.py" &>/dev/null
curl -s -o "$TMP_DIR/parser/parser.py" "$RAZEN_REPO/parser/parser.py" &>/dev/null
echo -e "  ${GREEN}✓${NC} Downloaded parser modules"

# Download utils files
curl -s -o "$TMP_DIR/utils/__init__.py" "$RAZEN_REPO/utils/__init__.py" &>/dev/null
curl -s -o "$TMP_DIR/utils/interpreter.py" "$RAZEN_REPO/utils/interpreter.py" &>/dev/null
curl -s -o "$TMP_DIR/utils/runtime.py" "$RAZEN_REPO/utils/runtime.py" &>/dev/null
echo -e "  ${GREEN}✓${NC} Downloaded utility modules"

# Download script files
curl -s -o "$TMP_DIR/scripts/razen" "$RAZEN_REPO/scripts/razen" &>/dev/null
curl -s -o "$TMP_DIR/scripts/razen-debug" "$RAZEN_REPO/scripts/razen-debug" &>/dev/null
curl -s -o "$TMP_DIR/scripts/razen-test" "$RAZEN_REPO/scripts/razen-test" &>/dev/null
curl -s -o "$TMP_DIR/scripts/razen-run" "$RAZEN_REPO/scripts/razen-run" &>/dev/null
curl -s -o "$TMP_DIR/scripts/razen-update" "$RAZEN_REPO/scripts/razen-update" &>/dev/null
curl -s -o "$TMP_DIR/scripts/razen-help" "$RAZEN_REPO/scripts/razen-help" &>/dev/null
echo -e "  ${GREEN}✓${NC} Downloaded script files"

# Make scripts executable
chmod +x "$TMP_DIR/scripts/"*
echo -e "  ${GREEN}✓${NC} Made scripts executable"

# Set RAZEN_DIR to the temporary directory
RAZEN_DIR="$TMP_DIR"

# Check for existing installation
if [ -f "/usr/local/bin/razen" ]; then
    echo -e "${YELLOW}Razen is already installed.${NC}"
    
    # Check if there are any missing commands
    MISSING_COMMANDS=false
    for cmd in razen-update razen-help; do
        if ! command -v $cmd &>/dev/null; then
            MISSING_COMMANDS=true
            break
        fi
    done
    
    # Check installed version
    CURRENT_VERSION=$(razen version 2>/dev/null | head -n1 | cut -d' ' -f3- || echo "unknown")
    
    if [ "$MISSING_COMMANDS" = true ]; then
        echo -e "${YELLOW}New Razen commands are available with this version.${NC}"
    fi
    
    if [ "$CURRENT_VERSION" != "$RAZEN_VERSION" ]; then
        echo -e "${YELLOW}New version available: $RAZEN_VERSION${NC}"
        echo -e "${YELLOW}Current installed version: $CURRENT_VERSION${NC}"
    fi
    
    read -p "Do you want to update Razen? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled.${NC}"
        echo -e "${GREEN}Tip:${NC} You can use 'razen-update' to update Razen later."
        rm -rf "$TMP_DIR"
        exit 0
    fi
    
    # Remove existing installation
    echo -e "${YELLOW}Updating Razen installation...${NC}"
    
    # Remove all binary and script symlinks
    for cmd in razen razen-debug razen-test razen-run razen-update razen-help; do
        if [ -f "/usr/local/bin/$cmd" ]; then
            sudo rm "/usr/local/bin/$cmd"
        fi
        if [ -L "/usr/bin/$cmd" ]; then
            sudo rm "/usr/bin/$cmd"
        fi
    done
    
    # Remove installation directory
    if [ -d "/usr/local/lib/razen" ]; then
        sudo rm -rf /usr/local/lib/razen
    fi
    
    echo -e "${GREEN}✓${NC} Previous installation removed."
fi

echo -e "${YELLOW}Installing Razen $RAZEN_VERSION...${NC}"

# Create permanent installation directory
echo -e "${YELLOW}Installing to /usr/local/lib/razen...${NC}"
sudo mkdir -p /usr/local/lib/razen
sudo cp -r "$TMP_DIR"/* /usr/local/lib/razen/
sudo chmod -R 755 /usr/local/lib/razen
INSTALL_DIR="/usr/local/lib/razen"
echo -e "  ${GREEN}✓${NC} Installed Razen core files"

# Create symbolic links
echo -e "${YELLOW}Creating symbolic links...${NC}"

# Create a list of all scripts to create symlinks for
SCRIPTS="razen razen-debug razen-test razen-run razen-update razen-help"

# Create symbolic links for each script
for script in $SCRIPTS; do
    # Create link in /usr/local/bin
    sudo ln -sf "$INSTALL_DIR/scripts/$script" "/usr/local/bin/$script"
    echo -e "  ${GREEN}✓${NC} Created /usr/local/bin/$script"
    
    # Create symlink in /usr/bin
    sudo ln -sf "/usr/local/bin/$script" "/usr/bin/$script"
    echo -e "  ${GREEN}✓${NC} Created symlink /usr/bin/$script"
done

# Also save the installer itself
sudo cp "$0" "$INSTALL_DIR/install.sh" 2>/dev/null || sudo sh -c "cat > $INSTALL_DIR/install.sh" <<< "$(cat $0)"
sudo chmod +x "$INSTALL_DIR/install.sh"

# Create version file for future updates
echo "$RAZEN_VERSION" > "$INSTALL_DIR/version"

# Create examples directory
echo -e "${YELLOW}Creating examples...${NC}"
    
# Create a simple hello world example
cat > "$INSTALL_DIR/examples/hello_world.rzn" <<EOL
// Basic Hello World example
// Powered by Razen $RAZEN_VERSION - © 2025 Prathmesh Barot, Basai Corporation

let name = "World"
show "Hello, \${name}!"

// Read user input
read user_input = "What's your name? "
show "Nice to meet you, \${user_input}!"
EOL

# Create a more advanced example
cat > "$INSTALL_DIR/examples/calculator.rzn" <<EOL
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

# Create a test script to verify installation works correctly
TEST_SCRIPT=$(mktemp)
cat > "$TEST_SCRIPT" <<EOL
#!/usr/bin/env bash
# Test that the Razen commands work properly

echo "Testing Razen installation..."

# Test commands exist
for cmd in razen razen-debug razen-test razen-run razen-update razen-help; do
    if ! command -v \$cmd &>/dev/null; then
        echo "Error: \$cmd command not found"
        exit 1
    fi
    echo "  ✓ \$cmd is available"
done

# Test version command
VERSION_OUTPUT=\$(razen version 2>&1)
if [[ ! "\$VERSION_OUTPUT" == *"$RAZEN_VERSION"* ]]; then
    echo "Error: version command not working correctly"
    exit 1
fi
echo "  ✓ Version command works"

# Test new command (in temp directory)
TMP_TEST_DIR=\$(mktemp -d)
cd "\$TMP_TEST_DIR"
razen new test_program &>/dev/null
if [ ! -f "test_program.rzn" ]; then
    echo "Error: new command not working correctly"
    rm -rf "\$TMP_TEST_DIR"
    exit 1
fi
echo "  ✓ New command works"
rm -rf "\$TMP_TEST_DIR"

# Test help command
HELP_OUTPUT=\$(razen-help 2>&1)
if [[ ! "\$HELP_OUTPUT" == *"USAGE"* ]]; then
    echo "Error: help command not working correctly"
    exit 1
fi
echo "  ✓ Help command works"

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

# Clean up temporary directory
rm -rf "$TMP_DIR"

# Check if installation was successful
if [ -x "/usr/local/bin/razen" ]; then
    # Check if this was an update
    if [ -n "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" != "$RAZEN_VERSION" ]; then
        echo -e "\n${GREEN}✅ Razen has been successfully updated from $CURRENT_VERSION to $RAZEN_VERSION!${NC}"
    else
        echo -e "\n${GREEN}✅ Razen $RAZEN_VERSION has been successfully installed!${NC}"
    fi
    
    echo -e "${BLUE}You can now use the following commands:${NC}"
    echo -e "  ${YELLOW}razen${NC} - Run a Razen script"
    echo -e "  ${YELLOW}razen-debug${NC} - Run a script in debug mode"
    echo -e "  ${YELLOW}razen-test${NC} - Run a script in test mode"
    echo -e "  ${YELLOW}razen-run${NC} - Run a script with clean output"
    echo -e "  ${YELLOW}razen-update${NC} - Update Razen to the latest version"
    echo -e "  ${YELLOW}razen-help${NC} - Display help information"
    echo -e "  ${YELLOW}razen new myprogram${NC} - Create a new Razen program"
    echo -e "  ${YELLOW}razen version${NC} - Display version information"
    
    echo -e "\n${BLUE}Examples:${NC}"
    echo -e "  ${YELLOW}razen-run examples/hello_world.rzn${NC} - Run the hello world example"
    echo -e "  ${YELLOW}razen new hello.rzn${NC} - Create a new hello.rzn program"
    echo -e "  ${YELLOW}razen-update${NC} - Check for and install updates"
    
    echo -e "\n${BLUE}To uninstall:${NC}"
    echo -e "  ${YELLOW}razen uninstall${NC}"
    
    echo -e "\n${GREEN}Note:${NC} Razen is installed in root-protected locations for security."
    echo -e "This prevents unauthorized modifications to the core language."
    echo -e "\n${BLUE}Official website and documentation coming soon!${NC}"
else
    echo -e "\n${RED}❌ Installation failed.${NC}"
    echo -e "${RED}Please check the error messages above.${NC}"
    exit 1
fi 