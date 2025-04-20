#!/bin/bash

# Razen Language Installer for macOS
# Copyright 2025 Prathmesh Barot, Basai Corporation
# Version: beta v0.1.657 (Colours & Installers & Updaters updated properly.)

# Repository URL
RAZEN_REPO="https://raw.githubusercontent.com/BasaiCorp/Razen-Lang/main"

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
    local recovery_hint="$2"
    local exit_code="${3:-1}"
    
    echo -e "${RED}Error: $error_msg${NC}"
    
    if [ -n "$recovery_hint" ]; then
        echo -e "${YELLOW}Hint: $recovery_hint${NC}"
    fi
    
    if [ -d "$TMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TMP_DIR"
    fi
    
    exit $exit_code
}

# Function to check internet connectivity
check_internet_connectivity() {
    echo -e "${YELLOW}Checking internet connectivity...${NC}"
    
    # Test sites to check connectivity
    local test_sites=("github.com" "raw.githubusercontent.com" "google.com")
    local connected=false
    
    for site in "${test_sites[@]}"; do
        if ping -c 1 -W 2 "$site" &>/dev/null; then
            connected=true
            break
        fi
    done
    
    if [ "$connected" = false ]; then
        echo -e "${RED}No internet connection detected.${NC}"
        echo -e "${YELLOW}Please check your network connection and try again.${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✓${NC} Internet connection detected"
    return 0
}

# Function to check if running as root or with sudo
check_sudo_privileges() {
    echo -e "${YELLOW}Checking for administrator privileges...${NC}"
    
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}This script requires administrator privileges.${NC}"
        echo -e "${YELLOW}Please run with sudo:${NC}"
        echo -e "  ${CYAN}sudo ./install-mac.sh${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✓${NC} Administrator privileges confirmed"
    return 0
}

# Function to download a file with retry logic
download_with_retry() {
    local url="$1"
    local output_file="$2"
    local description="$3"
    local max_retries=3
    local retry_count=0
    local success=false
    
    echo -e "  ${CYAN}Downloading $description...${NC}"
    
    while [ "$success" = false ] && [ $retry_count -lt $max_retries ]; do
        if curl -s -o "$output_file" "$url" &>/dev/null; then
            echo -e "    ${GREEN}✓${NC} Downloaded $description"
            success=true
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                echo -e "    ${YELLOW}✗${NC} Download attempt $retry_count failed. Retrying in 2 seconds..."
                sleep 2
            else
                echo -e "    ${RED}✗${NC} Failed to download $description after $max_retries attempts"
                echo -e "      ${RED}Error: $(curl -s -w "%{http_code}" "$url")${NC}"
                return 1
            fi
        fi
    done
    
    return 1
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
            SCRIPTS="razen razen-debug razen-test razen-run razen-update razen-help razen-extension"
            echo -e "${YELLOW}No executable scripts found, using default list.${NC}"
        else
            echo -e "${GREEN}Found $(echo "$SCRIPTS" | wc -w) scripts to link.${NC}"
        fi
    else
        cleanup_and_exit "Scripts directory not found at $INSTALL_DIR/scripts" "Make sure the installation directory structure is correct"
    fi
    
    # Create /usr/local/bin if it doesn't exist
    if [ ! -d "/usr/local/bin" ]; then
        echo -e "${YELLOW}Creating /usr/local/bin directory...${NC}"
        if ! sudo mkdir -p "/usr/local/bin"; then
            cleanup_and_exit "Failed to create /usr/local/bin directory" "Check your permissions and try again"
        fi
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
            echo -e "  ${RED}✗${NC} Failed to create /usr/local/bin/$script (file not found)"
            continue
        fi
    done
    
    # Verify all symlinks are created in /usr/local/bin
    local missing_links=0
    for script in $SCRIPTS; do
        if [ ! -L "/usr/local/bin/$script" ]; then
            echo -e "  ${RED}✗${NC} Missing symlink for $script in /usr/local/bin"
            missing_links=$((missing_links + 1))
        fi
    done
    
    if [ $missing_links -gt 0 ]; then
        echo -e "${YELLOW}Warning: Failed to create $missing_links symbolic links in /usr/local/bin.${NC}"
        echo -e "${YELLOW}You may need to manually add the Razen directory to your PATH.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} All symbolic links created successfully"
    return 0
}

