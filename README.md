# Razen Programming Language (beta v0.1.5)

## Overview
Razen is a modern, intuitive programming language designed for clarity, performance, and ease of use. With a clean syntax inspired by Python and strong type safety, Razen offers an excellent balance between development speed and runtime performance.

Developed by Prathmesh Barot, Basai Corporation.

## Features
- **Intuitive Syntax**: Python-like syntax that's easy to read and write
- **Fast Performance**: Built for efficiency with optimized runtime execution
- **Built-in Debugging**: Comprehensive debugging tools including step-by-step execution
- **String Interpolation**: Powerful nested string interpolation with `${...}` syntax
- **Type Safety**: Strong type checking for variables with different variable types
- **Web Development**: First-class support for building web applications with HTML integration
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

### Basic Razen Program

```razen
// Variables with type enforcement
let number = 42          // Numeric values only
take message = "Hello"   // String values only
hold is_active = true    // Boolean values only
put anything = "flexible" // Any type allowed

// String interpolation
show "Hello, ${message}!"

// Calculations
let total = number * 2.5
show "Total: ${total}"

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
take inner = "value"
take outer = "Outer with ${inner}"
show "${outer}"
```

### Web Development with Razen

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Razen Web App</title>
</head>
<razen>
    // Define variables using standard Razen syntax
    let counter = 0;
    take greeting = "Hello from Razen!";
    
    // Initialize when the page loads
    on window load {
        // Update the greeting text
        get greeting_element {
            text content = greeting;
        }
        
        // Setup counter functionality
        get increment_button {
            on click {
                let counter = counter + 1;
                get counter_display {
                    text content = counter;
                }
            }
        }
    }
</razen>
<body>
    <h1 id="greeting_element"></h1>
    <p>Counter: <span id="counter_display">0</span></p>
    <button id="increment_button">Increment</button>
</body>
</html>
```

Check the `examples` folder for more sample programs and tutorials.

## Command Details

### razen-update
A dedicated command to check for and install updates from the main repository. It shows the current version and latest available version, then performs the update if a newer version is available.

### razen-help
A colorful, well-formatted help command that displays comprehensive information about all available Razen commands, tools, and usage examples.

### razen new
Creates a new Razen program with a template to help you get started quickly. Automatically adds the `.rzn` extension if not provided.

### razen-web
Creates a new Razen web application with HTML integration. This command sets up the basic structure for a web project using Razen for interactivity.

```bash
razen-web my-web-app
```

### razen-run-web
Runs a Razen web application and serves it on a local development server.

```bash
razen-run-web my-app.html.rzn
```

### razen uninstall
Safely removes all Razen files and symbolic links from your system. Provides confirmation before proceeding.

## File Locations

- **Core files**: `/usr/local/lib/razen`
- **Examples**: `/usr/local/lib/razen/examples`
- **Scripts**: `/usr/local/lib/razen/scripts`
- **Web Properties**: `/usr/local/lib/razen/properties/web-properties`

## Variable Types

Razen supports different variable types with type enforcement:

- **let**: For numeric values (integers and floats)
  ```razen
  let count = 42
  let price = 9.99
  ```

- **take**: For string values
  ```razen
  take name = "John"
  take message = "Hello, World!"
  ```

- **hold**: For boolean values
  ```razen
  hold is_active = true
  hold has_permission = false
  ```

- **put**: For any type (no type restrictions)
  ```razen
  put anything = 42
  put anything = "Now I'm a string"
  put anything = true
  ```

## Web Development

Razen provides powerful web development capabilities through its web properties. These properties allow you to create interactive web applications using the familiar Razen syntax while seamlessly integrating with HTML.

### Integration with HTML

Razen web code can be embedded in HTML files using the `<razen>` tag:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Razen Web App</title>
</head>
<razen>
    # Your Razen code here
</razen>
<body>
    <!-- HTML content -->
</body>
</html>
```

### Web Variables

Razen includes specialized variables for web development:

- **Element Access**: `get`, `query`, `all`
- **DOM Manipulation**: `html`, `text`, `attr`, `style`, `class`
- **Event Handling**: `on`, `off`, `trigger`
- **Form Handling**: `form`, `validate`, `submit`
- **AJAX and Fetch**: `fetch`, `post`, `get_data`
- **Storage**: `store_local`, `store_session`, `cookie`

See the examples directory for complete web application examples.

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
