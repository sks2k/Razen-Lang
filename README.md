# Razen Programming Language beta v0.1.76 - Performance Boost & Enhanced Tooling

## Overview
Razen is a modern, intuitive programming language designed for clarity, performance, and ease of use. With a clean syntax inspired by Python and strong type safety, Razen offers an excellent balance between development speed and runtime performance.

Developed by Prathmesh Barot, Basai Corporation.

## Features
- **Intuitive Syntax**: Python-like syntax that's easy to read and write.
- **Fast Performance**: Built for efficiency with optimized runtime execution.
- **Built-in Debugging**: Comprehensive debugging tools including step-by-step execution.
- **Type Safety**: Strong type checking for variables with specialized declaration tokens.
- **Rich Library System**: Extensive library system with bracket notation for function calls.
- **Expressive Conditionals**: Clean if/else syntax with support for nested conditions.
- **Interactive Mode**: Built-in REPL for testing code snippets.
- **Lightweight**: Small footprint with minimal dependencies.
- **Cross-platform support**: Works on Linux, macOS, and Windows.
- **OOP Support**: Class-based object-oriented programming capabilities.
- **Colored Output**: Built-in support for colored terminal output.
- **Robust Error Handling**: Comprehensive error handling with try/catch blocks.
- **Filesystem Library**: Comprehensive filesystem operations for file and directory management.

## Changelog

Razen is under active development with regular updates. The latest version is **beta v0.1.76** which brings significant performance improvements and enhanced tooling.

### Latest Release: beta v0.1.76 – Performance Boost & Enhanced Tooling

This release focuses on performance optimizations, LLVM integration, and improved developer experience. View the full changelog:

- [Markdown Version (beta_v0.1.76.md)](changelogs/beta_v0.1.76.md)

#### Key Improvements in v0.1.76

- **Faster Installation**: Completely revamped installation process that's significantly faster and more lightweight
- **LLVM Integration**: Experimental support for LLVM-based compilation, enabling more powerful optimizations
- **Logging Updates**: Renamed logging functions to avoid conflicts (`info`→`infolog`, `warn`→`warnlog`, etc.)
- **VS Code Extension**: Improved syntax highlighting and smarter code completion
- **Memory Management**: Reduced memory usage and optimized performance across the board
- **Build System**: Streamlined build process with better dependency management

For a complete history of all version changelogs, please visit the [changelogs.mdx](changelogs/changelogs.mdx) file or browse the [changelogs](changelogs/) directory for individual version details.

## Installation

### Universal Installer (All Platforms)

Razen now provides a single universal installer that works across all major platforms:

```bash
# Using curl (Linux/macOS/Windows with Git Bash)
curl -o installer.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/installer.sh" && chmod +x installer.sh && ./installer.sh
```

```bash
# Using wget (Linux)
wget -O installer.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/installer.sh" && chmod +x installer.sh && ./installer.sh
```

### Windows Installation

For Windows users:
```bash
# Using Git Bash
curl -o installer.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/installer.sh" && chmod +x installer.sh && ./installer.sh
```