# Function to check for updates
check_for_updates() {
    echo -e "${YELLOW}Checking for updates...${NC}"
    
    # Download version check file
    if ! download_with_retry "$RAZEN_REPO/version" "$TMP_DIR/version.txt" "version information"; then
        echo -e "${RED}Failed to check for updates. Please check your internet connection.${NC}"
        return 1
    fi
    
    # Read latest version
    LATEST_VERSION=$(cat "$TMP_DIR/version.txt" 2>/dev/null || echo "unknown")
    LATEST_VERSION=$(echo "$LATEST_VERSION" | tr -d '[:space:]')
    
    echo -e "  ${GREEN}✓${NC} Current version: $RAZEN_VERSION"
    echo -e "  ${GREEN}✓${NC} Latest version: $LATEST_VERSION"
    
    if [ "$LATEST_VERSION" == "$RAZEN_VERSION" ]; then
        echo -e "${GREEN}Razen is already up to date.${NC}"
        return 0
    elif [ "$LATEST_VERSION" == "unknown" ]; then
        echo -e "${RED}Failed to determine the latest version.${NC}"
        return 1
    else
        echo -e "${YELLOW}A new version of Razen is available: $LATEST_VERSION${NC}"
        return 2
    fi
}

# Function to perform update
perform_update() {
    echo -e "${YELLOW}Updating Razen...${NC}"
    
    # Download the latest installer
    if ! download_with_retry "$RAZEN_REPO/install-mac.sh" "$TMP_DIR/install-mac.sh" "latest installer"; then
        cleanup_and_exit "Failed to download the latest installer" "Check your internet connection and try again"
    fi
    
    # Make the downloaded installer executable
    chmod +x "$TMP_DIR/install-mac.sh"
    
    # Copy the installer to a temporary location
    TEMP_INSTALLER="/tmp/razen-installer-$$.sh"
    cp "$TMP_DIR/install-mac.sh" "$TEMP_INSTALLER"
    chmod +x "$TEMP_INSTALLER"
    
    echo -e "${GREEN}✓${NC} Downloaded the latest installer"
    echo -e "${YELLOW}Running the latest installer...${NC}"
    
    # Clean up the temporary directory
    rm -rf "$TMP_DIR"
    
    # Run the new installer with the same arguments
    exec sudo "$TEMP_INSTALLER" "$@"
    
    # This point should not be reached
    exit 0
}

# Function to uninstall Razen
uninstall_razen() {
    echo -e "${YELLOW}Uninstalling Razen...${NC}"
    
    # Remove symlinks
    for script in razen razen-debug razen-test razen-run razen-update razen-help razen-extension; do
        if [ -L "/usr/local/bin/$script" ]; then
            sudo rm "/usr/local/bin/$script"
            echo -e "  ${GREEN}✓${NC} Removed /usr/local/bin/$script"
        fi
    done
    
    # Remove installation directory
    if [ -d "/usr/local/razen" ]; then
        sudo rm -rf "/usr/local/razen"
        echo -e "  ${GREEN}✓${NC} Removed /usr/local/razen"
    fi
    
    # Remove version file
    if [ -f "version" ]; then
        rm "version"
        echo -e "  ${GREEN}✓${NC} Removed version file"
    fi
    
    echo -e "${GREEN}✓${NC} Razen has been successfully uninstalled"
    exit 0
}

