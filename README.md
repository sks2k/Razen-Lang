# Razen Programming Language

## Overview
Razen is a modern, intuitive programming language designed for clarity, performance, and ease of use. With a clean syntax inspired by Python and strong type safety, Razen offers an excellent balance between development speed and runtime performance.

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

### Option 1: Using the Install Script

```bash
# Clone the repository
git clone https://github.com/BasaiCorp/Razen-lang.git
cd razen-lang

# Run the install script
bash install.sh
```

### Option 2: One-Command Installation

Using wget:
```bash
wget -qO- "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" | bash
```

Using curl:
```bash
curl -s "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/install.sh" | bash
```

This will download and install Razen globally on your system, making the `razen` command available from anywhere.

### Uninstalling Razen

To uninstall Razen:
```bash
bash install.sh --uninstall
```

## Usage

### Running a Razen Script
```bash
razen path/to/script.rzn
```

### Debugging a Razen Script
```bash
razen-debug path/to/script.rzn
```

### Testing a Razen Script
```bash
razen-test path/to/script.rzn
```

### Running in Clean Mode (Only Output)
```bash
razen-run path/to/script.rzn
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
Powered by Razen - © 2025 Prathmesh Barot
```

## Contact
For questions, support, or feedback about Razen, please contact:
- Email: prathmesh.barot@example.com
- GitHub: [https://github.com/USERNAME/razen-lang](https://github.com/USERNAME/razen-lang) # Razen-Lang
