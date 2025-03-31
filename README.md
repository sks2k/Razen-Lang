# Razen Programming Language (beta v0.1.2)

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

## Installation

### One-Command Installation

Using wget:
```bash
wget -qO- "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" | bash
```

Using curl:
```bash
curl -o install.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" && chmod +x install.sh && ./install.sh
```

This will download and install Razen globally on your system, making the `razen` command available from anywhere.

### Keeping Razen Updated

To update Razen to the latest version:
```bash
razen update
```

This will automatically check for updates and install the newest version if available.

### Uninstalling Razen

To uninstall Razen:
```bash
bash install.sh --uninstall
```

## Usage

### Command Reference

```bash
razen                      # Run a Razen script
razen new myprogram.rzn    # Create a new Razen program
razen update               # Update to the latest version
razen version              # Display version information
razen help                 # Show help information
```

### Running Scripts

```bash
razen path/to/script.rzn       # Standard execution
razen-debug path/to/script.rzn # Debug mode with detailed output
razen-test path/to/script.rzn  # Test mode for testing scripts
razen-run path/to/script.rzn   # Clean mode (only shows program output)
```

### Creating Your First Razen Program

Create a file named `hello.rzn`:
```razen
// My first Razen program
let name = "World"
show "Hello, ${name}!"

// Ask for user input
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