# Function to install VS Code extension
install_vscode_extension() {
    echo -e "${YELLOW}Installing VS Code Extension for Razen...${NC}"
    
    # Check if VS Code is installed
    local vscode_installed=false
    local vscode_path=""
    
    if command -v code &>/dev/null; then
        vscode_installed=true
        vscode_path=$(command -v code)
        echo -e "  ${GREEN}✓${NC} VS Code detected at: $vscode_path"
    elif command -v codium &>/dev/null; then
        vscode_installed=true
        vscode_path=$(command -v codium)
        echo -e "  ${GREEN}✓${NC} VSCodium detected at: $vscode_path"
    fi
    
    # Create extension directory
    local vscode_ext_source_dir="$INSTALL_DIR/razen-vscode-extension"
    local vscode_ext_target_dir="$HOME/.vscode/extensions/razen-lang.razen"
    
    mkdir -p "$vscode_ext_target_dir"
    
    # Check if extension source exists
    if [ -d "$vscode_ext_source_dir" ] && [ "$(ls -A "$vscode_ext_source_dir" 2>/dev/null)" ]; then
        # Copy extension files
        cp -r "$vscode_ext_source_dir/"* "$vscode_ext_target_dir/"
        echo -e "  ${GREEN}✓${NC} VS Code extension installed to: $vscode_ext_target_dir"
    else
        # Create basic extension structure if source doesn't exist
        echo -e "  ${YELLOW}⚠${NC} Extension source not found, creating basic extension..."
        
        # Create directories
        mkdir -p "$vscode_ext_target_dir/syntaxes"
        
        # Create package.json
        cat > "$vscode_ext_target_dir/package.json" << EOL
{
    "name": "razen-lang",
    "displayName": "Razen Language Support",
    "description": "Syntax highlighting and tools for Razen programming language",
    "version": "0.1.0",
    "publisher": "razen-lang",
    "engines": {
        "vscode": "^1.60.0"
    },
    "categories": ["Programming Languages"],
    "contributes": {
        "languages": [{
            "id": "razen",
            "aliases": ["Razen", "razen"],
            "extensions": [".rzn"],
            "configuration": "./language-configuration.json"
        }],
        "grammars": [{
            "language": "razen",
            "scopeName": "source.razen",
            "path": "./syntaxes/razen.tmLanguage.json"
        }]
    }
}
EOL
        
        # Create language configuration
        cat > "$vscode_ext_target_dir/language-configuration.json" << EOL
{
    "comments": {
        "lineComment": "#",
        "blockComment": ["/*", "*/"]
    },
    "brackets": [
        ["[", "]"],
        ["(", ")"],
        ["{", "}"]
    ],
    "autoClosingPairs": [
        { "open": "{", "close": "}" },
        { "open": "[", "close": "]" },
        { "open": "(", "close": ")" },
        { "open": "\"", "close": "\"" },
        { "open": "'", "close": "'" }
    ]
}
EOL
        
        # Create basic syntax highlighting
        cat > "$vscode_ext_target_dir/syntaxes/razen.tmLanguage.json" << EOL
{
    "$schema": "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
    "name": "Razen",
    "patterns": [
        { "include": "#keywords" },
        { "include": "#strings" },
        { "include": "#comments" }
    ],
    "repository": {
        "keywords": {
            "patterns": [{
                "name": "keyword.control.razen",
                "match": "\\b(if|else|while|for|return|function|var|const|let|print|input)\\b"
            }]
        },
        "strings": {
            "name": "string.quoted.double.razen",
            "begin": "\"",
            "end": "\"",
            "patterns": [
                {
                    "name": "constant.character.escape.razen",
                    "match": "\\\\."
                }
            ]
        },
        "comments": {
            "patterns": [
                {
                    "name": "comment.line.number-sign.razen",
                    "match": "#.*$"
                },
                {
                    "name": "comment.block.razen",
                    "begin": "/\\*",
                    "end": "\\*/"
                }
            ]
        }
    },
    "scopeName": "source.razen"
}
EOL
        
        echo -e "  ${GREEN}✓${NC} Basic VS Code extension created at: $vscode_ext_target_dir"
    fi
    
    if [ "$vscode_installed" = true ]; then
        echo -e "  ${GREEN}✓${NC} VS Code extension installed successfully"
        echo -e "  ${YELLOW}Restart VS Code to activate the extension${NC}"
        return 0
    else
        echo -e "  ${YELLOW}VS Code not detected. Extension files installed to:${NC}"
        echo -e "  ${CYAN}$vscode_ext_target_dir${NC}"
        echo -e "  ${YELLOW}Install VS Code from https://code.visualstudio.com/ to use the extension${NC}"
        return 1
    fi
}

