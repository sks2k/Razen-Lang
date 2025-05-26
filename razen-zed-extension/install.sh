#!/bin/bash

# Razen Zed Extension Installation Script
# This script builds and installs the Razen language extension for Zed IDE

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "extension.toml" ] || [ ! -f "Cargo.toml" ]; then
    print_error "This script must be run from the razen-zed-extension directory"
    print_error "Make sure you're in the directory containing extension.toml and Cargo.toml"
    exit 1
fi

print_status "Starting Razen Zed Extension installation..."

# Check if Rust is installed
if ! command -v cargo &> /dev/null; then
    print_error "Cargo (Rust) is not installed or not in PATH"
    print_status "Please install Rust via rustup: https://rustup.rs/"
    print_status "Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

print_success "Rust/Cargo found: $(cargo --version)"

# Check if Zed is installed
ZED_PATH=""
if command -v zed &> /dev/null; then
    ZED_PATH="zed"
elif [ -d "/Applications/Zed.app" ]; then
    ZED_PATH="/Applications/Zed.app/Contents/MacOS/zed"
elif [ -f "/usr/bin/zed" ]; then
    ZED_PATH="/usr/bin/zed"
elif [ -f "/usr/local/bin/zed" ]; then
    ZED_PATH="/usr/local/bin/zed"
else
    print_warning "Zed IDE not found in common locations"
    print_warning "Please make sure Zed is installed before proceeding"
fi

if [ -n "$ZED_PATH" ]; then
    print_success "Zed IDE found at: $ZED_PATH"
fi

# Add wasm32-wasi target if not present
print_status "Checking for wasm32-wasi target..."
if ! rustup target list --installed | grep -q "wasm32-wasi"; then
    print_status "Adding wasm32-wasi target..."
    rustup target add wasm32-wasi
    print_success "wasm32-wasi target added"
else
    print_success "wasm32-wasi target already installed"
fi

# Clean previous builds
print_status "Cleaning previous builds..."
cargo clean

# Build the extension
print_status "Building Razen Zed extension..."
if cargo build --release --target wasm32-wasi; then
    print_success "Extension built successfully"
else
    print_error "Failed to build extension"
    print_error "Check the error messages above and fix any issues"
    exit 1
fi

# Check if build artifacts exist
WASM_FILE="target/wasm32-wasi/release/razen_zed_extension.wasm"
if [ ! -f "$WASM_FILE" ]; then
    print_error "WebAssembly file not found: $WASM_FILE"
    print_error "Build may have failed"
    exit 1
fi

print_success "WebAssembly file created: $WASM_FILE"

# Get extension directory path
EXTENSION_DIR=$(pwd)
print_status "Extension directory: $EXTENSION_DIR"

# Check if all required files are present
REQUIRED_FILES=(
    "extension.toml"
    "languages/razen/config.toml"
    "languages/razen/highlights.scm"
    "languages/razen/textobjects.scm"
    "languages/razen/brackets.scm"
    "languages/razen/outline.scm"
    "languages/razen/indents.scm"
)

print_status "Checking required files..."
MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    print_error "Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        print_error "  - $file"
    done
    exit 1
fi

print_success "All required files present"

# Display installation instructions
echo
print_status "Build completed successfully!"
echo
print_status "To install the extension in Zed:"
echo "  1. Open Zed IDE"
echo "  2. Press Cmd+Shift+X (macOS) or Ctrl+Shift+X (Windows/Linux)"
echo "  3. Click 'Install Dev Extension'"
echo "  4. Select this directory: $EXTENSION_DIR"
echo "  5. Restart Zed IDE"
echo
print_status "To test the extension:"
echo "  1. Create a new file with .rzn extension"
echo "  2. Add some Razen code"
echo "  3. Verify syntax highlighting works"
echo
print_success "Installation script completed!"

# Optional: Try to open Zed with the extension directory
if [ -n "$ZED_PATH" ] && [ "$1" = "--open-zed" ]; then
    print_status "Opening Zed IDE..."
    "$ZED_PATH" "$EXTENSION_DIR" &
fi

# Create a test file
TEST_FILE="test_syntax.rzn"
if [ ! -f "$TEST_FILE" ]; then
    print_status "Creating test file: $TEST_FILE"
    cat > "$TEST_FILE" << 'EOF'
type script;

# Razen Language Test File
lib mathlib;
lib strlib;

let number = 42;
take message = "Hello, Razen!";
hold isActive = true;

fun greet(name) {
    if (name == null) {
        return "Hello, Guest!";
    }
    return "Hello, " + name + "!";
}

let result = MathLib[add](5, 3);
take upperMessage = StrLib[upper](message);

show greet("World");
show "Result: " + result;
show(green) "Extension test file created!";
EOF
    print_success "Test file created: $TEST_FILE"
    print_status "Use this file to test the extension after installation"
fi

echo
print_success "🎉 Razen Zed Extension is ready for installation!"
print_status "Follow the installation instructions above to complete setup."