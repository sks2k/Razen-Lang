# Razen Programming Language

**Version: beta v0.1.76**

Razen is a modern programming language designed with clarity and performance in mind. Built for developers who value clean syntax, strong type safety, and efficient execution.

Created by Prathmesh Barot at Basai Corporation.

## What is Razen?

Razen combines the best aspects of modern language design with practical development needs. It features intuitive syntax, comprehensive type safety, and built-in tooling that makes development faster and more reliable.

## Key Features

- **Clean Syntax**: Readable and expressive code that feels natural to write
- **Strong Type System**: Multiple variable types with enforcement where you need it
- **Built-in Tools**: Integrated debugging, testing, and development utilities  
- **Rich Libraries**: Comprehensive standard library with bracket notation
- **Cross-Platform**: Runs on Linux, macOS, and Windows
- **Object-Oriented**: Full class-based programming support
- **Interactive Development**: Built-in REPL for quick testing
- **Performance Focused**: Optimized runtime with LLVM integration
- **Developer Experience**: Colored output, comprehensive error handling, VS Code extension

## Installation

### Quick Install (All Platforms)

```
# Using curl
curl -o installer.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/installer.sh" && chmod +x installer.sh && ./installer.sh

# Using wget (Linux)
wget -O installer.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/installer.sh" && chmod +x installer.sh && ./installer.sh
```

### Windows Users

Use Git Bash to run the installer:
```
curl -o installer.sh "https://raw.githubusercontent.com/BasaiCorp/razen-lang/main/installer.sh" && chmod +x installer.sh && ./installer.sh
```

**Requirements:**
- Git Bash (download from git-scm.com)
- Git LFS installed and working
- Administrator privileges recommended
- 2GB free disk space

### Installation Options

```
./installer.sh           # Standard installation
./installer.sh force     # Fresh installation
./installer.sh uninstall # Remove Razen
```

### Stay Updated

```
razen-update             # Update to latest version
```

## Getting Started

### Your First Program

Create a new Razen program:
```
razen new hello
```

This generates `hello.rzn`:
```
# Hello World in Razen
str message = "Hello, World!";
show message;

# Get user input
read user_input = "What's your name? ";
show "Nice to meet you, " + user_input + "!";
```

Run it:
```
razen-run hello.rzn
```

## Command Line Tools

```
razen <file.rzn>           # Execute a Razen script
razen new <name>           # Create new program template
razen version              # Show version info
razen help                 # Display help

# Development tools
razen-debug <file.rzn>     # Debug with detailed output
razen-test <file.rzn>      # Run in test mode
razen-run <file.rzn>       # Clean execution (output only)
razen-update               # Update Razen
razen-help                 # Detailed help with examples
```

## Language Basics

### Variables and Types

Razen provides several variable types for different needs:

```
# Basic types
num count = 42;              # Numbers (integers and floats)
str name = "Alice";          # Text strings
bool active = true;          # Boolean values
var flexible = "anything";   # Dynamic typing

# Mathematical operations
num total = 100 + 50;        # Addition
num difference = 100 - 50;   # Subtraction
num product = 5 * 10;        # Multiplication
num quotient = 20 / 4;       # Division
num remainder = 10 % 3;      # Modulus
```

### Control Flow

```
# Conditionals
if (count > 40) {
    show "Count is high";
} else if (count == 40) {
    show "Count is exactly 40";
} else {
    show "Count is low";
}

# Loops
num i = 0;
while (i < 5) {
    show "Iteration: " + i;
    i = i + 1;
}
```

### Functions

```
# Function definition
fun greet(name, age) {
    show "Hello, " + name + "! You are " + age + " years old.";
}

# Function call
greet("Bob", 25);

# Function with return value
fun factorial(n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

show "5! = " + factorial(5);
```

## Object-Oriented Programming

Razen supports full object-oriented programming with classes and inheritance:

```
class Person {
    # Constructor
    fun init(name, age) {
        this.name = name;
        this.age = age;
    }

    # Methods
    fun introduce() {
        show "Hi, I'm " + this.name + " and I'm " + this.age + " years old.";
    }

    fun haveBirthday() {
        this.age = this.age + 1;
        show "Happy birthday! Now " + this.age + " years old.";
    }
}

# Create and use objects
var person = new Person("Sarah", 28);
person::introduce();
person::haveBirthday();
```