# Function to install JetBrains plugin
install_jetbrains_plugin() {
    echo -e "${YELLOW}Installing JetBrains Plugin for Razen...${NC}"
    
    # Check if any JetBrains IDE is installed
    local jetbrains_found=false
    local jetbrains_dirs=("$HOME/Library/Application Support/JetBrains" "$HOME/.local/share/JetBrains")
    
    for dir in "${jetbrains_dirs[@]}"; do
        if [ -d "$dir" ]; then
            jetbrains_found=true
            echo -e "  ${GREEN}✓${NC} JetBrains IDE detected at: $dir"
            break
        fi
    done
    
    # Create plugin directory
    local jetbrains_plugin_source_dir="$INSTALL_DIR/razen-jetbrains-plugin"
    local jetbrains_plugin_target_dir="$HOME/.razen/jetbrains-plugin"
    
    mkdir -p "$jetbrains_plugin_target_dir"
    
    # Check if plugin source exists
    if [ -d "$jetbrains_plugin_source_dir" ] && [ "$(ls -A "$jetbrains_plugin_source_dir" 2>/dev/null)" ]; then
        # Copy plugin files
        cp -r "$jetbrains_plugin_source_dir/"* "$jetbrains_plugin_target_dir/"
        echo -e "  ${GREEN}✓${NC} JetBrains plugin files copied to: $jetbrains_plugin_target_dir"
    else
        # Create placeholder files
        echo -e "  ${YELLOW}⚠${NC} Plugin source not found, creating placeholder..."
        
        # Create README file
        cat > "$jetbrains_plugin_target_dir/README.md" << EOL
# Razen Language Plugin for JetBrains IDEs

This is a placeholder for the Razen language plugin for JetBrains IDEs.
The actual plugin will be available soon.

## Installation Instructions

1. Open your JetBrains IDE (IntelliJ IDEA, PyCharm, etc.)
2. Go to Settings/Preferences > Plugins
3. Click the gear icon and select "Install Plugin from Disk..."
4. Navigate to the plugin JAR file location
5. Restart the IDE

## Features

- Syntax highlighting for Razen (.rzn) files
- Code completion
- Error highlighting
- Navigation
- Refactoring tools

## Support

For support, please visit the Razen language website or GitHub repository.
EOL
        
        echo -e "  ${GREEN}✓${NC} JetBrains plugin placeholder created at: $jetbrains_plugin_target_dir"
    fi
    
    if [ "$jetbrains_found" = true ]; then
        echo -e "  ${YELLOW}To install the plugin in your JetBrains IDE:${NC}"
        echo -e "  1. Open your JetBrains IDE (IntelliJ IDEA, PyCharm, etc.)"
        echo -e "  2. Go to Settings/Preferences > Plugins"
        echo -e "  3. Click the gear icon and select 'Install Plugin from Disk...'"
        echo -e "  4. Navigate to $jetbrains_plugin_target_dir and select the plugin JAR file"
        echo -e "  5. Restart the IDE"
        return 0
    else
        echo -e "  ${YELLOW}No JetBrains IDE detected. Plugin files have been saved to:${NC}"
        echo -e "  ${CYAN}$jetbrains_plugin_target_dir${NC}"
        echo -e "  ${YELLOW}Install a JetBrains IDE to use the plugin${NC}"
        return 1
    fi
}

# Function to display installation summary
show_installation_summary() {
    local install_dir="$1"
    local version="$2"
    local symlinks_created="$3"
    local vscode_ext_installed="$4"
    local jetbrains_plugin_installed="$5"
    
    echo -e "\n${GREEN}✅ Razen $version has been successfully installed!${NC}"
    
    # Installation details
    echo -e "\n${YELLOW}Installation Details:${NC}"
    echo -e "  • Installation Directory: ${CYAN}$install_dir${NC}"
    echo -e "  • Version: ${CYAN}$version${NC}"
    echo -e "  • Symbolic Links: ${CYAN}$([ "$symlinks_created" = "0" ] && echo "Created" || echo "Some Issues")${NC}"
    echo -e "  • VS Code Extension: ${CYAN}$([ "$vscode_ext_installed" = "0" ] && echo "Installed" || echo "Not Installed")${NC}"
    echo -e "  • JetBrains Plugin: ${CYAN}$([ "$jetbrains_plugin_installed" = "0" ] && echo "Installed" || echo "Not Installed")${NC}"
    
    # Available commands
    echo -e "\n${YELLOW}Available Commands:${NC}"
    echo -e "  • ${GREEN}razen${NC} <file.rzn> - Run a Razen program"
    echo -e "  • ${GREEN}razen-debug${NC} <file.rzn> - Run a Razen program in debug mode"
    echo -e "  • ${GREEN}razen-test${NC} <file.rzn> - Run tests for a Razen program"
    echo -e "  • ${GREEN}razen-run${NC} <file.rzn> - Run a Razen program with additional options"
    echo -e "  • ${GREEN}razen-update${NC} - Update Razen to the latest version"
    echo -e "  • ${GREEN}razen-help${NC} - Show help information"
    echo -e "  • ${GREEN}razen-extension${NC} - Manage Razen extensions"
    
    # Example usage
    echo -e "\n${YELLOW}Example Usage:${NC}"
    echo -e "  ${CYAN}razen hello.rzn${NC}"
    echo -e "  ${CYAN}razen-debug app.rzn${NC}"
    echo -e "  ${CYAN}razen-update${NC}"
    
    # Next steps
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "  1. Create a new Razen program: ${CYAN}razen new myprogram.rzn${NC}"
    echo -e "  2. Run the example programs: ${CYAN}razen examples/hello.rzn${NC}"
    echo -e "  3. Check for updates: ${CYAN}razen-update${NC}"
    
    # Important notes
    echo -e "\n${YELLOW}Important Notes:${NC}"
    echo -e "  • You may need to restart your terminal for the PATH changes to take effect"
    echo -e "  • To uninstall Razen, run: ${CYAN}sudo ./install-mac.sh --uninstall${NC}"
    echo -e "  • For help and documentation, run: ${CYAN}razen-help${NC}"
    
    # Support information
    echo -e "\n${YELLOW}Support:${NC}"
    echo -e "  • GitHub: ${CYAN}https://github.com/BasaiCorp/razen-lang${NC}"
    echo -e "  • Documentation: Coming soon"
    echo -e "  • Report Issues: ${CYAN}https://github.com/BasaiCorp/razen-lang/issues${NC}"
    
    echo -e "\n${CYAN}Thank you for installing Razen! Happy coding!${NC}"
}

