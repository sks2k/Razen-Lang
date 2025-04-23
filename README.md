# Razen Programming Language (beta v0.1.658)

## Overview
Razen is a modern, intuitive programming language designed for clarity, performance, and ease of use. With a clean syntax inspired by Python and strong type safety, Razen offers an excellent balance between development speed and runtime performance.

Developed by Prathmesh Barot, Basai Corporation.

## Features
- **Intuitive Syntax**: Python-like syntax that's easy to read and write
- **Fast Performance**: Built for efficiency with optimized runtime execution
- **Built-in Debugging**: Comprehensive debugging tools including step-by-step execution
- **String Interpolation**: Powerful nested string interpolation with `${...}` syntax
- **Type Safety**: Strong type checking for variables with different variable types
- **Rich Library System**: Extensive library system with bracket notation for function calls
- **Expressive Conditionals**: Clean if/else syntax with support for nested conditions
- **Interactive Mode**: Built-in REPL for testing code snippets
- **Lightweight**: Small footprint with minimal dependencies
- **Cross-platform support**: Works on Linux, macOS, and Windows
- **OOP Support**: Class-based object-oriented programming capabilities
- **Colored Output**: Built-in support for colored terminal output
- **Robust Error Handling**: Comprehensive error handling with try/catch blocks

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
# New Razen program created on [current date]
# Powered by Razen Language

# Your code goes here
let message = "Hello, World!";
show message;

# Read user input
read user_input = "What's your name? ";
show "Nice to meet you, " + user_input + "!";
```

Run it with:
```bash
razen-run hello.rzn
```

## Example Code

### Basic Razen Program

```razen
# Variables with type enforcement
let number = 42;          # Numeric values only
take message = "Hello";   # String values only
hold is_active = true;    # Boolean values only
put anything = "flexible"; # Any type allowed

# String concatenation
show "Hello, " + message + "!";

# Calculations
let total = number * 2.5;
show "Total: " + total;

# Conditionals
if (total > 50) {
    show "Qualifies for free shipping!";
} else {
    show "Add more items for free shipping.";
}

# Input
read user_input = "Enter your name: ";
show "Hello, " + user_input + "!";

# String concatenation
take inner = "value";
take outer = "Outer with " + inner;
show outer;
```

### Colored Output

```razen
type cli;

# Using colors in output
show(red) "This is a red error message";
show(green) "This is a green success message";
show(yellow) "This is a yellow warning message";
show(blue) "This is a blue information message";
show(purple) "This is a purple highlight message";
show(cyan) "This is a cyan technical message";
```

### Function Definition and Usage

```razen
# Define a simple function to calculate factorial
fun factorial(n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

# Use the function
let num = 5;
show "Factorial of " + num + " is " + factorial(num);

# Function with multiple parameters
fun greet(name, age) {
    show "Hello, " + name + "! You are " + age + " years old.";
}

greet("Alice", 30);
```

### Library System with Bracket Notation

```razen
# Import libraries
lib arrlib;   # Array library
lib strlib;   # String library
lib mathlib;  # Math library
lib random;   # Random library
lib crypto;   # Crypto library for encryption and hashing

# Using library functions with bracket notation
show "Array operations:";
show "Original array: " + [1, 2, 3];
show "After push: " + ArrLib[push]([1, 2, 3], 4);
show "Join with dash: " + ArrLib[join](["a", "b", "c"], "-");

# String operations
show "String operations:";
show "Uppercase: " + StrLib[upper]("Hello, Razen!");
show "Replace: " + StrLib[replace]("Hello, Razen!", "Razen", "World");

# Math operations
show "Math operations:";
show "Square root: " + MathLib[sqrt](16);
show "Power: " + MathLib[power](2, 3);

# Random operations
show "Random operations:";
show "Random integer (1-10): " + Random[int](1, 10);
show "Random choice: " + Random[choice](["apple", "banana", "cherry"]);

# Crypto operations
show "Crypto operations:";
show "Hash of 'Hello, Razen!': " + Crypto[hash]("Hello, Razen!");
```

Check the `examples` folder for more sample programs and tutorials.

## Command Details

### razen-update
A dedicated command to check for and install updates from the main repository. It shows the current version and latest available version, then performs the update if a newer version is available.

### razen-help
A colorful, well-formatted help command that displays comprehensive information about all available Razen commands, tools, and usage examples.

### razen new
Creates a new Razen program with a template to help you get started quickly. Automatically adds the `.rzn` extension if not provided.

### razen-debug
Runs a Razen program in debug mode with detailed output, showing each step of execution.

```bash
razen-debug my-program.rzn
```

### razen-test
Runs a Razen program in test mode, useful for testing scripts and validating functionality.

```bash
razen-test my-program.rzn
```

### razen uninstall
Safely removes all Razen files and symbolic links from your system. Provides confirmation before proceeding.

## File Locations

- **Core files**: `/usr/local/lib/razen`
- **Examples**: `/usr/local/lib/razen/examples`
- **Scripts**: `/usr/local/lib/razen/scripts`
- **Library Files**: `/usr/local/lib/razen/properties/libs`

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

## Object-Oriented Programming

Razen supports class-based object-oriented programming with a clean and intuitive syntax.

### Class Declaration

```razen
class Person {
    # Constructor (implicitly called when creating new instances)
    fun init(name, age) {
        this.name = name;
        this.age = age;
    }
    
    # Method to display information
    fun display() {
        show "Name: " + this.name + ", Age: " + this.age;
    }
    
    # Method to have a birthday
    fun haveBirthday() {
        this.age = this.age + 1;
        show this.name + " is now " + this.age + " years old!";
    }
}

# Create a new Person instance
put person = new Person("John", 30);

# Call methods
person.display();
person.haveBirthday();
```

### Inheritance

Razen supports class inheritance using the `extends` keyword:

```razen
class Employee extends Person {
    fun init(name, age, position) {
        super.init(name, age);
        this.position = position;
    }
    
    fun display() {
        super.display();
        show "Position: " + this.position;
    }
}
```

See the examples directory for complete object-oriented programming examples.

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
- Email: prathmeshbarot2009@gmail.com
- GitHub: [https://github.com/BasaiCorp/razen-lang](https://github.com/BasaiCorp/razen-lang)

**Official website coming soon!**
