# Razen Language Extension for Zed

A comprehensive language extension for the Razen programming language in Zed IDE, providing syntax highlighting, auto-completion, intelligent code features, and seamless development experience for `.rzn` files.

## Features

### 🎨 Advanced Syntax Highlighting
- **Keywords**: Full support for Razen control flow (`if`, `else`, `while`, `for`, `fun`, etc.)
- **Variable Types**: Highlighting for specialized variable declarations (`let`, `take`, `hold`, `put`, `sum`, `diff`, etc.)
- **Built-in Functions**: Recognition of Razen built-in functions (`show`, `ask`, `read_file`, etc.)
- **Library Calls**: Special highlighting for library bracket notation (`LibName[function]()`)
- **Constants**: Boolean (`true`, `false`, `null`) and color constants
- **Comments**: Line comments (`#`) and block comments (`/* */`)
- **Strings**: String literals with interpolation support (`${}`)
- **Numbers**: Integer, float, hexadecimal, and binary number formats
- **Document Types**: Support for `type web`, `type script`, `type cli`, and `type freestyle`

### 🏗️ Language Structure & Intelligence
- **Function Definitions**: Proper highlighting and outline for `fun` declarations
- **Library Imports**: Recognition of `lib libraryname;` statements
- **Code Blocks**: Intelligent bracket matching and block structure
- **Auto-Indentation**: Smart indentation for blocks, functions, and control structures
- **Code Outline**: Hierarchical view of functions, variables, and imports
- **Text Objects**: Intelligent text selection for functions, blocks, strings, and more
- **Code Folding**: Collapsible code regions and blocks
- **Runnable Detection**: Identifies executable code blocks and main functions

### 📚 Comprehensive Library Support
Support for Razen's extensive library ecosystem:

#### Core Libraries
- **`arrlib`**: Array/list operations (push, pop, join, length, unique)
- **`strlib`**: String manipulation (upper, lower, substring, replace, split, trim)
- **`mathlib`**: Mathematical operations (add, multiply, power, sqrt, trigonometry)
- **`timelib`**: Date and time handling (now, format, parse, calculations)
- **`random`**: Random number generation and selections
- **`file`**: File I/O operations (read, write, exists, append)
- **`json`**: JSON parsing and serialization

#### System & Networking Libraries
- **`os`**: Operating system information and environment variables
- **`system`**: System commands and process information
- **`netlib`**: HTTP requests, ping, and network operations
- **`memlib`**: Memory management and allocation
- **`binlib`**: Binary file operations
- **`bitlib`**: Bitwise operations and manipulation
- **`syslib`**: System calls and low-level operations

#### Utilities & Development
- **`crypto`**: Encryption, hashing, and cryptographic functions
- **`regex`**: Regular expression matching and replacement
- **`uuid`**: UUID generation and validation
- **`validation`**: Data validation helpers (email, phone, required)
- **`color`**: Color manipulation and conversion
- **`audio`**: Audio playback and recording
- **`image`**: Image processing and manipulation
- **`date`**: Enhanced date operations and formatting

#### Performance & Compilation
- **`bolt`**: High-performance operations for intensive tasks
- **`thrlib`**: Threading and parallel processing
- **`complib`**: Compiler construction utilities
- **`lexerlib`**: Lexical analysis tools
- **`parserlib`**: Syntax parsing utilities
- **`astlib`**: Abstract syntax tree manipulation

### 🔧 Developer Tools
- **Language Server**: Full LSP support with hover, completion, and diagnostics
- **Code Actions**: Quick fixes and refactoring suggestions
- **Formatting**: Automatic code formatting and style enforcement
- **Debugging**: Integrated debugging support with breakpoints
- **Testing**: Built-in test runner for Razen test functions
- **Compilation**: Direct compilation from the editor
- **REPL Integration**: Interactive Razen interpreter

### 📝 Editor Features
- **Auto-Closing**: Automatic closing of brackets, quotes, and parentheses
- **Word Boundaries**: Proper word selection and navigation
- **Comment Toggle**: Line and block comment toggling
- **Multi-Cursor**: Advanced multi-cursor editing support
- **Find & Replace**: Enhanced search with Razen-specific patterns
- **Snippets**: Pre-built code templates for common patterns

## Installation

### From Zed Extensions Registry (Recommended)
1. Open Zed IDE
2. Go to Extensions (`Cmd+Shift+X` on macOS, `Ctrl+Shift+X` on Linux/Windows)
3. Search for "Razen Language"
4. Click Install
5. Restart Zed IDE

### Manual Installation (Development)
1. Clone this repository:
   ```bash
   git clone https://github.com/BasaiCorp/Razen-Lang.git
   cd Razen-Lang/razen-zed-extension
   ```

2. Install dependencies (if building from source):
   ```bash
   cargo build --release
   ```

3. Install as development extension:
   - Open Zed IDE
   - Go to Extensions and click "Install Dev Extension"
   - Select the `razen-zed-extension` folder