# Function to create installation directories
create_installation_directories() {
    echo -e "${YELLOW}Creating installation directories...${NC}"
    
    # Create installation directory
    if ! sudo mkdir -p "$INSTALL_DIR"; then
        cleanup_and_exit "Failed to create installation directory" "Check your permissions and try again"
    fi
    echo -e "  ${GREEN}✓${NC} Created main installation directory"
    
    # Create subdirectories
    local subdirs=("src" "src/functions" "properties" "properties/libs" "scripts" "examples" "examples/web-example" "razen-vscode-extension" "razen-vscode-extension/src" "razen-vscode-extension/syntaxes" "razen-vscode-extension/language-configuration" "razen-vscode-extension/snippets" "razen-vscode-extension/icons" "razen-jetbrains-plugin")
    for dir in "${subdirs[@]}"; do
        if ! sudo mkdir -p "$INSTALL_DIR/$dir"; then
            cleanup_and_exit "Failed to create $INSTALL_DIR/$dir" "Check your permissions and try again"
        fi
        echo -e "  ${GREEN}✓${NC} Created $dir directory"
    done
    
    return 0
}

# Function to download Razen files with retry
download_razen_files() {
    echo -e "${YELLOW}Downloading Razen files...${NC}"
    local download_success=true
    
    # Download main.py
    if ! download_with_retry "$RAZEN_REPO/main.py" "$TMP_DIR/main.py" "main.py"; then
        echo -e "  ${RED}✗${NC} Failed to download main.py"
        download_success=false
    fi
    
    # Download src files
    local src_files=("main.rs" "compiler.rs" "parser.rs" "lexer.rs" "interpreter.rs" "ast.rs" "token.rs" "value.rs" "library.rs" "functions.rs")
    for file in "${src_files[@]}"; do
        if ! download_with_retry "$RAZEN_REPO/src/$file" "$TMP_DIR/src/$file" "src/$file"; then
            echo -e "  ${RED}✗${NC} Failed to download src/$file"
            # Create empty file as fallback
            touch "$TMP_DIR/src/$file"
            echo -e "  ${YELLOW}⚠${NC} Created empty src/$file as fallback"
        fi
    done
    
    # Create functions directory and download function files
    mkdir -p "$TMP_DIR/src/functions"
    echo -e "  ${GREEN}✓${NC} Created functions directory"
    
    # Download function files
    local function_files=("arrlib.rs" "mathlib.rs" "strlib.rs" "randomlib.rs" "filelib.rs" "jsonlib.rs" "boltlib.rs" "seedlib.rs" "colorlib.rs" "cryptolib.rs" "regexlib.rs" "uuidlib.rs" "oslib.rs" "validationlib.rs" "systemlib.rs" "boxutillib.rs" "loglib.rs" "htlib.rs" "netlib.rs" "timelib.rs" "color.rs")
    for file in "${function_files[@]}"; do
        if ! download_with_retry "$RAZEN_REPO/src/functions/$file" "$TMP_DIR/src/functions/$file" "src/functions/$file"; then
            echo -e "  ${RED}✗${NC} Failed to download src/functions/$file"
            # Create empty file as fallback
            touch "$TMP_DIR/src/functions/$file"
            echo -e "  ${YELLOW}⚠${NC} Created empty src/functions/$file as fallback"
        fi
    done
    
    # Download properties files
    local prop_files=("variables.rzn" "keywords.rzn" "operators.rzn" "functions.rzn" "loops.rzn" "conditionals.rzn" "types.rzn" "api.rzn" "syntax.rzn" "usage.rzn")
    for file in "${prop_files[@]}"; do
        if ! download_with_retry "$RAZEN_REPO/properties/$file" "$TMP_DIR/properties/$file" "properties/$file"; then
            echo -e "  ${YELLOW}⚠${NC} Failed to download properties/$file"
            # Create empty file as fallback
            touch "$TMP_DIR/properties/$file"
            echo -e "  ${YELLOW}⚠${NC} Created empty properties/$file as fallback"
        fi
    done
    
    # Create libs directory and download library files
    mkdir -p "$TMP_DIR/properties/libs"
    echo -e "  ${GREEN}✓${NC} Created libs directory"
    
    # Download library files
    local lib_files=("arrlib.rzn" "strlib.rzn" "mathlib.rzn" "random.rzn" "file.rzn" "json.rzn" "bolt.rzn" "seed.rzn" "color.rzn" "crypto.rzn" "regex.rzn" "uuid.rzn" "os.rzn" "validation.rzn" "system.rzn" "boxlib.rzn" "loglib.rzn" "htlib.rzn" "netlib.rzn" "timelib.rzn")
    for file in "${lib_files[@]}"; do
        if ! download_with_retry "$RAZEN_REPO/properties/libs/$file" "$TMP_DIR/properties/libs/$file" "properties/libs/$file"; then
            echo -e "  ${YELLOW}⚠${NC} Failed to download properties/libs/$file"
            # Create empty file as fallback
            touch "$TMP_DIR/properties/libs/$file"
            echo -e "  ${YELLOW}⚠${NC} Created empty properties/libs/$file as fallback"
        fi
    done
    
    # Download script files
    local script_files=("razen" "razen-debug" "razen-test" "razen-run" "razen-update" "razen-help" "razen-extension" "razen-docs" "razen-autogen" "razen-run-debug")
    for script in "${script_files[@]}"; do
        if ! download_with_retry "$RAZEN_REPO/scripts/$script" "$TMP_DIR/scripts/$script" "scripts/$script"; then
            echo -e "  ${YELLOW}⚠${NC} Failed to download scripts/$script"
            # Create empty file as fallback
            touch "$TMP_DIR/scripts/$script"
            echo -e "  ${YELLOW}⚠${NC} Created empty scripts/$script as fallback"
        fi
    done
    
    # Make scripts executable
    chmod +x "$TMP_DIR/scripts/"*
    echo -e "  ${GREEN}✓${NC} Made scripts executable"
    
    # Download example files
    mkdir -p "$TMP_DIR/examples"
    local example_files=("hello.rzn" "calculator.rzn" "web-example/script.rzn" "quiz.rzn" "guess.rzn" "12-16.rzn" "library_test.rzn" "color_test.rzn" "purchase.rzn" "order.rzn" "web-example/index.html" "web-example/style.css")
    for file in "${example_files[@]}"; do
        if ! download_with_retry "$RAZEN_REPO/examples/$file" "$TMP_DIR/examples/$file" "examples/$file"; then
            echo -e "  ${YELLOW}⚠${NC} Failed to download examples/$file"
            # Create directory for file if needed
            mkdir -p "$(dirname "$TMP_DIR/examples/$file")"
            # Create empty file as fallback
            touch "$TMP_DIR/examples/$file"
            echo -e "  ${YELLOW}⚠${NC} Created empty examples/$file as fallback"
        fi
    done
    
    # Try to download VS Code extension files
    mkdir -p "$TMP_DIR/razen-vscode-extension"
    if ! download_with_retry "$RAZEN_REPO/razen-vscode-extension/package.json" "$TMP_DIR/razen-vscode-extension/package.json" "VS Code extension files"; then
        echo -e "  ${YELLOW}⚠${NC} VS Code extension files not found or couldn't be downloaded"
    fi
    
    # Try to download JetBrains plugin files
    mkdir -p "$TMP_DIR/razen-jetbrains-plugin"
    if ! download_with_retry "$RAZEN_REPO/razen-jetbrains-plugin/README.md" "$TMP_DIR/razen-jetbrains-plugin/README.md" "JetBrains plugin files"; then
        echo -e "  ${YELLOW}⚠${NC} JetBrains plugin files not found or couldn't be downloaded"
    fi
    
    if [ "$download_success" = false ]; then
        echo -e "${YELLOW}Warning: Some essential files failed to download. Installation may be incomplete.${NC}"
        echo -e "${YELLOW}You may want to run the installer again with better internet connectivity.${NC}"
    else
        echo -e "  ${GREEN}✓${NC} All essential downloads completed successfully"
    fi
    
    return 0
}

