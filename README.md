# Razen Programming Language (beta v0.1.3)

## Overview
Razen is a modern, intuitive programming language designed for clarity, performance, and ease of use. With a clean syntax inspired by Python and strong type safety, Razen offers an excellent balance between development speed and runtime performance.

Developed by Prathmesh Barot, Basai Corporation.

## Features
- **Intuitive Syntax**: Python-like syntax that's easy to read and write
- **Fast Performance**: Built for efficiency with optimized runtime execution
- **Built-in Debugging**: Comprehensive debugging tools including step-by-step execution
- **String Interpolation**: Powerful nested string interpolation with `${...}` syntax
- **Type Flexibility**: Combines dynamic typing with optional type annotations
- **Expressive Conditionals**: Clean if/else syntax with support for nested conditions
- **Interactive Mode**: Built-in REPL for testing code snippets
- **Lightweight**: Small footprint with minimal dependencies
- **Cross-platform support**: Works on Linux, macOS, and Windows

## Installation

### Linux
```bash
# Using curl
curl -o install.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" && chmod +x install.sh && sudo ./install.sh
```

```bash
# Using wget
wget -O install.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" && chmod +x install.sh && sudo ./install.sh
```

### macOS
```bash
# Using curl
curl -o install-mac.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install-mac.sh" && chmod +x install-mac.sh && sudo ./install-mac.sh
```

```bash
# Using Homebrew (coming soon)
brew install razen
```

### Windows
```powershell
# Using PowerShell (Run as Administrator)
# First, create a temporary directory and change to it
cd $env:USERPROFILE\Desktop
# Download and run the installer
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.ps1" -OutFile "install.ps1"; .\install.ps1
```

```powershell
# Alternative method (if the above doesn't work):
# 1. Open PowerShell as Administrator
# 2. Run these commands:
cd $env:USERPROFILE\Desktop
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.ps1" -OutFile "install.ps1"
.\install.ps1
```

This will download and install Razen globally on your system, making the `razen` command available from anywhere.

### Keeping Razen Updated

To update Razen to the latest version:
```bash
razen-update
```

This will automatically check for updates and install the newest version if available.

### Uninstalling Razen

To uninstall Razen:
```bash
razen uninstall
```

Alternatively:
```bash
sudo /usr/local/lib/razen/install.sh --uninstall
```

## Usage

### Command Reference

```bash
# Core Commands
razen <filename.rzn>       # Run a Razen script
razen new <filename>       # Create a new Razen program
razen version              # Display version information
razen help                 # Show help information
razen uninstall            # Uninstall Razen

# Specialized Tools
razen-debug <filename.rzn> # Debug mode with detailed output
razen-test <filename.rzn>  # Test mode for testing scripts
razen-run <filename.rzn>   # Clean mode (only shows program output)
razen-update               # Update to the latest version
razen-help                 # Display detailed help with formatting
```

### Running Scripts

```bash
razen path/to/script.rzn       # Standard execution
razen-debug path/to/script.rzn # Debug mode with detailed output
razen-test path/to/script.rzn  # Test mode for testing scripts
razen-run path/to/script.rzn   # Clean mode (only shows program output)
```

### Creating Your First Razen Program

You can create a new Razen program with a template:
```bash
razen new hello
```

This creates a new file `hello.rzn` with a Hello World template:
```razen
// New Razen program created on [current date]
// Powered by Razen Language

// Your code goes here
let message = "Hello, World!"
show "${message}"

// Read user input
read user_input = "What's your name? "
show "Nice to meet you, ${user_input}!"
```

Run it with:
```bash
razen-run hello.rzn
```

## Example Code

```razen
// Variables
let name = "World"
let price = 9.99
let quantity = 5
let is_available = true

// String interpolation
show "Hello, ${name}!"

// Calculations
let total = price * quantity
show "Total cost: ${total}"

// Conditionals
if total > 50 {
    show "Qualifies for free shipping!"
} else {
    show "Add more items for free shipping."
}

// Input
read user_input = "Enter your name: "
show "Hello, ${user_input}!"

// Nested interpolation
let inner = "value"
let outer = "Outer with ${inner}"
show "${outer}"
```

Check the `examples` folder for more sample programs and tutorials.

## Command Details

### razen-update
A dedicated command to check for and install updates from the main repository. It shows the current version and latest available version, then performs the update if a newer version is available.

### razen-help
A colorful, well-formatted help command that displays comprehensive information about all available Razen commands, tools, and usage examples.

### razen new
Creates a new Razen program with a template to help you get started quickly. Automatically adds the `.rzn` extension if not provided.

### razen uninstall
Safely removes all Razen files and symbolic links from your system. Provides confirmation before proceeding.

## File Locations

- **Core files**: `/usr/local/lib/razen`
- **Examples**: `/usr/local/lib/razen/examples`
- **Scripts**: `/usr/local/lib/razen/scripts`

## License
Razen is licensed under a custom license. See the [LICENSE](./LICENSE) file for details.

Key points:
- You can use Razen for personal and commercial projects
- You can create libraries and applications using Razen
- You cannot modify, rebrand, or redistribute the core language
- You must include attribution: "Powered by Razen - © 2025 Prathmesh Barot"

## Attribution
When using Razen in your projects, please include the following attribution:

```
Powered by Razen - © 2025 Prathmesh Barot, Basai Corporation
```

## Contact
For questions, support, or feedback about Razen, please contact:
- Email: prathmesh.barot@example.com
- GitHub: [https://github.com/BasaiCorp/razen-lang](https://github.com/BasaiCorp/razen-lang)

**Official website coming soon!**