### Language Server Setup (Optional)
For enhanced features, install the Razen Language Server:

```bash
# Install Razen interpreter and language server
curl -sSL https://install.razen-lang.org | sh
razen --version
razen-ls --version
```

## Quick Start

### Creating Your First Razen File
1. Create a new file with `.rzn` extension
2. Choose a document type:

```razen
type script;

# Welcome to Razen!
take message = "Hello, World!";
show message;

fun greet(name) {
    return "Hello, " + name + "!";
}

let greeting = greet("Razen Developer");
show greeting;
```

### Document Types
Begin your Razen files with a document type declaration:

```razen
type script;    # For general scripts and automation
type web;       # For web applications and services
type cli;       # For command-line tools and utilities
type freestyle; # For experimental and mixed-paradigm code
```

### Variable Declarations
Use Razen's specialized variable types for better semantics:

```razen
let number = 42;           # Numeric variables
take message = "Hello";    # String variables
hold isActive = true;      # Boolean variables
put anything = [1, 2, 3];  # Generic/dynamic variables

# Mathematical operations
sum total = 100 + 50;      # Addition
diff result = 100 - 30;    # Subtraction
prod product = 5 * 10;     # Multiplication
div quotient = 20 / 4;     # Division
mod remainder = 10 % 3;    # Modulus
```

### Library Usage
Import and use Razen's extensive library ecosystem:

```razen
lib mathlib;
lib strlib;
lib arrlib;

# Mathematical operations
let result = MathLib[add](5, 3);
let power = MathLib[power](2, 8);

# String manipulation
take upper = StrLib[upper]("hello world");
take parts = StrLib[split]("a,b,c", ",");

# Array operations
list numbers = [1, 2, 3, 4, 5];
ArrLib[push](numbers, 6);
let length = ArrLib[length](numbers);
```

## Language Features

### Control Flow
```razen
# Conditional statements
if (temperature > 25) {
    show "It's warm outside!";
} elif (temperature > 15) {
    show "Nice weather.";
} else {
    show "It's cold.";
}

# Loops
while (counter < 10) {
    show "Count: " + counter;
    counter = counter + 1;
}

for (item in collection) {
    show "Processing: " + item;
}
```

### Functions
```razen
# Function definitions
fun calculateArea(width, height) {
    return width * height;
}

fun processData(data) {
    if (data == null) {
        return "No data provided";
    }
    
    take processed = StrLib[trim](data);
    return StrLib[upper](processed);
}

# Function calls
let area = calculateArea(10, 5);
take result = processData("  hello world  ");
```

### Advanced Features

#### Compiler Construction
```razen
lib complib;
lib lexerlib;
lib parserlib;

# Tokenization
token identifier = LexerLib[tokenize]("variable_name");
token number = LexerLib[tokenize]("42");

# AST manipulation
ast node = CompLib[create_node]("assignment", left, right);
ast tree = ParserLib[parse](tokens);

# Code generation
take code = CompLib[generate](tree, "target_language");
```

#### System Programming
```razen
lib memlib;
lib syslib;
lib bitlib;

# Memory management
let ptr = MemLib[alloc](1024);
MemLib[write_byte](ptr, 0, 65);
let byte = MemLib[read_byte](ptr, 0);
MemLib[free](ptr);

# System operations
let pid = SysLib[getpid]();
SysLib[execute]("ls -la");

# Bitwise operations
let result = BitLib[and](5, 3);  # 0101 & 0011 = 0001
```

#### Web Development
```razen
type web;

lib netlib;
lib json;

# HTTP requests
take response = NetLib[get]("https://api.example.com/data");
put data = JSON[parse](response);

# API responses
take jsonResponse = JSON[stringify]({
    "status": "success",
    "data": data,
    "timestamp": TimeLib[now]()
});
```

## Configuration

### Extension Settings
Configure the extension through Zed's settings:

```json
{
  "languages": {
    "Razen": {
      "tab_size": 4,
      "formatter": "language_server",
      "format_on_save": "on",
      "enable_language_server": true,
      "show_completions_on_input": true,
      "soft_wrap": "preferred_line_length"
    }
  },
  "lsp": {
    "razen-language-server": {
      "initialization_options": {
        "enable_diagnostics": true,
        "enable_completions": true,
        "enable_hover": true,
        "library_path": "./libs",
        "stdlib_path": "/usr/local/lib/razen/stdlib"
      }
    }
  }
}
```

### Theme Customization
The extension includes a custom "Razen Dark" theme optimized for Razen syntax. You can also customize syntax highlighting colors:

```json
{
  "theme": "Razen Dark",
  "syntax_overrides": {
    "keyword.control.razen": "#c586c0",
    "entity.name.function.razen": "#dcdcaa",
    "storage.type.razen": "#569cd6",
    "string.quoted.double.razen": "#ce9178"
  }
}
```

## Keyboard Shortcuts