# Function to copy files to installation directory
copy_files_to_install_dir() {
    echo -e "${YELLOW}Copying files to installation directory...${NC}"
    
    # Copy main.py
    if ! sudo cp "$TMP_DIR/main.py" "$INSTALL_DIR/"; then
        cleanup_and_exit "Failed to copy main.py to installation directory" "Check your permissions and try again"
    fi
    
    # Copy src files
    if ! sudo cp -r "$TMP_DIR/src/"* "$INSTALL_DIR/src/" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC} Some src files may not have been copied"
    fi
    
    # Copy properties files
    if ! sudo cp -r "$TMP_DIR/properties/"* "$INSTALL_DIR/properties/" 2>/dev/null; then
        echo -e "  ${YELLOW}⚠${NC} Some properties files may not have been copied"
    fi
    
    # Copy scripts
    if ! sudo cp -r "$TMP_DIR/scripts/"* "$INSTALL_DIR/scripts/" 2>/dev/null; then
        cleanup_and_exit "Failed to copy scripts to installation directory" "Check your permissions and try again"
    fi
    
    # Copy examples
    if [ -d "$TMP_DIR/examples" ] && [ "$(ls -A "$TMP_DIR/examples" 2>/dev/null)" ]; then
        sudo cp -r "$TMP_DIR/examples/"* "$INSTALL_DIR/examples/" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Copied example files"
    fi
    
    # Copy VS Code extension files
    if [ -d "$TMP_DIR/razen-vscode-extension" ]; then
        # Copy all extension files
        sudo cp -r "$TMP_DIR/razen-vscode-extension/"* "$INSTALL_DIR/razen-vscode-extension/" 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Copied VS Code extension files"
        
        # Ensure all subdirectories are properly copied
        for subdir in "src" "syntaxes" "language-configuration" "snippets" "icons"; do
            if [ -d "$TMP_DIR/razen-vscode-extension/$subdir" ]; then
                sudo cp -r "$TMP_DIR/razen-vscode-extension/$subdir/"* "$INSTALL_DIR/razen-vscode-extension/$subdir/" 2>/dev/null || true
                echo -e "  ${GREEN}✓${NC} Copied VS Code extension $subdir files"
            fi
        done
    else
        echo -e "  ${YELLOW}⚠${NC} VS Code extension files not found"
    fi
    
    # Copy JetBrains plugin files
    if [ -d "$TMP_DIR/razen-jetbrains-plugin" ] && [ "$(ls -A "$TMP_DIR/razen-jetbrains-plugin" 2>/dev/null)" ]; then
        sudo cp -r "$TMP_DIR/razen-jetbrains-plugin/"* "$INSTALL_DIR/razen-jetbrains-plugin/" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Copied JetBrains plugin files"
    fi
    
    # Download and save the latest installer script for future updates
    if ! download_with_retry "$RAZEN_REPO/install-mac.sh" "$TMP_DIR/install-mac.sh" "latest installer script"; then
        echo -e "${YELLOW}Warning: Could not download latest installer script. Using current version instead.${NC}"
        # If we're running from a downloaded script, copy it
        if [ -f "$0" ] && [[ "$0" != "/usr/local/bin/"* ]]; then
            sudo cp "$0" "$INSTALL_DIR/install-mac.sh"
        fi
    else
        sudo cp "$TMP_DIR/install-mac.sh" "$INSTALL_DIR/install-mac.sh"
    fi
    
    # Set proper permissions
    sudo chmod -R 755 "$INSTALL_DIR"
    sudo chown -R root:wheel "$INSTALL_DIR"
    
    echo -e "  ${GREEN}✓${NC} Copied files to installation directory"
    
    # Create version file in installation directory
    echo "$RAZEN_VERSION" | sudo tee "$INSTALL_DIR/version" > /dev/null
    echo -e "  ${GREEN}✓${NC} Created version file"
    
    return 0
}