> **Note**: Windows installation requires Git Bash, which you can download from [https://git-scm.com/downloads](https://git-scm.com/downloads)

#### Windows Installation Notes

- **Git LFS Required**: The Razen installer relies on a pre-compiled compiler binary distributed via Git LFS. Please ensure you have Git LFS installed and that it's functioning correctly before running the installer. You can download it from [https://git-lfs.github.com/](https://git-lfs.github.com/).
- If you encounter issues, ensure Git LFS successfully pulled the compiler binary during the `git clone` step. You can manually run `git lfs pull` in the cloned repository directory if needed.
- Running Git Bash as Administrator might be necessary for the installer to copy files to system locations.

**Environment Requirements:**
- Git Bash (from Git for Windows)
- Administrator privileges (recommended)
- Internet connection for downloading dependencies
- At least 2GB free disk space

### Installation Options

The installer provides additional options:

```bash
./installer.sh           # Standard installation/update
./installer.sh force     # Force a fresh installation
./installer.sh uninstall # Remove Razen from your system
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
./installer.sh uninstall
```

or

```bash
razen uninstall
```

## Usage

### Command Reference

```bash
# Core Commands
razen <filename.rzn>       # Run a Razen script
razen new <filename>       # Create a new Razen program
razen version              # Display version information
razen help                 # Show help information

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
str message = "Hello, World!";
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
# Hello World program in Razen
show "Hello, World!";

# Variables with type enforcement
num int = 42;  # Numeric variable
str name = "Alice";  # String variable
bool is_active = true;  # Boolean variable
var anything = "This can be any type";  # Any type variable

# Mathematical operations 
num total = 100 + 50;  # Sum calculation
num result = 100 - 50;  # Difference calculation
num product = 5 * 10;  # Product calculation
num quotient = 20 / 4;  # Division calculation
num remainder = 10 % 3;  # Modulus calculation

str message = "Hello, " + name + "!";
show message;

# Conditional statements
if (int > 40) {
    show "Number is greater than 40";
} else if (int == 40) {
    show "Number is exactly 40";
} else {
    show "Number is less than 40";
}

# Loops
let i = 0;
while (i < 5) {
    show "Loop iteration: " + i;
    i = i + 1;
}

# Using library functions
show "Current time: " + date::now();
show "Random number: " + random::int(1, 100);

# Colored output
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
num int = 5;
show "Factorial of " + int + " is " + factorial(num);

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
show "After push: " + arrlib::push([1, 2, 3], 4);
show "Join with dash: " + arrlib::join(["a", "b", "c"], "-");

# String operations
show "String operations:";
show "Uppercase: " + strlib::upper("Hello, Razen!");
show "Replace: " + strlib::replace("Hello, Razen!", "Razen", "World");

# Math operations
show "Math operations:";
show "Square root: " + mathlib::sqrt(16);
show "Power: " + mathlib::power(2, 3);

# Random operations
show "Random operations:";
show "Random integer (1-10): " + arndom::int(1, 10);
show "Random choice: " + Random::choice(["apple", "banana", "cherry"]);

# Crypto operations
show "Crypto operations:";
show "Hash of 'Hello, Razen!': " + Crypto::hash("Hello, Razen!");
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

## File Locations

### Linux/macOS
- **Core files**: `/usr/local/lib/razen`
- **Examples**: `/usr/local/lib/razen/examples`
- **Scripts**: `/usr/local/lib/razen/scripts`
- **Library Files**: `/usr/local/lib/razen/properties/libs`

### Windows
- **Core files**: `C:\Program Files\Razen`
- **Examples**: `C:\Program Files\Razen\examples`
- **Scripts**: `C:\Program Files\Razen\scripts`
- **Executables**: `C:\Program Files\Razen\bin`

## Variable Types

Razen supports different variable types with type enforcement:

- **num**: For numeric values (integers and floats)
  ```razen
  num count = 42;
  num price = 9.99;
  ```

- **str**: For string values
  ```razen
  str name = "John";
  str message = "Hello, World!";
  ```

- **bool**: For boolean values
  ```razen
  bool is_active = true;
  bool has_permission = false;
  ```

- **var**: For any type (no type restrictions)
  ```razen
  var anything = 42;
  var anything = "Now I'm a string";
  var anything = true;
  ```

### Mathematical Variables

- **num**: For numeric operations & mathematical operations
  ```razen
  num total = 100 + 50;  # Sum calculation
  num result = 100 - 50;  # Difference calculation
  num product = 5 * 10;  # Product calculation
  num quotient = 20 / 4;  # Division calculation
  num remainder = 10 % 3;  # Modulus calculation
  ```

### Collection Variables

- **list**, **arr**, **append**, **remove**: For array operations
  ```razen
  list fruits = ["apple", "banana", "orange"];  # Dynamic array
  arr<num> temperatures = [72, 68, 75, 79, 71];  # Fixed-size array
  append(fruits, "mango");  # Array with appended element
  remove(fruits, "banana");  # Array after removal
  ```

### Dictionary/Map Variables

- **map**, **key**, **value**: For dictionary operations
  ```razen
  map userProfile = {
    "name": "Alex",
    "age": 28,
    "isActive": true
  }  # Key-value storage using arrays
  for (key in userProfile) {
    show key + ": " + userProfile:key; 
  }  # Dictionary keys
  for (value in userProfile) {
    show value;
  }  # Dictionary values
  ```

### User-Defined Variables

- **store**, **box**, **ref**: For special variable operations
  ```razen
  store userData = loadUserData();
  saveToStore(userData);  # Persistent storage
  with box tempFile = File["open"]("data.txt") {
    # Process file
    # File will be automatically closed when exiting this block
  }  # Temporary storage
  ref currentUser = users:activeIndex;
  currentUser:lastLogin = now();  # Reference to another variable
  ```

## Object-Oriented Programming

Razen supports class-based object-oriented programming with a clean and intuitive syntax.

### Class Declaration

```razen
class Person {
    # Constructor (implicitly called when creating new instances)
    fun init(name, age) {
        this:name = name;
        this:age = age;
    }

    # Method to display information
    fun display() {
        show "Name: " + this:name + ", Age: " + this:age; 
    }

    # Method to have a birthday
    fun haveBirthday() {
        this:age = this:age + 1;
        show this:name + " is now " + this:age + " years old!";
    }
}

# Create a new Person instance
put person = new Person("John", 30);

# Call methods
person::display();
person::haveBirthday();
```

### Inheritance

Razen supports class inheritance using the `extends` keyword:

```razen
class Employee extends Person {
    fun init(name, age, position) {
        super:init(name, age);
        this:position = position;
    }

    fun display() {
        super:display();
        show "Position: " + this:position;
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