### Default Shortcuts
- `Cmd+R` / `Ctrl+R`: Run current Razen file
- `Cmd+Shift+R` / `Ctrl+Shift+R`: Run with arguments
- `Cmd+B` / `Ctrl+B`: Compile current file
- `Cmd+T` / `Ctrl+T`: Run tests
- `Cmd+Shift+F` / `Ctrl+Shift+F`: Format code
- `F5`: Debug current file
- `Cmd+/` / `Ctrl+/`: Toggle line comments
- `Cmd+Shift+/` / `Ctrl+Shift+/`: Toggle block comments

### Custom Commands
- `razen: Run Main Function`: Execute the main function
- `razen: Run Tests`: Run all test functions
- `razen: Compile Project`: Compile the entire project
- `razen: Format Document`: Format the current document
- `razen: Show Documentation`: Show documentation for symbol under cursor

## Debugging

### Built-in Debugger
The extension supports debugging Razen applications:

1. Set breakpoints by clicking in the gutter
2. Press `F5` or use the debug panel
3. Use the debug console for interactive debugging
4. Inspect variables and call stack

### Debug Configuration
Create a `.vscode/launch.json` for custom debug configurations:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Razen Script",
      "type": "razen",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "args": []
    },
    {
      "name": "Debug Razen Tests",
      "type": "razen",
      "request": "launch",
      "program": "${workspaceFolder}/tests",
      "console": "integratedTerminal",
      "runMode": "test"
    }
  ]
}
```

## Testing

### Running Tests
The extension provides built-in support for Razen's testing framework:

```razen
# Test functions are automatically detected
fun test_calculator() {
    let result = add(2, 3);
    assert(result == 5, "Addition should work correctly");
}

fun test_string_operations() {
    take result = StrLib[upper]("hello");
    assert(result == "HELLO", "String uppercase should work");
}

# Run tests with Cmd+T or through the command palette
```

### Test Discovery
The extension automatically discovers and runs:
- Functions starting with `test_`
- Functions in files ending with `_test.rzn`
- Functions marked with `@test` annotations

## Troubleshooting

### Common Issues

#### Extension Not Loading
1. Ensure Zed is updated to the latest version
2. Check if the extension is enabled in Extensions panel
3. Restart Zed IDE
4. Check the Zed log for error messages

#### Syntax Highlighting Not Working
1. Verify the file has `.rzn` extension
2. Check if the language is set to "Razen" in the status bar
3. Try reloading the window (`Cmd+R` / `Ctrl+R`)

#### Language Server Issues
1. Ensure `razen-ls` is installed and in PATH
2. Check language server logs in the output panel
3. Verify settings in `settings.json`
4. Restart the language server

#### Performance Issues
1. Disable unused features in settings
2. Increase memory limits for large files
3. Use `.razenignore` to exclude irrelevant files

### Getting Help
- **Documentation**: [https://docs.razen-lang.org](https://docs.razen-lang.org)
- **Issues**: [GitHub Issues](https://github.com/BasaiCorp/Razen-Lang/issues)
- **Community**: [Discord Server](https://discord.gg/razen-lang)
- **Email**: support@razen-lang.org

## Contributing

We welcome contributions! Here's how to get started:

### Development Setup
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/your-username/Razen-Lang.git
   cd Razen-Lang/razen-zed-extension
   ```

3. Install dependencies:
   ```bash
   cargo build
   ```

4. Make your changes
5. Test the extension locally
6. Submit a pull request

### Areas for Contribution
- **Syntax Highlighting**: Improve highlighting patterns
- **Language Server**: Enhance LSP features
- **Documentation**: Update guides and examples
- **Testing**: Add test cases and improve coverage
- **Performance**: Optimize extension performance
- **Features**: Add new language features and support

### Code Style
- Follow Rust best practices and formatting
- Use clear, descriptive variable names
- Add comments for complex logic
- Include tests for new features
- Update documentation as needed

## Roadmap

### Upcoming Features
- **IntelliSense**: Enhanced auto-completion with context awareness
- **Refactoring**: Automated refactoring tools
- **Code Generation**: Templates and scaffolding
- **Package Manager**: Integration with Razen package manager
- **Mobile Development**: Support for mobile app development
- **Web Framework**: Built-in web development tools
- **AI Assistant**: AI-powered code suggestions and debugging

### Version History

#### v0.1.0 (Current)
- Initial release
- Basic syntax highlighting
- Library support and recognition
- Code structure and outline
- Auto-indentation and bracket matching
- Runnable code detection
- Tree-sitter grammar integration
- Language server foundation

## License

This extension is released under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Zed Team**: For creating an amazing editor platform
- **Tree-sitter**: For powerful syntax highlighting infrastructure
- **Razen Community**: For feedback and contributions
- **Open Source Contributors**: For their valuable contributions

---

**Happy coding with Razen! 🚀**

For more information, visit [razen-lang.org](https://razen-lang.org) or join our community on [Discord](https://discord.gg/razen-lang).