# Function to check for Rust installation and install if needed
check_and_install_rust() {
    echo -e "${YELLOW}Checking for Rust installation...${NC}"
    
    if ! command -v rustc &> /dev/null; then
        echo -e "${YELLOW}Rust is not installed. Razen compiler requires Rust to run.${NC}"
        echo -e "${YELLOW}Would you like to install Rust now? (y/n)${NC}"
        read -p "Enter your choice: " rust_choice
        
        if [[ "$rust_choice" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Installing Rust...${NC}"
            
            # Download and run the Rust installer
            if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
                echo -e "${RED}Failed to install Rust.${NC}"
                echo -e "${YELLOW}Please install Rust manually:${NC}"
                echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
                return 1
            fi
            
            # Source the cargo environment
            source "$HOME/.cargo/env"
            
            # Verify Rust installation
            if ! command -v rustc &> /dev/null; then
                echo -e "${RED}Rust installation completed but rustc command not found.${NC}"
                echo -e "${YELLOW}Please restart your terminal and run the installer again.${NC}"
                return 1
            fi
            
            echo -e "  ${GREEN}✓${NC} Rust has been successfully installed"
        else
            echo -e "${YELLOW}Rust installation skipped. Razen requires Rust to run.${NC}"
            echo -e "${YELLOW}Please install Rust manually:${NC}"
            echo -e "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
            return 1
        fi
    else
        RUST_VERSION=$(rustc --version | cut -d' ' -f2)
        echo -e "  ${GREEN}✓${NC} Rust is already installed (version $RUST_VERSION)"
    fi
    
    return 0
}

# Get version from the version file
echo -e "${YELLOW}Checking Razen version...${NC}"
if [ -f "version" ]; then
    RAZEN_VERSION=$(cat version)
    echo -e "  ${GREEN}✓${NC} Found local version file: $RAZEN_VERSION"
else
    # Download version file if not present
    if ! download_with_retry "$RAZEN_REPO/version" "version" "version information"; then
        echo -e "${YELLOW}Using default version due to download failure.${NC}"
        RAZEN_VERSION="beta v0.1.4"
    else
        RAZEN_VERSION=$(cat version)
        echo -e "  ${GREEN}✓${NC} Downloaded version information: $RAZEN_VERSION"
    fi
fi

# Remove any trailing whitespace or newlines
RAZEN_VERSION=$(echo "$RAZEN_VERSION" | tr -d '[:space:]')

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
echo -e "${YELLOW}Copyright 2025 Prathmesh Barot${NC}\n"
sleep 1  # Add a small delay to make the banner more readable

# Check if running as root
if ! check_sudo_privileges; then
    exit 1
fi

# Create temporary directory
TMP_DIR=$(mktemp -d)
if [ $? -ne 0 ]; then
    cleanup_and_exit "Failed to create temporary directory" "Check your permissions and try again"
fi
echo -e "${GREEN}  ✓ Created temporary directory${NC}"

# Create necessary directories in temp folder
mkdir -p "$TMP_DIR/src"
mkdir -p "$TMP_DIR/properties"
mkdir -p "$TMP_DIR/scripts"
mkdir -p "$TMP_DIR/examples"
mkdir -p "$TMP_DIR/razen-vscode-extension"
mkdir -p "$TMP_DIR/razen-jetbrains-plugin"

# Create installation directory
INSTALL_DIR="/usr/local/razen"
create_installation_directories

# Download Razen files
download_razen_files

# Copy files to installation directory
copy_files_to_install_dir

# Create symbolic links
symlink_result=1
create_symlinks "$INSTALL_DIR"
symlink_result=$?

# Check for Rust installation
check_and_install_rust
rust_installed=$?

# Ask about IDE extension installation
echo -e "\n${YELLOW}Would you like to install IDE extensions for Razen?${NC}"
echo -e "1. ${CYAN}VS Code Extension${NC} (works with VS Code and forks like VSCodium)"
echo -e "2. ${CYAN}JetBrains Plugin${NC} (works with IntelliJ IDEA, PyCharm, WebStorm, etc.)"
echo -e "3. ${CYAN}Skip${NC} (don't install IDE extensions)"

read -p "Enter your choice (1-3): " ide_choice
echo

# Install IDE extensions based on user choice
vscode_ext_installed=1
jetbrains_plugin_installed=1

case $ide_choice in
    1)
        install_vscode_extension
        vscode_ext_installed=$?
        ;;
    2)
        install_jetbrains_plugin
        jetbrains_plugin_installed=$?
        ;;
    3)
        echo -e "${YELLOW}Skipping IDE extension installation.${NC}"
        echo -e "${CYAN}You can install extensions later from:${NC}"
        echo -e "  VS Code: $INSTALL_DIR/razen-vscode-extension/"
        echo -e "  JetBrains: $INSTALL_DIR/razen-jetbrains-plugin/"
        ;;
esac

# Display installation summary
show_installation_summary "$INSTALL_DIR" "$RAZEN_VERSION" "$symlink_result" "$vscode_ext_installed" "$jetbrains_plugin_installed"

# Success message
echo -e "\n${GREEN}✅ Razen has been successfully installed!${NC}"
echo -e "\n${YELLOW}Available commands:${NC}"
echo -e "  ${GREEN}razen${NC} - Run Razen programs"
echo -e "  ${GREEN}razen-debug${NC} - Run Razen programs in debug mode"
echo -e "  ${GREEN}razen-test${NC} - Run tests for a Razen program"
echo -e "  ${GREEN}razen-run${NC} - Run a Razen program with additional options"
echo -e "  ${GREEN}razen-update${NC} - Update Razen to the latest version"
echo -e "  ${GREEN}razen-help${NC} - Show help information"
echo -e "  ${GREEN}razen-extension${NC} - Manage Razen extensions"
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