### Inheritance

```
class Employee extends Person {
    fun init(name, age, role) {
        super.init(name, age);
        this.role = role;
    }

    fun introduce() {
        super.introduce();
        show "I work as a " + this.role;
    }
}

var employee = new Employee("John", 30, "Developer");
employee::introduce();
```

## Standard Library

Razen includes a comprehensive standard library with bracket notation:

```
# Import libraries
lib arrlib;    # Array operations
lib strlib;    # String utilities
lib mathlib;   # Mathematical functions
lib random;    # Random number generation
lib crypto;    # Cryptographic functions

# Array operations
show "Array functions:";
var numbers = ;
show "Original: " + numbers;
show "After push: " + arrlib::push(numbers, 4);
show "Joined: " + arrlib::join(["a", "b", "c"], "-");

# String operations
show "String functions:";
show "Uppercase: " + strlib::upper("hello world");
show "Replace: " + strlib::replace("Hello Razen", "Razen", "World");

# Math operations
show "Math functions:";
show "Square root of 16: " + mathlib::sqrt(16);
show "2 to the power of 8: " + mathlib::power(2, 8);

# Random utilities
show "Random functions:";
show "Random number (1-100): " + random::int(1, 100);
show "Random choice: " + random::choice(["red", "green", "blue"]);

# Cryptographic functions
show "Crypto functions:";
show "Hash: " + crypto::hash("secure data");
```

## Advanced Features

### Collections

```
# Dynamic arrays
list fruits = ["apple", "banana", "cherry"];
append(fruits, "mango");
remove(fruits, "banana");

# Fixed arrays
arr<num> temperatures = ;

# Dictionaries
map userProfile = {
    "name": "Alex",
    "age": 28,
    "active": true
};

# Iterate over maps
for (key in userProfile) {
    show key + ": " + userProfile.key;
}
```

### Special Variables

```
# Persistent storage
store settings = loadConfig();
saveToStore(settings);

# Managed resources
with box file = File["open"]("data.txt") {
    # File operations here
    # Automatically closed when block exits
}

# References
ref currentUser = users.activeIndex;
currentUser.lastActive = now();
```

### Colored Output

```
show(red) "Error message";
show(green) "Success message";
show(yellow) "Warning message";
show(blue) "Information";
show(purple) "Highlight";
show(cyan) "Technical details";
```

## What's New in v0.1.76

This release brings significant improvements:

- **Faster Installation**: Completely redesigned installer that's much quicker
- **LLVM Integration**: Experimental support for advanced optimizations
- **Updated Logging**: Renamed logging functions to prevent conflicts
- **VS Code Extension**: Better syntax highlighting and code completion
- **Memory Optimizations**: Reduced memory usage across the board
- **Improved Build System**: Streamlined dependency management

For complete changelog details, check the [changelogs](changelogs/) directory.

## File Structure

### Linux/macOS
- Core files: `/usr/local/lib/razen`
- Examples: `/usr/local/lib/razen/examples`
- Libraries: `/usr/local/lib/razen/properties/libs`

### Windows
- Core files: `C:\Program Files\Razen`
- Examples: `C:\Program Files\Razen\examples`
- Executables: `C:\Program Files\Razen\bin`

## Development and Debugging

Razen includes powerful development tools:

```
# Debug mode shows execution details
razen-debug my-script.rzn

# Test mode for validation
razen-test my-script.rzn

# Clean output for production
razen-run my-script.rzn
```

The built-in debugger provides step-by-step execution tracking and comprehensive error reporting.

## License

Razen is licensed under the Apache License 2.0. You are free to use, modify, and distribute Razen for both personal and commercial purposes. See the [LICENSE](./LICENSE) file for complete details.

## Support and Community

For questions, bug reports, or feature requests:
- Email: prathmeshbarot2009@gmail.com
- GitHub: [https://github.com/BasaiCorp/razen-lang](https://github.com/BasaiCorp/razen-lang)

Check the `examples` folder for sample programs and tutorials to help you get started.

---

**Razen Programming Language** - Building better software through clear, powerful code.
